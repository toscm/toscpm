# Aliases
if (Test-Path Alias:r)     { Remove-Item Alias:r }
if (Test-Path Alias:where) { Remove-Item -Force Alias:where }

# ls family: eza when installed (matching bash and zsh), Get-ChildItem otherwise.
# ls/dir/gci are ReadOnly built-in aliases, so overriding needs -Force; and
# aliases outrank functions in PowerShell's command resolution, so the ones
# taking arguments must have their alias removed before the function is defined.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Set-Alias -Name ls -Value eza -Force -Option AllScope
    foreach ($n in 'll', 'la', 'l', 'lt') {
        if (Test-Path "Alias:$n") { Remove-Item -Force "Alias:$n" -ErrorAction SilentlyContinue }
    }
    function ll { eza -l @args }
    function la { eza -la @args }
    function l  { eza -a @args }
    function lt { eza --tree --level=2 @args }
} else {
    Set-Alias la Get-ChildItem
}

# Yazi: `y` launches yazi and cd's to the dir you quit in (q to keep, Q to cancel)
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}

# Prompt
function prompt {
    $currDir = (Get-Location).Path
    $baseName = (Get-Item -Path $currDir).Name
    return "$([char]27)[36m$($baseName)> $([char]27)[0m"
}

# Completion Settings
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -BellStyle None -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# kubectl completion powershell | Out-String | Invoke-Expression
# docker completion powershell | Out-String | Invoke-Expression


