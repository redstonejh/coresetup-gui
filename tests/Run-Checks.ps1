$ErrorActionPreference = "Stop"

& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "CoreSetup.Static.Tests.ps1")
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "PASSED: CoreSetup checks"
exit 0
