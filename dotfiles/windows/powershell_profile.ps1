# Aliases
if (Test-Path Alias:r)     { Remove-Item Alias:r }
if (Test-Path Alias:where) { Remove-Item -Force Alias:where }
Set-Alias la Get-ChildItem

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


