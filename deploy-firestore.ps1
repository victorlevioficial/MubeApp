param(
  [switch]$Rules,
  [switch]$Indexes,
  [switch]$Help,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wrapperPath = Join-Path $repoRoot "deploy-firebase.ps1"
$forwardedArgs = New-Object System.Collections.Generic.List[string]

foreach ($arg in $Args) {
  switch ($arg) {
    "--rules" {
      $Rules = $true
      continue
    }
    "--indexes" {
      $Indexes = $true
      continue
    }
    "--help" {
      $Help = $true
      continue
    }
    default {
      $forwardedArgs.Add($arg)
    }
  }
}

if ($Help) {
  @"
Uso:
  .\deploy-firestore.ps1
  .\deploy-firestore.ps1 --rules
  .\deploy-firestore.ps1 --indexes
  .\deploy-firestore.ps1 --dry-run

Sem flags, o script faz deploy de:
  firestore:rules,firestore:indexes
"@ | Write-Host
  exit 0
}

if (-not (Test-Path $wrapperPath)) {
  throw "Arquivo deploy-firebase.ps1 nao encontrado em $wrapperPath."
}

$targets = @()
if ($Rules) {
  $targets += "firestore:rules"
}
if ($Indexes) {
  $targets += "firestore:indexes"
}
if ($targets.Count -eq 0) {
  $targets = @("firestore:rules", "firestore:indexes")
}

$forwardArgs = @("--only", ($targets -join ","))
if ($forwardedArgs.Count -gt 0) {
  $forwardArgs += $forwardedArgs
}

& $wrapperPath @forwardArgs
exit $LASTEXITCODE
