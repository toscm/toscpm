# Aliases
Remove-Item Alias:r
Remove-Item -Force Alias:where
Set-Alias la Get-ChildItem

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


