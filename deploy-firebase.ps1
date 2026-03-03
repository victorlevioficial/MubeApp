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
  throw "Arquivo firebase.deploy.json nao encontrado em $deployConfigPath."
}

$firebaseRc = Get-Content -Path $firebaseRcPath -Raw | ConvertFrom-Json
$projectId = $firebaseRc.projects.default

if ([string]::IsNullOrWhiteSpace($projectId)) {
  throw "Projeto padrao nao definido em .firebaserc."
}

if ($Args.Count -eq 0) {
  throw @"
Uso:
  .\deploy-firebase.ps1 --only firestore:rules
  .\deploy-firebase.ps1 --only firestore:indexes
  .\deploy-firebase.ps1 --only hosting
"@
}

$deployArgs = @("deploy", "--project", $projectId, "--config", $deployConfigPath)
$deployArgs += $Args

Write-Host "Projeto:" $projectId
Write-Host "Config:" $deployConfigPath
Write-Host "Comando: firebase $($deployArgs -join ' ')"

& firebase @deployArgs
exit $LASTEXITCODE
