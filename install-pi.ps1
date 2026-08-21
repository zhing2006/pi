# Build pi from source and install it as a global command (npm link). Windows.
# Usage:
#   .\install-pi.ps1               # Full flow: install deps -> build -> npm link
#   .\install-pi.ps1 -SkipInstall  # Skip dependency install; rebuild + link only
#   .\install-pi.ps1 -Sync         # Sync upstream/main, rebase zhing2006, and push both
#   .\install-pi.ps1 -Sync -SkipInstall
param(
	[switch]$SkipInstall,
	[switch]$Sync
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

function Invoke-Git {
	param([string[]]$Arguments)
	Write-Host "==> git $($Arguments -join ' ')" -ForegroundColor Cyan
	& git @Arguments
	if ($LASTEXITCODE -ne 0) {
		throw "Git command failed (exit code $LASTEXITCODE): git $($Arguments -join ' ')"
	}
}

function Sync-Branches {
	Push-Location $repoRoot
	try {
		$gitStatus = & git status --porcelain
		if ($LASTEXITCODE -ne 0) {
			throw "Unable to read git status."
		}
		if ($gitStatus) {
			throw "Cannot sync branches with uncommitted changes. Commit or remove them first."
		}

		Invoke-Git @("show-ref", "--verify", "--quiet", "refs/heads/main")
		Invoke-Git @("show-ref", "--verify", "--quiet", "refs/heads/zhing2006")
		Invoke-Git @("fetch", "upstream", "main")
		Invoke-Git @("switch", "main")
		Invoke-Git @("merge", "--ff-only", "upstream/main")
		Invoke-Git @("push", "origin", "main")
		Invoke-Git @("switch", "zhing2006")
		Invoke-Git @("rebase", "main")
		Invoke-Git @("push", "--force-with-lease", "origin", "zhing2006")
	}
	finally {
		Pop-Location
	}
}

if ($Sync) {
	Sync-Branches
}

if (-not $SkipInstall) {
	Invoke-Step "Install dependencies (npm install --ignore-scripts)" $repoRoot { npm install --ignore-scripts }
}

Invoke-Step "Build all packages (npm run build)" $repoRoot { npm run build }

Invoke-Step "Register global pi command (npm link)" (Join-Path $repoRoot "packages\coding-agent") { npm link }

Write-Host ""
Write-Host "Done. Verifying version:" -ForegroundColor Green
& "$(npm prefix -g)\pi.cmd" --version
