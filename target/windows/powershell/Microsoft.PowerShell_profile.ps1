<#
# ----------------------------------------------------------------
# Module: PowerShell Visual Appearance Configuration
# ----------------------------------------------------------------
#>

### ================================
### PROMPT THEME
### ================================

function prompt {
	$esc = [char]27
	$reset = "$esc[0m"
	$gray = "$esc[90m"
	$blue = "$esc[94m"
	$green = "$esc[92m"
	$yellow = "$esc[93m"
	$magenta = "$esc[95m"
	$cyan = "$esc[96m"
	$red = "$esc[91m"

	$osIcon = "󰍲"
	$osName = "Windows"
	$shellName = if ($IsCoreCLR) { "pwsh" } else { "powershell" }

	$time = (Get-Date).ToString("HH:mm:ss")
	$date = (Get-Date).ToString("dd/MM/yy")
	$loc = (Get-Location).Path
	$pwd = Split-Path -Leaf $loc
	if ($loc -eq $HOME -or $loc -eq $env:USERPROFILE) { $pwd = "~" }
	$user = $env:USERNAME

	$gitInfo = ""
	try {
		$b = (git symbolic-ref --short HEAD 2>$null)
		if ($b) {
			$dirty = ""
			$status = (git status --porcelain=v1 -uno --ignore-submodules=dirty 2>$null)
			if ($status) { $dirty = "$yellow*" }
			$gitInfo = " $gray❮$red󰊢 $magenta$b$dirty$gray❯"
		}
	} catch { }

	$userColor = if ($IsAdmin) { $red } else { $green }
	$l1 = "$gray$blue$osIcon $magenta$osName$gray─$blue $magenta$shellName$gray"
	$l2 = "$gray┌──❮$blue $green$time$gray❯─❮$blue $green$date$gray❯─❮$yellow $cyan$pwd$gray❯─ ❮$blue $userColor$user$gray❯$gitInfo"
	$l3 = "$gray└─$blue$reset "

	return "`n$l1`n$l2`n$l3"
}

if ($Host.Name -eq 'ConsoleHost') {
	if (Get-Module -ListAvailable -Name Terminal-Icons) {
		Import-Module Terminal-Icons
	}
}
