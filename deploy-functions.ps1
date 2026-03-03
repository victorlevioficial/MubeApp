param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$firebaseRcPath = Join-Path $repoRoot ".firebaserc"
$deployConfigPath = Join-Path $repoRoot "firebase.deploy.json"

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  throw "Firebase CLI nao encontrada no PATH."
}

if (-not (Test-Path $firebaseRcPath)) {
  throw "Arquivo .firebaserc nao encontrado em $firebaseRcPath."
}

if (-not (Test-Path $deployConfigPath)) {
  throw "Arquivo firebase.deploy.json não encontrado em $deployConfigPath."
}

$firebaseRc = Get-Content -Path $firebaseRcPath -Raw | ConvertFrom-Json
$projectId = $firebaseRc.projects.default

if ([string]::IsNullOrWhiteSpace($projectId)) {
  throw "Projeto padrao nao definido em .firebaserc."
}

$defaultCloudRunRegion = "southamerica-east1"

function Get-FirebaseCliAccessToken {
  $configPath = Join-Path $env:USERPROFILE ".config\configstore\firebase-tools.json"
  if (-not (Test-Path $configPath)) {
    throw "Arquivo de sessao do Firebase CLI nao encontrado em $configPath."
  }

  $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
  $accessToken = $config.tokens.access_token
  if ([string]::IsNullOrWhiteSpace($accessToken)) {
    throw "Nao foi possivel obter o access token atual do Firebase CLI."
  }

  return $accessToken
}

function Get-PublicCallableFunctions {
  $functionsSrcPath = Join-Path $repoRoot "functions\src"
  if (-not (Test-Path $functionsSrcPath)) {
    return @()
  }

  $pattern =
    'export const (\w+)\s*=\s*onCall\(\s*\{[\s\S]*?invoker:\s*"public"[\s\S]*?\}\s*,'
  $functionsByName = @{}

  Get-ChildItem -Path $functionsSrcPath -Filter *.ts -Recurse | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    $constants = @{}
    $constantMatches = [System.Text.RegularExpressions.Regex]::Matches(
      $content,
      'const\s+(\w+)\s*=\s*"([^"]+)"'
    )
    foreach ($constantMatch in $constantMatches) {
      $constants[$constantMatch.Groups[1].Value] = $constantMatch.Groups[2].Value
    }

    $matches = [System.Text.RegularExpressions.Regex]::Matches(
      $content,
      $pattern
    )

    foreach ($match in $matches) {
      $functionName = $match.Groups[1].Value
      $block = $match.Value
      $region = $null

      $literalRegion = [System.Text.RegularExpressions.Regex]::Match(
        $block,
        'region:\s*"([^"]+)"'
      )
      if ($literalRegion.Success) {
        $region = $literalRegion.Groups[1].Value
      }

      if ([string]::IsNullOrWhiteSpace($region)) {
        $constantRegion = [System.Text.RegularExpressions.Regex]::Match(
          $block,
          'region:\s*(\w+)'
        )
        if ($constantRegion.Success) {
          $constantName = $constantRegion.Groups[1].Value
          if ($constants.ContainsKey($constantName)) {
            $region = $constants[$constantName]
          }
        }
      }

      if ([string]::IsNullOrWhiteSpace($region)) {
        $region = $defaultCloudRunRegion
      }

      $functionsByName[$functionName] = [pscustomobject]@{
        Name = $functionName
        Region = $region
      }
    }
  }

  return @($functionsByName.Values | Sort-Object Name)
}

function Ensure-PublicCallableInvokerPolicy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    [Parameter(Mandatory = $true)]
    [object[]]$Functions
  )

  if ($Functions.Count -eq 0) {
    Write-Host "Nenhuma callable publica encontrada para validar IAM."
    return
  }

  $accessToken = Get-FirebaseCliAccessToken
  $headers = @{
    Authorization = "Bearer $accessToken"
    "x-goog-user-project" = $ProjectId
  }

  foreach ($function in $Functions) {
    $functionName = [string]$function.Name
    $serviceRegion = [string]$function.Region
    $serviceName = $functionName.ToLowerInvariant()
    $policyUri =
      "https://run.googleapis.com/v2/projects/$ProjectId/locations/" +
      "$serviceRegion/services/$serviceName`:getIamPolicy"

    $policy = Invoke-RestMethod -Method Get -Headers $headers -Uri $policyUri
    $bindings = @()
    $bindingsProperty = $policy.PSObject.Properties["bindings"]
    if ($null -ne $bindingsProperty) {
      foreach ($binding in $bindingsProperty.Value) {
        $bindings += @{
          role = [string]$binding.role
          members = @($binding.members)
        }
      }
    }

    $invokerBinding = $bindings | Where-Object {
      $_.role -eq "roles/run.invoker"
    } | Select-Object -First 1

    if ($null -ne $invokerBinding -and $invokerBinding.members -contains "allUsers") {
      Write-Host "IAM ok:" $functionName "-> allUsers ja pode invocar."
      continue
    }

    if ($null -eq $invokerBinding) {
      $bindings += @{
        role = "roles/run.invoker"
        members = @("allUsers")
      }
    } else {
      $members = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
      )
      foreach ($member in $invokerBinding.members) {
        [void]$members.Add([string]$member)
      }
      [void]$members.Add("allUsers")
      $invokerBinding.members = @($members)
    }

    $setUri =
      "https://run.googleapis.com/v2/projects/$ProjectId/locations/" +
      "$serviceRegion/services/$serviceName`:setIamPolicy"
    $body = @{
      policy = @{
        etag = $policy.etag
        version = 1
        bindings = $bindings
      }
    } | ConvertTo-Json -Depth 8

    Invoke-RestMethod `
      -Method Post `
      -Headers ($headers + @{ "Content-Type" = "application/json" }) `
      -Uri $setUri `
      -Body $body | Out-Null

    Write-Host "IAM corrigida:" $functionName "-> roles/run.invoker para allUsers."
  }
}

$hasOnlyFlag = $false
for ($i = 0; $i -lt $Args.Count; $i++) {
  if ($Args[$i] -eq "--only" -or $Args[$i].StartsWith("--only=")) {
    $hasOnlyFlag = $true
    break
  }
}

$deployArgs = @("deploy", "--project", $projectId, "--config", $deployConfigPath)
if (-not $hasOnlyFlag) {
  $deployArgs += @("--only", "functions")
}
if ($Args.Count -gt 0) {
  $deployArgs += $Args
}

Write-Host "Projeto:" $projectId
Write-Host "Config:" $deployConfigPath
Write-Host "Comando: firebase $($deployArgs -join ' ')"

& firebase @deployArgs
$deployExitCode = $LASTEXITCODE
if ($deployExitCode -ne 0) {
  exit $deployExitCode
}

$publicCallableFunctions = Get-PublicCallableFunctions
Ensure-PublicCallableInvokerPolicy `
  -ProjectId $projectId `
  -Functions $publicCallableFunctions

exit 0
