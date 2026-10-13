<#
.SYNOPSIS
Guided stage, commit and push for the current branch of a Git repository.

.DESCRIPTION
Shows the repository, branch and status, then asks before each step:
staging (git add -A, whole repository), committing, and pushing to the
branch's configured upstream. Every confirmation defaults to No.
The script stops with a nonzero exit code as soon as a Git command fails.

.PARAMETER Path
A folder inside the repository. Defaults to the current directory.

.EXAMPLE
.\git-push-helper.ps1

.EXAMPLE
.\git-push-helper.ps1 -Path "D:\Work\my project"
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Path = (Get-Location).Path
)

function Confirm-Step {
    param([string]$Question)
    $answer = Read-Host "$Question [y/N]"
    return $answer -match '^\s*(y|yes)\s*$'
}

function Assert-GitSucceeded {
    param([string]$Action)
    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed (git exit code $LASTEXITCODE)."
    }
}

$originalLocation = (Get-Location).Path
$messageFile = $null
$exitCode = 0

try {
    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
        throw 'Git was not found on PATH. Install Git and try again.'
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Path not found or not a folder: $Path"
    }
    Set-Location -LiteralPath $Path -ErrorAction Stop

    # Move to the repository root so the script behaves the same from any subfolder.
    $cdUp = git rev-parse --show-cdup
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a Git working tree: $Path"
    }
    if ($cdUp) {
        Set-Location -LiteralPath $cdUp -ErrorAction Stop
    }

    $branch = git symbolic-ref --quiet --short HEAD
    if ($LASTEXITCODE -ne 0) {
        throw 'HEAD is detached. Check out a branch and run the script again.'
    }

    # git config --get exits with 1 when the key is not set; anything higher is a real failure.
    $remote = git config --get "branch.$branch.remote"
    if ($LASTEXITCODE -gt 1) { throw "Reading the upstream remote failed (git exit code $LASTEXITCODE)." }
    $remoteRef = git config --get "branch.$branch.merge"
    if ($LASTEXITCODE -gt 1) { throw "Reading the upstream branch failed (git exit code $LASTEXITCODE)." }
    $hasUpstream = $remote -and $remoteRef -and ($remote -ne '.')

    Write-Host "Repository: $((Get-Location).Path)"
    Write-Host "Branch:     $branch"
    if ($hasUpstream) {
        Write-Host "Upstream:   $remote $remoteRef"
    } else {
        Write-Host 'Upstream:   (none)'
    }
    Write-Host ''
    git status
    Assert-GitSucceeded 'git status'
    Write-Host ''

    # Stage
    $changes = git status --porcelain
    Assert-GitSucceeded 'git status'
    if ($changes) {
        if (Confirm-Step 'Stage ALL changes in the whole repository (git add -A)?') {
            git add -A
            Assert-GitSucceeded 'git add -A'
        } else {
            Write-Host 'Staging skipped.'
        }
    } else {
        Write-Host 'Working tree is clean. Nothing to stage or commit.'
    }

    # Commit (exit code 1 from git diff --quiet means there are staged changes)
    git diff --cached --quiet
    if ($LASTEXITCODE -gt 1) { throw "Checking staged changes failed (git exit code $LASTEXITCODE)." }
    if ($LASTEXITCODE -eq 1) {
        if (Confirm-Step 'Commit the staged changes?') {
            $message = Read-Host 'Commit message'
            if ([string]::IsNullOrWhiteSpace($message)) {
                throw 'The commit message is empty. Nothing was committed.'
            }
            # Pass the message through a file: Windows PowerShell 5.1 mangles
            # double quotes in arguments to native commands.
            $messageFile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($messageFile, $message)
            git commit -F $messageFile
            Assert-GitSucceeded 'git commit'
        } else {
            Write-Host 'Commit skipped.'
        }
    } elseif ($changes) {
        Write-Host 'Nothing is staged. Commit skipped.'
    }

    # Push
    Write-Host ''
    if (-not $hasUpstream) {
        Write-Host "Branch '$branch' has no upstream, so nothing will be pushed."
        Write-Host 'Set one yourself and run the script again, for example:'
        Write-Host "  git push -u <remote> $branch"
    } elseif (Confirm-Step "Push '$branch' to $remote ($remoteRef)?") {
        $refspec = "refs/heads/${branch}:$remoteRef"
        Write-Host "Dry run: git push --dry-run $remote $refspec"
        git push --dry-run $remote $refspec
        Assert-GitSucceeded 'The dry-run push'
        if (Confirm-Step 'Dry run succeeded. Push for real?') {
            git push $remote $refspec
            Assert-GitSucceeded 'git push'
        } else {
            Write-Host 'Live push skipped.'
        }
    } else {
        Write-Host 'Push skipped.'
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}
finally {
    Set-Location -LiteralPath $originalLocation
    if ($messageFile -and (Test-Path -LiteralPath $messageFile)) {
        Remove-Item -LiteralPath $messageFile -Force
    }
}

exit $exitCode
