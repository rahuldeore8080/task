# Run from an extracted project directory in Windows PowerShell.
# Prerequisite: Git for Windows, and permission to push to rahuldeore8080/task.
$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$target = Join-Path $env:TEMP ('task-github-' + [guid]::NewGuid().ToString('N'))
$repo = 'https://github.com/rahuldeore8080/task.git'

Write-Host "Cloning existing main branch (keeps Git history)..."
git clone --branch main $repo $target
if ($LASTEXITCODE -ne 0) { throw 'Clone failed. Check Git installation and repository access.' }

Write-Host 'Copying project source into repository...'
robocopy $source $target /E /XD '.git' '.venv' 'venv' '__pycache__' '.pytest_cache' /XF '.env' '*.pyc' '.coverage' | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'File copy failed.' }

Push-Location $target
try {
    git add -A
    git status --short
    $answer = Read-Host 'Push these changes to public GitHub main? (type YES)'
    if ($answer -cne 'YES') { Write-Host "Stopped safely. Working copy: $target"; return }
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { Write-Host 'No changes to publish'; return }
    git commit -m 'Add FastAPI task management API, tests, Docker and CI'
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed. Configure your Git user.name and user.email.' }
    git push origin main
    if ($LASTEXITCODE -ne 0) { throw "Push failed. Your local working copy is at $target" }
    Write-Host 'Published successfully: https://github.com/rahuldeore8080/task'
}
finally { Pop-Location }
