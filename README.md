# Git Push Helper

A small PowerShell script that walks you through staging, committing and pushing the current Git branch, asking before each step.

It shows the repository, branch and `git status` first, every confirmation defaults to **No**, and it stops with a nonzero exit code as soon as a Git command fails.

## Requirements

- Windows PowerShell 5.1
- Git on `PATH`

## Usage

From any folder inside a repository:

```powershell
.\git-push-helper.ps1
```

Or point it at a repository from anywhere:

```powershell
.\git-push-helper.ps1 -Path "D:\Work\my project"
```

If your execution policy blocks local scripts, run it as:

```powershell
powershell -ExecutionPolicy Bypass -File .\git-push-helper.ps1
```

## Example

```text
Repository: D:\Work\my project
Branch:     main
Upstream:   origin refs/heads/main

On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
        notes.txt

Stage ALL changes in the whole repository (git add -A)? [y/N]: y
Commit the staged changes? [y/N]: y
Commit message: add "notes" file
[main 5900659] add "notes" file
 1 file changed, 1 insertion(+)

Push 'main' to origin (refs/heads/main)? [y/N]: y
Dry run: git push --dry-run origin refs/heads/main:refs/heads/main
   56eb7d2..5900659  main -> main
Dry run succeeded. Push for real? [y/N]: y
   56eb7d2..5900659  main -> main
```

## Behaviour

- **Staging** uses `git add -A` from the repository root. It stages every new, modified and deleted file in the whole repository that `.gitignore` does not exclude, even when you start the script in a subfolder. Check the status output before answering yes.
- **Committing** is offered only when something is staged. An empty commit message is rejected.
- **Pushing** goes to the current branch's configured upstream. A dry run against the same destination runs first, and the live push needs its own confirmation.
- A detached `HEAD`, a path outside a repository, or a missing Git stops the script before anything changes.
- Your working directory is restored when the script ends.

## Upstream setup

The script never chooses a remote or changes Git configuration. If the branch has no upstream it explains this and skips the push. Set the upstream once yourself:

```powershell
git push -u origin main
```

After that the script can push the branch.
