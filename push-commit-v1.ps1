# Get the current directory
$currentDirectory = (Get-Location).Path

# Change directory to the current directory
Set-Location $currentDirectory

# Check if there are changes in the repository
$hasChanges = git status --porcelain

# If there are no changes, prompt to exit
if (-not $hasChanges) {
    Write-Host "No changes detected. Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}

# Add all changes to the staging area
git add .

# Prompt the user to enter the commit message
$commitMessage = Read-Host -Prompt "Enter the commit message"

# Commit the changes with the provided message
git commit -m $commitMessage

# Push the changes to the repository
git push origin master
