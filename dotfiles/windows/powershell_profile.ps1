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

# Directory colours for `ls`, covering both eza and the Get-ChildItem fallback.
# PowerShell's default $PSStyle.FileInfo.Directory is `e[44;1m: it sets a blue
# background but no foreground, so names keep the scheme's normal foreground.
# On the light scheme that is #475365 on #3c60dd -- 1.45:1, and unreadable.
#
# A fixed fg/bg pair from the palette cannot fix it either. Monospace Light is
# built so all 16 entries are readable *on* its near-white background, which
# makes all 16 of them dark: the best pair it can form is 4.34:1, below the
# 4.5:1 floor. Any palette background is a dark background there.
#
# Reverse video (SGR 7) sidesteps that: it makes the text the terminal's own
# background colour, so the contrast becomes exactly the palette entry's
# contrast against the background -- the property both schemes already
# guarantee. Bright blue gives 4.95:1 on Campbell and 12.21:1 on Monospace
# Light. The terminal resolves it at render time, so it also follows the
# automatic scheme switch when Windows toggles light/dark mid-session.
if ($PSStyle) { $PSStyle.FileInfo.Directory = "$([char]27)[7;94m" }
$env:EZA_COLORS = "di=7;94"

# ISO dates. The en-DE culture's short date pattern is dd/MM/yyyy, which is
# impossible to tell apart from the US MM/dd/yyyy at a glance -- 04/03/2026 is
# either 4 March or 3 April depending on a setting you cannot see. Clone the
# culture and override only ShortDatePattern, so number formatting stays German
# (1.234,50); the pattern is still 10 characters wide, so the Get-ChildItem
# column does not shift. ShortTimePattern is already 24-hour, so it is left be.
$culture = [System.Globalization.CultureInfo]::CurrentCulture.Clone()
$culture.DateTimeFormat.ShortDatePattern = 'yyyy-MM-dd'
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture

# eza formats its own dates and ignores the .NET culture. TIME_STYLE is its
# equivalent knob (GNU ls compatible, so it applies to any ls run from here).
$env:TIME_STYLE = 'long-iso'

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


