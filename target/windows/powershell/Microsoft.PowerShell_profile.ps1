<#
# ----------------------------------------------------------------
# Module: PowerShell Visual Appearance Configuration
# ----------------------------------------------------------------
#>

if (-not $global:_ShellCoreLoaded) {
	$scriptDir = if ($PSCommandPath) { [System.IO.Path]::GetDirectoryName($PSCommandPath) } else { "" }
	$allHostsProfile = if ($scriptDir) { [System.IO.Path]::Combine($scriptDir, "profile.ps1") } else { "" }
	if ($allHostsProfile -and [System.IO.File]::Exists($allHostsProfile)) {
		. $allHostsProfile
	}
}

### ================================
### PROMPT THEME
### ================================

$script:winIcon = $null
$script:winName = $null

function _Initialize-PromptOsMetadata {
	$script:winIcon = ""
	$script:winName = "11"
	try {
		$build = [System.Environment]::OSVersion.Version.Build
		$displayVersion = [Microsoft.Win32.Registry]::GetValue(
			"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
			"DisplayVersion",
			$null
		)
		if ($build -ge 22000) {
			$script:winName = if ($displayVersion) { "11 $displayVersion" } else { "11" }
			$script:winIcon = ""
		} elseif ($build -ge 10240) {
			$script:winName = if ($displayVersion) { "10 $displayVersion" } else { "10" }
			$script:winIcon = ""
		} else {
			$script:winName = "NT 10.0"
			$script:winIcon = ""
		}
	} catch { }
}

function prompt {
	if (-not $script:winName) {
		_Initialize-PromptOsMetadata
	}

	$esc = [char]27
	$reset = "$esc[0m"
	$gray = "$esc[90m"
	$blue = "$esc[94m"
	$green = "$esc[92m"
	$yellow = "$esc[93m"
	$magenta = "$esc[95m"
	$cyan = "$esc[96m"
	$red = "$esc[91m"

	$osIcon = $script:winIcon
	$osName = $script:winName
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
			$gitInfo = " $gray$red󰊢 $magenta$b$dirty$gray"
		}
	} catch { }

	$isUserAdmin = if ($null -ne $global:IsAdmin) {
		$global:IsAdmin
	} elseif (Test-Path Function:\Test-IsAdmin) {
		Test-IsAdmin
	} else {
		$false
	}
	$userColor = if ($isUserAdmin) { $red } else { $green }
	$l1 = "$gray$blue$osIcon $magenta$osName $blue󰣆 ${magenta}NT 10.0 $blue $magenta$shellName$gray"
	$l2 = "$gray┌──$blue $green$time$gray─$blue $green$date$gray─$yellow $cyan$pwd$gray─ $blue $userColor$user$gray$gitInfo"
	$l3 = "$gray└─$blue$reset "

	return "`n$l1`n$l2`n$l3"
}

### ================================
### INTERACTIVE HOST & MODULES
### ================================

function _Test-ModuleInPath([string]$ModuleName) {
	foreach ($moduleDir in ($env:PSModulePath -split ';')) {
		if ($moduleDir -and [System.IO.Directory]::Exists([System.IO.Path]::Combine($moduleDir, $ModuleName))) {
			return $true
		}
	}
	return $false
}

if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
	try {
		if (_Test-ModuleInPath 'Terminal-Icons') {
			Import-Module Terminal-Icons -ErrorAction Stop
		}
	} catch {
		Write-Verbose ""
	}
	try {
		if (_Test-ModuleInPath 'PSReadLine') {
			Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
			Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction Stop
			Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction Stop
		}
	} catch {
		Write-Verbose ""
	}
}

### ================================
### CHOCOLATEY INTEGRATION
### ================================

if ($env:ChocolateyInstall) {
	$script:chocoProfilePath = [System.IO.Path]::Combine($env:ChocolateyInstall, 'helpers', 'chocolateyProfile.psm1')
	if ([System.IO.File]::Exists($script:chocoProfilePath)) {
		function Update-SessionEnvironment {
			Remove-Item Function:\Update-SessionEnvironment -Force -ErrorAction SilentlyContinue
			Remove-Item Alias:\refreshenv -Force -ErrorAction SilentlyContinue
			Import-Module $script:chocoProfilePath -Global -ErrorAction SilentlyContinue
			if (Get-Command Update-SessionEnvironment -CommandType Cmdlet -ErrorAction SilentlyContinue) {
				Update-SessionEnvironment @args
			}
		}
		Set-Alias -Name 'refreshenv' -Value 'Update-SessionEnvironment' -Force
	}
}
