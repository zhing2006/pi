# Build pi from source and install it as a global command (npm link). Windows.
# Usage:
#   .\install-pi.ps1               # Full flow: install deps -> build -> npm link
#   .\install-pi.ps1 -SkipInstall  # Skip dependency install; rebuild + link only
param(
	[switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-Step {
	param([string]$Name, [string]$WorkDir, [scriptblock]$Action)
	Write-Host "==> $Name" -ForegroundColor Cyan
	Push-Location $WorkDir
	try {
		& $Action
		if ($LASTEXITCODE -ne 0) {
			throw "Step failed: $Name (exit code $LASTEXITCODE)"
		}
	}
	finally {
		Pop-Location
	}
}

if (-not $SkipInstall) {
	Invoke-Step "Install dependencies (npm install --ignore-scripts)" $repoRoot { npm install --ignore-scripts }
}

Invoke-Step "Build all packages (npm run build)" $repoRoot { npm run build }

Invoke-Step "Register global pi command (npm link)" (Join-Path $repoRoot "packages\coding-agent") { npm link }

Write-Host ""
Write-Host "Done. Verifying version:" -ForegroundColor Green
& "$(npm prefix -g)\pi.cmd" --version
