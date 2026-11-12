<#
# ----------------------------------------------------------------
# Module: PowerShell Interactive Environment Profile
# ----------------------------------------------------------------
#>

### ================================
### CONFIGURACOES GERAIS
### ================================

$PSDefaultparameterValues['*:Encoding'] = 'utf8'

$env:HOME = $env:USERPROFILE
$SYSTEM32 = 'C:\Windows\System32'
$env:PYTHONPYCACHEPREFIX = if ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME 'pycache' } else { Join-Path $env:HOME '.cache\pycache' }

function Get-Msys2UserHome {
	$root     = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { 'C:\msys64' }
	$homeBase = if ($env:MSYS2_HOME) { $env:MSYS2_HOME } else { Join-Path $root 'home' }
	$user     = if ($env:MSYS2_USER) { $env:MSYS2_USER } else { $env:USERNAME }

	$target = Join-Path $homeBase $user
	if (-not (Test-Path $target)) {
		$target = Join-Path $homeBase $user.ToLower()
	}
	if (Test-Path $target) { return $target }
	return $null
}

function Get-Msys2Shell {
	$roots = @(
		$env:MSYS2_ROOT,
		'C:\msys64',
		'D:\msys64',
		'E:\msys64',
		(Join-Path $env:LOCALAPPDATA 'Programs\msys64'),
		'C:\Program Files\Git'
	)
	$candidateShells = @('zsh.exe', 'bash.exe', 'sh.exe', 'ksh.exe')
	foreach ($shName in $candidateShells) {
		foreach ($r in $roots) {
			if ($r) {
				$bin = Join-Path $r (Join-Path 'usr\bin' $shName)
				if (Test-Path $bin) { return $bin }
				$bin = Join-Path $r (Join-Path 'bin' $shName)
				if (Test-Path $bin) { return $bin }
			}
		}
	}
	foreach ($shName in @('zsh', 'bash', 'sh', 'ksh')) {
		$cmds = Get-Command "$shName.exe", $shName -ErrorAction SilentlyContinue
		foreach ($c in $cmds) {
			if ($c.Source -and ($c.Source -notmatch '(?i)[\\/]system32[\\/]')) {
				return $c.Source
			}
		}
	}
	return $null
}

$MsysHome = Get-Msys2UserHome

$vaultCandidates = @(
	$env:VAULT_DIR,
	(Join-Path $HOME ".local\share\vault"),
	(Join-Path $HOME ".config\vault"),
	(Join-Path $HOME ".vault")
)
if ($MsysHome) {
	$vaultCandidates += @(
		(Join-Path $MsysHome ".local\share\vault"),
		(Join-Path $MsysHome ".config\vault"),
		(Join-Path $MsysHome ".vault")
	)
}

$vaultDir = $vaultCandidates | Where-Object { $_ -and (Test-Path (Join-Path $_ "vault.ps1")) } | Select-Object -First 1

if ($vaultDir) {
	. (Join-Path $vaultDir "vault.ps1")
}

$shellCandidates = @(
	$env:SHELL_REPO_DIR,
	(Join-Path $PSScriptRoot "..\..\.."),
	(Join-Path $HOME ".local\share\shell"),
	(Join-Path $HOME ".config\shell"),
	(Join-Path $HOME ".shell"),
	"C:\Program Files\Shell"
)
if ($MsysHome) {
	$shellCandidates += @(
		(Join-Path $MsysHome ".local\share\shell"),
		(Join-Path $MsysHome ".config\shell"),
		(Join-Path $MsysHome ".shell")
	)
}
$shellDir = $shellCandidates | Where-Object { $_ -and (Test-Path (Join-Path $_ "shell.sh")) } | Select-Object -First 1
if ($shellDir -and -not $env:SHELL_REPO_DIR) {
	$env:SHELL_REPO_DIR = (Resolve-Path $shellDir).Path
}

$OneDrive  = "${Home}\onedrive"
$Desktop   = "${OneDrive}\Área de Trabalho"
$Documents = "${OneDrive}\Documentos"
$Images    = "${OneDrive}\Imagens"
$Workspace = "${OneDrive}\Workspace"
$Downloads = "${Home}\Downloads"

$VIRTUAL_STORE = "$($env:LOCALAPPDATA)\VirtualStore"
$FASM_STORE    = "${VIRTUAL_STORE}\Program Files\FASM"
$FASM2_STORE   = "${VIRTUAL_STORE}\Program Files\FASM2"
$FASMG_STORE   = "${VIRTUAL_STORE}\Program Files\FASMG"
$FASMARM_STORE = "${VIRTUAL_STORE}\Program Files\FASMARM"

$IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
$Machine = [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
$User    = [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)

### ================================
### NAVEGACAO E EDICAO
### ================================

function Edit-Profile-Logic {
	$target = if ($PROFILE -and (Test-Path $PROFILE)) { $PROFILE } else { "${Home}\OneDrive\Documentos\PowerShell\profile.ps1" }
	notepad++ $target
}
function Edit-Profile-Visual {
	$target = if ($PROFILE) {
		$dir = Split-Path $PROFILE
		Join-Path $dir "Microsoft.PowerShell_profile.ps1"
	} else {
		"${Home}\OneDrive\Documentos\PowerShell\Microsoft.PowerShell_profile.ps1"
	}
	notepad++ $target
}

function Goto-User { Set-Location -Path "${Home}" }
function Goto-OneDrive { Set-Location -Path "${OneDrive}" }
function Goto-Desktop { Set-Location -Path "${Desktop}" }
function Goto-Documents { Set-Location -Path "${Documents}" }
function Goto-Workspace { Set-Location -Path "${Workspace}" }
function Goto-Images { Set-Location -Path "${Images}" }
function Goto-Downloads { Set-Location -Path "${Downloads}" }
function Goto-Virtual-Store { Set-Location -Path "${VIRTUAL_STORE}" }
function Goto-FASM-Store { Set-Location -Path "${FASM_STORE}" }
function Goto-Machine { Set-Location -Path "$SYSTEM32" }
function Goto-Msys { Set-Location -Path $(if ($MsysHome) { $MsysHome } else { 'C:\msys64' }) }

function Show-Explorer { explorer.exe . }
function Show-User { explorer.exe "${Home}" }
function Show-OneDrive { explorer.exe "${OneDrive}" }
function Show-Desktop { explorer.exe "${Desktop}" }
function Show-Documents { explorer.exe "${Documents}" }
function Show-Workspace { explorer.exe "${Workspace}" }
function Show-Images { explorer.exe "${Images}" }
function Show-Downloads { explorer.exe "${Downloads}" }
function Show-Virtual-Store { explorer.exe "${VIRTUAL_STORE}" }
function Show-FASM-Store { explorer.exe "${FASM_STORE}" }
function Show-Machine { explorer.exe "$SYSTEM32" }
function Show-Msys { explorer.exe $(if ($MsysHome) { $MsysHome } else { 'C:\msys64' }) }

### ================================
### SISTEMA E ADMINISTRACAO
### ================================

function Start-Admin {
	param(
		[parameter(Mandatory=$true, Position=0)][string] $Name,
		[parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $Args,
		[parameter(Mandatory=$false)][string] $WindowStyle = "Normal",
		[parameter(Mandatory=$false)][switch] $NoNewWindow,
		[parameter(Mandatory=$false)][switch] $PassThru
	)

	if ($NoNewWindow -and $IsAdmin) {
		$process = Start-Process -FilePath $Name -ArgumentList $Args -NoNewWindow:$NoNewWindow -PassThru:$PassThru
	}
	elseif ($IsAdmin) {
		$process = Start-Process -FilePath $Name -ArgumentList $Args -WindowStyle $WindowStyle -PassThru:$PassThru
	}
	else {
		$process = Start-Process -FilePath $Name -ArgumentList $Args -Verb runAs -WindowStyle $WindowStyle -PassThru:$PassThru
	}
	return $process
}

function Start-Windows-Terminal-Admin {
	param([parameter(Mandatory=$true, Position=0)][string] $Name, [parameter(ValueFromRemainingArguments=$true)][string[]] $Args)
	$Args = $Name + " " + $Args
	Start-Admin -Name "wt.exe" -Args $Args
}

function Start-Console-Host-Admin {
	param([parameter(Mandatory=$true, Position=0)][string] $Name, [parameter(ValueFromRemainingArguments=$true)][string[]] $Args)
	$Args = $Name + " " + $Args
	Start-Admin -Name "conhost.exe" -Args $Args
}

### ================================
### AMBIENTE E VARIAVEIS
### ================================

function Setx-User {
	param(
		[Parameter(Mandatory=$true)] [string]$Name,
		[Parameter(Mandatory=$true)] [string]$Value
	)
	[Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
	Set-Item -Path "env:$Name" -Value $Value

	Write-Host "Variável '$Name' definida como '$Value' (User Scope)" -ForegroundColor Cyan
}

function Setx-Machine {
	param(
		[Parameter(Mandatory=$true)] [string]$Name,
		[Parameter(Mandatory=$true)] [string]$Value
	)
	$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

	if ($IsAdmin) {
		[Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Machine)
		Set-Item -Path "env:$Name" -Value $Value

		Write-Host "Variável '$Name' definida como '$Value' (Machine Scope)" -ForegroundColor Red
	} else {
		Write-Warning "Você precisa executar como Administrador para definir variáveis de sistema (Machine)."
	}
}

function Getx-User {
	param([string]$Name)
	$val = Get-Content "env:$Name" -ErrorAction SilentlyContinue
	if (-not $val) {
		$val = [Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::User)
	}
	return $val
}

function Getx-Machine {
	param([string]$Name)
	[Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::Machine)
}

function Get-VM-IPs {
	Get-VM | Where-Object {$_.State -eq "Running"} | ForEach-Object {
		$vm = $_
		$vm.NetworkAdapters | Select-Object @{N='VMName';E={$vm.VMName}}, MacAddress, SwitchName, IPAddresses
	}
}

function Get-IP {
	param([switch]$all)
	if ($all) {
		Get-NetIPConfiguration -Detailed
	} else {
		Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv6LinkLocalAddress, DNSServer
	}
}

### ================================
### FERRAMENTAS
### ================================

function Browser-Search {
	param([parameter(ValueFromRemainingArguments=$true)][string[]] $Args)
	lynx -use_mouse=on -nobrowse=on -nopause=on -show_cursor=off $Args
}

### ================================
### EMISSAO E UI SEMANTICA
### ================================

function _ui_step([string]$msg) { Write-Host "$([char]27)[1;36m==>$([char]27)[0m $msg" }
function _ui_sub([string]$msg)  { Write-Host "$([char]27)[1;34m  ↳$([char]27)[0m $msg" }
function _ui_ok([string]$msg)   { Write-Host "$([char]27)[1;32m  ✅$([char]27)[0m $msg" }
function _ui_warn([string]$msg) { Write-Host "$([char]27)[1;33m  ⚠️ $([char]27)[0m $msg" }
function _ui_err([string]$msg)  { [Console]::Error.WriteLine("$([char]27)[1;31m  ❌$([char]27)[0m $msg") }
function _ui_info([string]$msg) { Write-Host "$([char]27)[1;35m  ℹ️ $([char]27)[0m $msg" }

function _ui_banner([string]$title) {$sep = "=" * 64
	Write-Host "`n$([char]27)[1;36m$sep$([char]27)[0m"
	Write-Host "$([char]27)[1m  $title$([char]27)[0m"
	Write-Host "$([char]27)[1;36m$sep$([char]27)[0m`n"
}

### ================================
### ATUALIZACAO
### ================================

function Update-Winget {
	if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
		_ui_info "Winget não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Winget..."
	winget upgrade --all
	if ($LASTEXITCODE -eq 0) { _ui_ok "Winget atualizado com sucesso!" }
}

function Update-Scoop {
	if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
		_ui_info "Scoop não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Scoop..."
	scoop update
	scoop update --all
	_ui_ok "Scoop atualizado com sucesso!"
}

function Update-Choco {
	if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
		_ui_info "Chocolatey não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Chocolatey..."
	$process = Start-Process -FilePath "choco" -ArgumentList "upgrade all -y" -Verb RunAs -PassThru -WindowStyle Normal
	Wait-Process -InputObject $process
	_ui_ok "Chocolatey atualizado com sucesso!"
}

function Update-Windows {
	_ui_step "Executando Windows Update com reinicialização automática se necessário..."
	$cmd = "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
	$pw = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
	$process = Start-Process -FilePath $pw -ArgumentList "-Command $cmd" -Verb RunAs -PassThru -WindowStyle Normal
	Wait-Process -InputObject $process
	_ui_ok "Windows Update finalizado!"
}

function Update-Git {
	param(
		[parameter(Position=0, Mandatory=$false)][string] $Path = ".",
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-Git [[-Path] <caminho>] [-Status] [-DryRun] [-Help] (alias: upgit, plgit)

Localiza e atualiza repositórios Git recursivamente com proteção contra divergências.

Parâmetros:
  -Path <caminho>    Diretório raiz da busca (padrão: '.')
  -Status, -s        Audita status de branches, commits divergentes e arquivos locais
  -DryRun, -n        Simula a sincronização sem efetuar git pull
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$targetPath = if ($Path) { (Resolve-Path $Path).Path } else { (Get-Location).Path }
	if (-not (Test-Path $targetPath)) {
		_ui_err "Diretório não encontrado: $targetPath"
		return
	}

	$actionName = if ($Status) { "Auditando status de" } elseif ($DryRun) { "Simulando atualização de" } else { "Buscando e atualizando" }
	_ui_step "$actionName repositórios Git em: $targetPath"
	Write-Host ""

	$gitDirs = Get-ChildItem -Path $targetPath -Directory -Recurse -Depth 3 -Force -Filter ".git" -ErrorAction SilentlyContinue |
		Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count }
	if (-not $gitDirs) {
		_ui_info "Nenhum repositório Git encontrado em $targetPath (profundidade máxima: 3)."
		return
	}

	foreach ($gitDir in $gitDirs) {
		$repoDir = $gitDir.Parent.FullName
		$branch = git -C $repoDir branch --show-current 2>$null
		if (-not $branch) { $branch = "detached" }

		if ($Status) {
			$st = git -C $repoDir status -s 2>$null
			$unpushed = git -C $repoDir cherry -v 2>$null
			if ($st -or $unpushed) {
				_ui_warn "$repoDir [$branch]: divergências detectadas"
				if ($unpushed) { Write-Host "  ↳ Commits pendentes de push" -ForegroundColor DarkYellow }
				if ($st) { $st | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray } }
			} else {
				_ui_ok "$repoDir [$branch]: sincronizado e limpo"
			}
		} elseif ($DryRun) {
			_ui_sub "[DRY-RUN PULL] $repoDir [$branch]"
		} else {
			_ui_sub "Atualizando $repoDir..."
			git -C $repoDir pull --ff-only 2>$null
			if ($LASTEXITCODE -ne 0) {
				git -C $repoDir pull
			}
		}
	}
	Write-Host ""
	_ui_ok "Operação Git concluída!"
}

function Push-Git {
	param(
		[parameter(Position=0, Mandatory=$false)][string] $Path = ".",
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Push-Git [[-Path] <caminho>] [-Status] [-DryRun] [-Help] (alias: psgit)

Localiza repositórios Git recursivamente e envia commits pendentes upstream.

Parâmetros:
  -Path <caminho>    Diretório raiz da busca (padrão: '.')
  -Status, -s        Audita commits locais pendentes de envio (cherry -v)
  -DryRun, -n        Simula o envio de commits sem executar git push
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$targetPath = if ($Path) { (Resolve-Path $Path).Path } else { (Get-Location).Path }
	if (-not (Test-Path $targetPath)) {
		_ui_err "Diretório não encontrado: $targetPath"
		return
	}

	$actionName = if ($Status) { "Auditando commits pendentes em" } elseif ($DryRun) { "Simulando push de" } else { "Buscando e enviando" }
	_ui_step "$actionName repositórios Git em: $targetPath"
	Write-Host ""

	$gitDirs = Get-ChildItem -Path $targetPath -Directory -Recurse -Depth 3 -Force -Filter ".git" -ErrorAction SilentlyContinue |
		Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count } -Descending
	if (-not $gitDirs) {
		_ui_info "Nenhum repositório Git encontrado em $targetPath (profundidade máxima: 3)."
		return
	}

	foreach ($gitDir in $gitDirs) {
		$repoDir = $gitDir.Parent.FullName
		$unpushed = git -C $repoDir cherry -v 2>$null
		$branch = git -C $repoDir branch --show-current 2>$null
		if (-not $branch) { $branch = "detached" }

		if ($unpushed) {
			if ($Status) {
				_ui_warn "$repoDir [$branch]: commits pendentes de envio"
				$unpushed | ForEach-Object { Write-Host "  ↳ $_" -ForegroundColor DarkYellow }
			} elseif ($DryRun) {
				_ui_sub "[DRY-RUN PUSH] $repoDir [$branch]"
			} else {
				_ui_sub "Enviando $repoDir ($branch)..."
				git -C $repoDir push
				if ($LASTEXITCODE -eq 0) {
					_ui_ok "${repoDir}: push concluído com sucesso!"
				} else {
					_ui_err "${repoDir}: falha no push."
				}
			}
		} else {
			if ($Status) {
				_ui_ok "$repoDir [$branch]: nada a enviar"
			} else {
				_ui_ok "${repoDir}: já atualizado com o remote."
			}
		}
	}
	Write-Host ""
	_ui_ok "Operação Push Git concluída!"
}

function Update-Editors {
	param(
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[alias("e")][switch]$Extensions,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-Editors [-Status] [-DryRun] [-Extensions] [-Help] (alias: uped)

Atualiza os repositórios da Suíte de Editores (Emacs, Helix, NeoVim, Vim).

Parâmetros:
  -Status, -s        Audita o status Git de cada editor instalado
  -DryRun, -n        Simula a sincronização sem puxar alterações
  -Extensions, -e    Sincroniza também as extensões declarativas de IDE
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$action = if ($Status) { "Auditando status da" } elseif ($DryRun) { "Simulando atualização da" } else { "Atualizando a" }
	_ui_step "$action Suíte de Editores no Windows..."
	$found = 0

	$emacsCandidates = @(
		(Join-Path $HOME ".emacs.d"),
		(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".emacs.d" }),
		(if ($env:APPDATA) { Join-Path $env:APPDATA ".emacs.d" }),
		(Join-Path $HOME ".config\emacs")
	) | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -Unique
	$emacsPath = $emacsCandidates | Select-Object -First 1

	if ($emacsPath) {
		$found = 1
		if ($Status) {
			_ui_sub "Status de Emacs em $emacsPath..."
			git -C $emacsPath status -s -b
		} elseif ($DryRun) {
			_ui_sub "[DRY-RUN] Atualização de Emacs em $emacsPath..."
			_ui_sub "git -C $emacsPath pull --ff-only"
		} else {
			_ui_sub "Atualizando Emacs em $emacsPath..."
			if (Test-Path (Join-Path $emacsPath "usr\local")) {
				git -C $emacsPath clean -fd "usr/local" 2>$null
			}
			git -C $emacsPath pull --ff-only
			if (Test-Path (Join-Path $emacsPath ".gitmodules")) {
				_ui_sub "Sincronizando submódulos Elisp..."
				git -C $emacsPath submodule update --init --recursive --remote --merge
			}
			_ui_ok "Emacs atualizado com sucesso!"
		}
	}

	$helixCandidates = @(
		(if ($env:APPDATA) { Join-Path $env:APPDATA "helix" }),
		(Join-Path $HOME "AppData\Roaming\helix"),
		(Join-Path $HOME ".config\helix")
	) | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -Unique
	$helixPath = $helixCandidates | Select-Object -First 1

	if ($helixPath) {
		$found = 1
		if ($Status) {
			_ui_sub "Status de Helix em $helixPath..."
			git -C $helixPath status -s -b
		} elseif ($DryRun) {
			_ui_sub "[DRY-RUN] Atualização de Helix em $helixPath..."
			_ui_sub "git -C $helixPath pull --ff-only"
		} else {
			_ui_sub "Atualizando Helix em $helixPath..."
			git -C $helixPath pull --ff-only
			_ui_ok "Helix atualizado com sucesso!"
		}
	}

	$nvimCandidates = @(
		(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "nvim" }),
		(Join-Path $HOME "AppData\Local\nvim"),
		(Join-Path $HOME ".config\nvim")
	) | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -Unique
	$nvimPath = $nvimCandidates | Select-Object -First 1

	if ($nvimPath) {
		$found = 1
		if ($Status) {
			_ui_sub "Status de NeoVim em $nvimPath..."
			git -C $nvimPath status -s -b
		} elseif ($DryRun) {
			_ui_sub "[DRY-RUN] Atualização de NeoVim em $nvimPath..."
			_ui_sub "git -C $nvimPath pull --ff-only"
		} else {
			_ui_sub "Atualizando NeoVim em $nvimPath..."
			git -C $nvimPath pull --ff-only
			_ui_ok "NeoVim atualizado com sucesso!"
		}
	}

	$vimCandidates = @(
		(Join-Path $HOME "vimfiles"),
		(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE "vimfiles" }),
		(Join-Path $HOME ".vim"),
		(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".vim" })
	) | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -Unique
	$vimPath = $vimCandidates | Select-Object -First 1

	if ($vimPath) {
		$found = 1
		if ($Status) {
			_ui_sub "Status de Vim em $vimPath..."
			git -C $vimPath status -s -b
		} elseif ($DryRun) {
			_ui_sub "[DRY-RUN] Atualização de Vim em $vimPath..."
			_ui_sub "git -C $vimPath pull --ff-only"
		} else {
			_ui_sub "Atualizando Vim em $vimPath..."
			git -C $vimPath pull --ff-only
			_ui_ok "Vim atualizado com sucesso!"
		}
	}

	if ($found -eq 0) {
		_ui_info "Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, helix, nvim, vimfiles)."
	} else {
		_ui_ok "Suíte de Editores sincronizada com sucesso!"
	}

	if ($Extensions) {
		Sync-Extensions -Status:$Status -DryRun:$DryRun
	}
}

function Sync-Extensions {
	param(
		[string]$Target = "auto",
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[switch]$Export,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Sync-Extensions [[-Target] <editor>] [-Status] [-DryRun] [-Export] [-Help] (alias: upext)

Sincroniza extensões declarativas de IDE (VS Code, VSCodium, Antigravity).

Parâmetros:
  -Target <editor>   Editor alvo: auto (padrão), vscode, vscodium, antigravity
  -Status, -s        Audita e lista extensões declaradas
  -DryRun, -n        Simula a instalação sem modificar o ambiente
  -Export            Exporta extensões instaladas para o manifesto
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	_ui_step "Sincronizando extensões de IDE declarativas..."
	$candidates = @(
		$env:PROFILE_DIR,
		(Join-Path $HOME ".local\share\profile"),
		(Join-Path $HOME ".config\profile"),
		(Join-Path $HOME ".profile"),
		(Join-Path $HOME "OneDrive\Documentos\Profile"),
		(Join-Path $HOME "Documents\Profile")
	)
	if ($MsysHome) {
		$candidates += @(
			(Join-Path $MsysHome ".local\share\profile"),
			(Join-Path $MsysHome ".config\profile"),
			(Join-Path $MsysHome ".profile")
		)
	}
	$targetRepo = $candidates | Where-Object { $_ -and (Test-Path (Join-Path $_ "profile.sh")) } | Select-Object -First 1

	$sh = Get-Msys2Shell
	if ($targetRepo -and $sh) {
		$argsList = @("extensions")
		if ($Export) { $argsList += "export" }
		elseif ($Status) { $argsList += "status" }
		else { $argsList += "install" }
		if ($DryRun) { $argsList += "--dry-run" }
		if ($Target -ne "auto") { $argsList += $Target }

		$argStr = $argsList -join " "
		$targetPosix = ($targetRepo -replace '\\', '/')
		if ($targetPosix -match '^[A-Za-z]:') {
			$drive = $targetPosix.Substring(0, 1).ToLower()
			$rest = $targetPosix.Substring(2)
			$targetPosix = "/$drive$rest"
		}
		& $sh -c "MSYS=winsymlinks:nativestrict '$targetPosix/profile.sh' $argStr"
	} else {
		$ideCli = if (Get-Command "antigravity" -ErrorAction SilentlyContinue) { "antigravity" }
			elseif (Get-Command "code" -ErrorAction SilentlyContinue) { "code" }
			elseif (Get-Command "codium" -ErrorAction SilentlyContinue) { "codium" }
			else { $null }

		if (-not $ideCli) {
			_ui_warn "Nenhuma CLI de editor encontrada (antigravity, code, codium)."
			return
		}

		$ideFolder = if ($ideCli -eq "codium") { "vscodium" } elseif ($ideCli -eq "antigravity") { "antigravity" } else { "vscode" }
		$extFile = if ($targetRepo) { Join-Path $targetRepo "editors\$ideFolder\extensions.txt" } else { $null }

		if (-not $extFile -or -not (Test-Path $extFile)) {
			_ui_info "Manifesto de extensões não encontrado ($ideFolder)."
			return
		}

		Get-Content $extFile | ForEach-Object {
			$line = $_.Trim()
			if ($line -and -not $line.StartsWith("#")) {
				if ($Status) {
					_ui_sub "[DECLARADA] $line"
				} elseif ($DryRun) {
					_ui_sub "[DRY-RUN EXT] $ideCli --install-extension $line"
				} else {
					& $ideCli --install-extension $line --force *>$null
					_ui_ok "[EXT] $line"
				}
			}
		}
		_ui_ok "Sincronização de extensões concluída!"
	}
}

function Update-EmacsModes {
	$emacsCandidates = @(
		(Join-Path $HOME ".emacs.d"),
		(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".emacs.d" }),
		(if ($env:APPDATA) { Join-Path $env:APPDATA ".emacs.d" }),
		(Join-Path $HOME ".config\emacs")
	) | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -Unique
	$emacsPath = $emacsCandidates | Select-Object -First 1

	if (-not $emacsPath) {
		_ui_warn "Diretório do GNU Emacs não encontrado em ~/.emacs.d ou ~/.config/emacs."
		return
	}
	_ui_step "Atualizando submódulos Elisp locais em $emacsPath..."
	git -C $emacsPath submodule update --init --recursive --remote --merge
	if ($LASTEXITCODE -eq 0) {
		_ui_ok "Submódulos Elisp atualizados com sucesso!"
	} else {
		_ui_err "Falha na sincronização dos submódulos Elisp."
	}
}

function Update-Profile {
	param(
		[alias("s")][switch]$Status,
		[switch]$Pull,
		[alias("n")][switch]$DryRun,
		[alias("b")][switch]$Backup,
		[alias("e")][switch]$Extensions,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-Profile [-Status] [-DryRun] [-Backup] [-Extensions] [-Pull] [-Help] (alias: uprc)

Atualiza o repositório Universal Profile e sincroniza dotfiles via profile.sh.

Parâmetros:
  -Status, -s        Audita o status do Profile e compara divergências
  -DryRun, -n        Simula a sincronização sem alterar arquivos
  -Backup, -b        Cria backup (.bak) antes de substituir arquivos
  -Extensions, -e    Sincroniza extensões declarativas de IDE
  -Pull              Reconcilia alterações do sistema de volta ao Git
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$candidates = @(
		$env:PROFILE_DIR,
		(Join-Path $HOME ".local\share\profile"),
		(Join-Path $HOME ".config\profile"),
		(Join-Path $HOME ".profile"),
		(Join-Path $HOME "OneDrive\Documentos\Profile"),
		(Join-Path $HOME "Documents\Profile")
	)
	if ($MsysHome) {
		$candidates += @(
			(Join-Path $MsysHome ".local\share\profile"),
			(Join-Path $MsysHome ".config\profile"),
			(Join-Path $MsysHome ".profile")
		)
	}
	$target = $candidates | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -First 1

	if ($target) {
		if ($Status) {
			_ui_step "Status do Universal Profile em: $target..."
			git -C $target status -s -b
		} elseif ($DryRun) {
			_ui_step "[DRY-RUN] Atualização do Universal Profile em: $target..."
			_ui_sub "git -C $target pull --ff-only"
		} else {
			_ui_step "Atualizando Universal Profile em: $target..."
			$dirty = git -C $target status --porcelain 2>$null
			if ($dirty) {
				_ui_warn "Alterações locais não commitadas detectadas em: $target. Ignorando git pull para preservar dados."
			} else {
				git -C $target pull --ff-only
			}
		}

		$shSync = Join-Path $target "profile.sh"
		if (Test-Path $shSync) {
			_ui_sub "Sincronizando dotfiles via profile.sh (MSYS2 / POSIX)..."
			$syncArgs = @("sync")
			if ($Status)     { $syncArgs += "--status" }
			if ($Pull)       { $syncArgs += "--pull" }
			if ($DryRun)     { $syncArgs += "--dry-run" }
			if ($Backup)     { $syncArgs += "--backup" }
			if ($Extensions) { $syncArgs += "--extensions" }
			$argStr = $syncArgs -join " "
			$sh = Get-Msys2Shell
			if ($sh) {
				$targetPosix = ($target -replace '\\', '/')
				if ($targetPosix -match '^[A-Za-z]:') {
					$drive = $targetPosix.Substring(0, 1).ToLower()
					$rest = $targetPosix.Substring(2)
					$targetPosix = "/$drive$rest"
				}
				& $sh -c "MSYS=winsymlinks:nativestrict '$targetPosix/profile.sh' $argStr"
			} else {
				_ui_warn "Ambiente MSYS2/POSIX shell não detectado no PATH (excluído WSL em System32)."
			}
		}
		_ui_ok "Universal Profile atualizado e sincronizado com sucesso!"
	} else {
		_ui_info "Repositório do Profile não encontrado."
	}
}

function Update-Vault {
	param(
		[alias("s")][switch]$Status,
		[alias("k")][switch]$Keys,
		[alias("n")][switch]$DryRun,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-Vault [-Status] [-Keys] [-DryRun] [-Help] (alias: upvt)

Atualiza o repositório Universal Vault e recarrega variáveis e chaves de segurança.

Parâmetros:
  -Status, -s        Audita o status do repositório do cofre
  -Keys, -k          Recarrega variáveis e chaves do cofre
  -DryRun, -n        Simula o pull sem aplicar alterações
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$candidates = @(
		$env:VAULT_DIR,
		(Join-Path $HOME ".local\share\vault"),
		(Join-Path $HOME ".config\vault"),
		(Join-Path $HOME ".vault")
	)
	if ($MsysHome) {
		$candidates += @(
			(Join-Path $MsysHome ".local\share\vault"),
			(Join-Path $MsysHome ".config\vault"),
			(Join-Path $MsysHome ".vault")
		)
	}
	$target = $candidates | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -First 1

	if ($target) {
		if ($Status) {
			_ui_step "Status do Universal Vault em: $target..."
			git -C $target status -s -b
			return
		}
		if ($DryRun) {
			_ui_step "[DRY-RUN] Atualização do Universal Vault em: $target..."
			_ui_sub "git -C $target pull --ff-only"
			return
		}
		_ui_step "Atualizando Universal Vault em: $target..."
		git -C $target pull --ff-only
		$vaultScript = Join-Path $target "vault.ps1"
		if (Test-Path $vaultScript) {
			_ui_sub "Recarregando variáveis e chaves de segurança..."
			& $vaultScript
		}
		_ui_ok "Universal Vault atualizado com sucesso!"
	} else {
		_ui_info "Repositório do Vault não encontrado."
	}
}

function Update-Shell {
	param(
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-Shell [-Status] [-DryRun] [-Help] (alias: upsh)

Atualiza o repositório Universal Shell via git pull.

Parâmetros:
  -Status, -s        Audita o status do repositório Git local sem puxar
  -DryRun, -n        Simula a sincronização sem efetuar pull
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	$candidates = @(
		$env:SHELL_REPO_DIR,
		(Join-Path $HOME ".local\share\shell"),
		(Join-Path $HOME ".config\shell"),
		(Join-Path $HOME ".shell"),
		(Join-Path $HOME "Documentos\Environment\Shell"),
		(Join-Path $HOME "Documents\Environment\Shell"),
		(Join-Path $HOME "OneDrive\Documentos\Environment\Shell"),
		(Join-Path $HOME "OneDrive\Documents\Environment\Shell"),
		"C:\Program Files\Shell"
	)
	if ($MsysHome) {
		$candidates += @(
			(Join-Path $MsysHome ".local\share\shell"),
			(Join-Path $MsysHome ".config\shell"),
			(Join-Path $MsysHome ".shell")
		)
	}
	$target = $candidates | Where-Object { $_ -and (Test-Path (Join-Path $_ ".git")) } | Select-Object -First 1

	if ($target) {
		if ($Status) {
			_ui_step "Status do Universal Shell em: $target..."
			git -C $target status -s -b
			return
		}
		if ($DryRun) {
			_ui_step "[DRY-RUN] Atualização do Universal Shell em: $target..."
			_ui_sub "git -C $target pull --ff-only"
			return
		}
		_ui_step "Atualizando Universal Shell em: $target..."
		git -C $target pull --ff-only
		$pwshScript = Join-Path $target "target\windows\powershell\profile.ps1"
		if (Test-Path $pwshScript) {
			_ui_sub "Recarregando perfis e funções do Universal Shell..."
			. $pwshScript
			if ($PROFILE -and (Test-Path $PROFILE)) {
				$profItem = Get-Item $PROFILE -Force -ErrorAction SilentlyContinue
				$isSymlink = $profItem.LinkType -or ($profItem.FullName -eq (Get-Item $pwshScript -Force).FullName)
				if (-not $isSymlink) {
					Copy-Item $pwshScript $PROFILE -Force -ErrorAction SilentlyContinue
					_ui_sub "Sincronizado perfil físico em: $PROFILE"
				}
				$docDir = Split-Path $PROFILE
				$commonProfile = Join-Path $docDir "profile.ps1"
				if (Test-Path $commonProfile) {
					$comItem = Get-Item $commonProfile -Force -ErrorAction SilentlyContinue
					if ($comItem -and (-not $comItem.LinkType) -and ($comItem.FullName -ne (Get-Item $pwshScript -Force).FullName)) {
						Copy-Item $pwshScript $commonProfile -Force -ErrorAction SilentlyContinue
					}
				}
			}

			if ($env:APPDATA) {
				$appNu = Join-Path $env:APPDATA "nushell"
				$nuSrc = Join-Path $target "target\windows\nushell"
				if ((Test-Path $appNu) -and (Test-Path $nuSrc)) {
					$nuSynced = $false
					foreach ($f in @("config.nu", "env.nu")) {
						$srcF = Join-Path $nuSrc $f
						$dstF = Join-Path $appNu $f
						if (Test-Path $srcF) {
							$isLink = $false
							if (Test-Path $dstF) {
								$item = Get-Item $dstF -Force -ErrorAction SilentlyContinue
								if ($item -and ($item.LinkType -or ($item.FullName -eq (Get-Item $srcF -Force).FullName))) {
									$isLink = $true
								}
							}
							if (-not $isLink) {
								Copy-Item $srcF $dstF -Force -ErrorAction SilentlyContinue
								$nuSynced = $true
							}
						}
					}
					if ($nuSynced) {
						_ui_sub "Sincronizados perfis físicos NuShell em: $appNu"
					}
				}
			}
			if ($env:LOCALAPPDATA) {
				$appClink = Join-Path $env:LOCALAPPDATA "clink"
				$cmdSrc = Join-Path $target "target\windows\cmd"
				if ((Test-Path $appClink) -and (Test-Path $cmdSrc)) {
					$clinkSynced = $false
					foreach ($f in @("profile.lua", "profile.cmd")) {
						$srcF = Join-Path $cmdSrc $f
						$dstF = Join-Path $appClink $f
						if (Test-Path $srcF) {
							$isLink = $false
							if (Test-Path $dstF) {
								$item = Get-Item $dstF -Force -ErrorAction SilentlyContinue
								if ($item -and ($item.LinkType -or ($item.FullName -eq (Get-Item $srcF -Force).FullName))) {
									$isLink = $true
								}
							}
							if (-not $isLink) {
								Copy-Item $srcF $dstF -Force -ErrorAction SilentlyContinue
								$clinkSynced = $true
							}
						}
					}
					if ($clinkSynced) {
						_ui_sub "Sincronizados perfis físicos Clink em: $appClink"
					}
				}
			}
		}
		_ui_ok "Universal Shell atualizado com sucesso!"
	} else {
		_ui_info "Repositório do Shell não encontrado."
	}
}

function Reinstall-Shell {
	_ui_step "Recarregando ambiente do PowerShell..."
	if ($PROFILE -and (Test-Path $PROFILE)) {
		. $PROFILE
	} elseif ($env:SHELL_REPO_DIR -and (Test-Path (Join-Path $env:SHELL_REPO_DIR "target\windows\powershell\profile.ps1"))) {
		. (Join-Path $env:SHELL_REPO_DIR "target\windows\powershell\profile.ps1")
	}
	_ui_ok "PowerShell recarregado com sucesso!"
}

function Bench-Shell {
	_ui_step "Medindo tempo de inicialização do PowerShell..."
	$pwshExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
	$sw = [System.Diagnostics.Stopwatch]::StartNew()
	& $pwshExe -NoProfile -Command "exit"
	$sw.Stop()
	_ui_ok "Latência de boot limpo: $($sw.ElapsedMilliseconds) ms"
}

function Clean-Cache {
	_ui_step "Limpando caches temporários do Shell..."
	if (Test-Path "$env:LOCALAPPDATA\Temp") {
		Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter "*shell*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
	}
	_ui_ok "Cache do Universal Shell limpo com sucesso!"
}

function Update-Wifi {
	_ui_step "Auditando interfaces e perfis de rede sem fio..."
	netsh wlan show interfaces
	_ui_ok "Status de WiFi verificado com sucesso!"
}

function Update-Network {
	_ui_step "Auditando configurações e adaptadores de rede..."
	Get-NetAdapter | Format-Table -AutoSize
	_ui_ok "Rede verificada com sucesso!"
}

function Update-System {
	_ui_step "Atualizando gerenciadores de pacotes do sistema..."
	$found = $false
	if (Get-Command winget -ErrorAction SilentlyContinue) { Update-Winget; $found = $true }
	if (Get-Command scoop -ErrorAction SilentlyContinue)  { Update-Scoop; $found = $true }
	if (Get-Command choco -ErrorAction SilentlyContinue)  { Update-Choco; $found = $true }
	if (-not $found) {
		_ui_warn "Nenhum gerenciador de pacotes suportado (winget, scoop, choco) encontrado no sistema."
		return
	}
	_ui_ok "Atualização de pacotes do sistema concluída!"
}

function Clean-System {
	param(
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Clean-System [-Help] (alias: cleansys, sysclean, syscls, clean-system, clear-system, clearsys)

Limpeza de caches de pacotes e dependências obsoletas no Windows.
"@
		return
	}
	_ui_step "Executando limpeza de pacotes e caches do sistema..."
	if (Get-Command scoop -ErrorAction SilentlyContinue) {
		_ui_sub "Limpando cache de instaladores do Scoop..."
		scoop cache rm * 2>$null
		scoop cleanup * 2>$null
	}
	if (Get-Command choco -ErrorAction SilentlyContinue) {
		_ui_sub "Limpando cache temporário do Chocolatey..."
		powershell -NoProfile -Command "Start-Process choco -ArgumentList 'cache remove' -Verb RunAs -Wait" 2>$null
	}
	_ui_ok "Limpeza do sistema concluída!"
}

function Update-All {
	param(
		[alias("s")][switch]$Status,
		[alias("n")][switch]$DryRun,
		[alias("h")][switch]$Help
	)
	if ($Help) {
		Write-Host @"
Uso: Update-All [-Status] [-DryRun] [-Help] (alias: upall)

Atualização geral e coordenada do ecossistema e gerenciadores de pacotes do sistema.

Parâmetros:
  -Status, -s        Executa auditoria e diagnóstico geral sem atualizar
  -DryRun, -n        Simula a atualização de todos os componentes
  -Help, -h          Exibe esta ajuda
"@
		return
	}
	if ($Status) {
		_ui_banner "Status Global do Ecossistema"
		Update-Profile -Status
		Update-Vault -Status
		Update-Shell -Status
		Update-Editors -Status
		_ui_banner "Verificação de Status Concluída"
		return
	}
	if ($DryRun) {
		_ui_banner "Simulação Global do Ecossistema (Dry-Run)"
		Update-Profile -DryRun
		Update-Vault -DryRun
		Update-Shell -DryRun
		Update-Editors -DryRun
		_ui_banner "Simulação Concluída"
		return
	}
	_ui_banner "Atualização Global do Ecossistema e Sistema"
	Update-System
	Update-Profile
	Update-Vault
	Update-Shell
	Update-Editors
	Clean-System
	_ui_banner "Atualização Global Concluída com Sucesso"
}

### ================================
### MANUAIS E DOCUMENTACAO
### ================================

function Windows-Manual {
	param([string]$term)
	Start-Process "https://learn.microsoft.com/en-us/search/?terms=$term"
}

function Unix-Manual {
	param([string] $section, [string] $command)
	$number = $section
	if (-not [char]::IsDigit($section[-1])) { $number = $section -replace ".$" }
	wsl w3m "https://www.man7.org/linux/man-pages/man$number/$command.$section.html"
}

function Wsl-Manual {
	param([parameter(ValueFromRemainingArguments=$true)][string[]] $Args)
	wsl man $Args
}

### ================================
### ALIASES
### ================================

Set-Alias "show" "Show-Explorer" -Force -Option AllScope
Set-Alias "clr" "clear" -Force -Option AllScope
Set-Alias "ip" "Get-IP" -Force -Option AllScope

Set-Alias "mkledit" "Edit-MakeLua" -Force -Option AllScope

Set-Alias "admin" "Start-Admin" -Force -Option AllScope
Set-Alias "admin-wt" "Start-Windows-Terminal-Admin" -Force -Option AllScope
Set-Alias "admin-ch" "Start-Console-Host-Admin" -Force -Option AllScope

Set-Alias "upget" "Update-Winget" -Force -Option AllScope
Set-Alias "upscp" "Update-Scoop" -Force -Option AllScope
Set-Alias "upcho" "Update-Choco" -Force -Option AllScope
Set-Alias "upsys" "Update-System" -Force -Option AllScope
Set-Alias "upsh" "Update-Shell" -Force -Option AllScope
Set-Alias "upmod" "Update-Module" -Force -Option AllScope
Set-Alias "upwin" "Update-Windows" -Force -Option AllScope
Set-Alias "upgit" "Update-Git" -Force -Option AllScope
Set-Alias "plgit" "Update-Git" -Force -Option AllScope
Set-Alias "psgit" "Push-Git" -Force -Option AllScope
Set-Alias "uped" "Update-Editors" -Force -Option AllScope
Set-Alias "update-extensions" "Sync-Extensions" -Force -Option AllScope
Set-Alias "upext" "Sync-Extensions" -Force -Option AllScope
Set-Alias "uprc" "Update-Profile" -Force -Option AllScope
Set-Alias "upprofile" "Update-Profile" -Force -Option AllScope
Set-Alias "sync-profile" "Update-Profile" -Force -Option AllScope
Set-Alias "upvt" "Update-Vault" -Force -Option AllScope
Set-Alias "u" "Update-All" -Force -Option AllScope
Set-Alias "upall" "Update-All" -Force -Option AllScope
Set-Alias "update-emacs-modes" "Update-EmacsModes" -Force -Option AllScope
Set-Alias "upmodes" "Update-EmacsModes" -Force -Option AllScope
Set-Alias "reinstall-shell" "Reinstall-Shell" -Force -Option AllScope
Set-Alias "resh" "Reinstall-Shell" -Force -Option AllScope
Set-Alias "bench-shell" "Bench-Shell" -Force -Option AllScope
Set-Alias "bsh" "Bench-Shell" -Force -Option AllScope
Set-Alias "shell-bench" "Bench-Shell" -Force -Option AllScope
Set-Alias "clean-cache" "Clean-Cache" -Force -Option AllScope
Set-Alias "ccache" "Clean-Cache" -Force -Option AllScope
Set-Alias "cleancache" "Clean-Cache" -Force -Option AllScope
Set-Alias "update-wifi" "Update-Wifi" -Force -Option AllScope
Set-Alias "upwf" "Update-Wifi" -Force -Option AllScope
Set-Alias "update-network" "Update-Network" -Force -Option AllScope
Set-Alias "upnet" "Update-Network" -Force -Option AllScope
Set-Alias "cleansys" "Clean-System" -Force -Option AllScope
Set-Alias "clearsys" "Clean-System" -Force -Option AllScope
Set-Alias "sysclean" "Clean-System" -Force -Option AllScope
Set-Alias "syscls" "Clean-System" -Force -Option AllScope
Set-Alias "clear-system" "Clean-System" -Force -Option AllScope

Remove-Item alias:gl -Force -ErrorAction SilentlyContinue
Remove-Item alias:gp -Force -ErrorAction SilentlyContinue
Remove-Item alias:gcm -Force -ErrorAction SilentlyContinue

function Invoke-GitStatusSb { git status -sb @args }
Set-Alias "gs" "Invoke-GitStatusSb" -Force -Option AllScope
function Invoke-GitDiff { git diff @args }
Set-Alias "gd" "Invoke-GitDiff" -Force -Option AllScope
function Invoke-GitStatus { git status @args }
Set-Alias "gst" "Invoke-GitStatus" -Force -Option AllScope
function Invoke-GitCheckout { git checkout @args }
Set-Alias "gco" "Invoke-GitCheckout" -Force -Option AllScope
function Invoke-GitCheckoutBranch { git checkout -b @args }
Set-Alias "gcb" "Invoke-GitCheckoutBranch" -Force -Option AllScope
function Invoke-GitSwitch { git switch @args }
Set-Alias "gsw" "Invoke-GitSwitch" -Force -Option AllScope
function Invoke-GitSwitchCreate { git switch -c @args }
Set-Alias "gswc" "Invoke-GitSwitchCreate" -Force -Option AllScope
function Invoke-GitCommitMsg { git commit -m @args }
Set-Alias "gcm" "Invoke-GitCommitMsg" -Force -Option AllScope
function Invoke-GitAddAll { git add --all @args }
Set-Alias "gaa" "Invoke-GitAddAll" -Force -Option AllScope
function Invoke-GitPull { git pull @args }
Set-Alias "gl" "Invoke-GitPull" -Force -Option AllScope
function Invoke-GitPush { git push @args }
Set-Alias "gp" "Invoke-GitPush" -Force -Option AllScope
function Invoke-GitLogGraph { git log --oneline --decorate --graph -n 20 @args }
Set-Alias "glog" "Invoke-GitLogGraph" -Force -Option AllScope

Set-Alias "brw" "Browser-Search" -Force -Option AllScope
Set-Alias "win-man" "Windows-Manual" -Force -Option AllScope
Set-Alias "wman" "Windows-Manual" -Force -Option AllScope
Set-Alias "unix-man" "Unix-Manual" -Force -Option AllScope
Set-Alias "uman" "Unix-Manual" -Force -Option AllScope
Set-Alias "mandoc" "Unix-Manual" -Force -Option AllScope
Set-Alias "wsl-man" "Wsl-Manual" -Force -Option AllScope

### ================================
### SERVER ALIASES
### ================================

function Resolve-VaultSshKey([string]$explicitKey, [string]$keyName) {
	if ($explicitKey -and (Test-Path $explicitKey)) { return $explicitKey }
	$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { "~" }

	$candidates = @(
		$(if ($env:VAULT_DIR) { Join-Path $env:VAULT_DIR "keys\$keyName" }),
		(Join-Path $homeDir ".local\share\vault\keys\$keyName"),
		(Join-Path $homeDir ".config\vault\keys\$keyName"),
		(Join-Path $homeDir ".vault\keys\$keyName")
	)

	if ($MsysHome) {
		$candidates += @(
			(Join-Path $MsysHome ".local\share\vault\keys\$keyName"),
			(Join-Path $MsysHome ".config\vault\keys\$keyName"),
			(Join-Path $MsysHome ".vault\keys\$keyName")
		)
	}

	return ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
}

function personal-server {
	$ip = if ($env:PERSONAL_SERVER_IP) { $env:PERSONAL_SERVER_IP } else { "144.22.210.65" }
	$user = if ($env:PERSONAL_SERVER_USER) { $env:PERSONAL_SERVER_USER } else { "ubuntu" }
	$key = Resolve-VaultSshKey $env:PERSONAL_SERVER_KEY "ssh-key-personal-server.key"
	if ($key) {
		$env:PERSONAL_SERVER_KEY = $key
		ssh -i $key "${user}@${ip}" $args
	} else {
		ssh "${user}@${ip}" $args
	}
}

function venture-server {
	$ip = if ($env:VENTURE_SERVER_IP) { $env:VENTURE_SERVER_IP } else { "137.131.238.161" }
	$user = if ($env:VENTURE_SERVER_USER) { $env:VENTURE_SERVER_USER } else { "ubuntu" }
	$key = Resolve-VaultSshKey $env:VENTURE_SERVER_KEY "ssh-key-venture-server.key"
	if ($key) {
		$env:VENTURE_SERVER_KEY = $key
		ssh -i $key "${user}@${ip}" $args
	} else {
		ssh "${user}@${ip}" $args
	}
}

### ================================
### EMACS ALIASES
### ================================

function _restore_tty_cursor {
	[Console]::Write("$([char]27)[1 q$([char]27)]112`a$([char]27)]112$([char]27)\")
}

function ek {
	taskkill /IM emacs.exe /F
	_restore_tty_cursor
}
function es {
	runemacs --fg-daemon
	_restore_tty_cursor
}
function er {
	ek
	es
	_restore_tty_cursor
}
function ec {
	emacsclientw --create-frame --alternate-editor "" $args
	_restore_tty_cursor
}
function emacs-nw {
	if (Get-Command emacs -ErrorAction SilentlyContinue) {
		emacs -nw @args
	} elseif (Get-Command emacs.exe -ErrorAction SilentlyContinue) {
		emacs.exe -nw @args
	} else {
		_ui_err "emacs not found."
	}
	_restore_tty_cursor
}
Set-Alias "en" "emacs-nw" -Force -Option AllScope
Set-Alias "enw" "emacs-nw" -Force -Option AllScope

function emacs-open-nw {
	$target = if ($args) { $args } else { @(".") }
	emacs-nw @target
	_restore_tty_cursor
}
Set-Alias "oen" "emacs-open-nw" -Force -Option AllScope
Set-Alias "oenw" "emacs-open-nw" -Force -Option AllScope
Set-Alias "open-emacs-nw" "emacs-open-nw" -Force -Option AllScope

function Invoke-EmacsEshell {
	$dir = if ($args) { $args[0] } else { "." }
	if (Test-Path $dir) { $dir = (Resolve-Path $dir).Path.Replace('\', '/') }
	if (Get-Command emacsclientw -ErrorAction SilentlyContinue) {
		emacsclientw --create-frame --alternate-editor "" --eval "(progn (cd `"$dir/`") (aweshell/new))"
	} elseif (Get-Command runemacs -ErrorAction SilentlyContinue) {
		runemacs --eval "(progn (cd `"$dir/`") (aweshell/new))"
	} else {
		_ui_err "emacs not found."
	}
	_restore_tty_cursor
}
Set-Alias "emacs-eshell" "Invoke-EmacsEshell" -Force -Option AllScope
Set-Alias "open-eshell" "Invoke-EmacsEshell" -Force -Option AllScope
Set-Alias "oes" "Invoke-EmacsEshell" -Force -Option AllScope
Set-Alias "esh" "Invoke-EmacsEshell" -Force -Option AllScope

function oe {
	$app = "emacsclientw"
	$target = if ($args) { $args } else { "." }
	$argList = @("--create-frame", "--alternate-editor", '""', $target)
	Start-Process -FilePath $app -ArgumentList $argList -WindowStyle Hidden
	_restore_tty_cursor
}

### ================================
### CODE EDITORS & APPS ALIASES
### ================================

function Invoke-OpenVlc {
	$target = if ($args) { $args } else { @() }
	Start-Process -FilePath "vlc" -ArgumentList $target
}
Set-Alias "open-vlc" "Invoke-OpenVlc" -Force -Option AllScope
Set-Alias "ov" "Invoke-OpenVlc" -Force -Option AllScope

function Invoke-OpenMpv {
	if ($args) {
		& mpv @args
	} else {
		& mpv .
	}
}
Set-Alias "open-mpv" "Invoke-OpenMpv" -Force -Option AllScope
Set-Alias "om" "Invoke-OpenMpv" -Force -Option AllScope

function Invoke-OpenWireshark {
	$target = if ($args) { $args } else { @() }
	Start-Process -FilePath "wireshark" -ArgumentList $target
}
Set-Alias "open-wireshark" "Invoke-OpenWireshark" -Force -Option AllScope
Set-Alias "open-shark" "Invoke-OpenWireshark" -Force -Option AllScope
Set-Alias "os" "Invoke-OpenWireshark" -Force -Option AllScope

function Invoke-OpenFirefox {
	$target = if ($args) { $args } else { @() }
	Start-Process -FilePath "firefox" -ArgumentList $target
}
Set-Alias "open-firefox" "Invoke-OpenFirefox" -Force -Option AllScope
Set-Alias "of" "Invoke-OpenFirefox" -Force -Option AllScope

function Invoke-OpenBrowser {
	$candidates = @(
		"google-chrome", "google-chrome-stable", "chrome",
		"brave-browser", "brave",
		"chromium", "chromium-browser",
		"microsoft-edge", "msedge",
		"firefox"
	)
	$browser = $null
	foreach ($b in $candidates) {
		if (Get-Command $b -ErrorAction SilentlyContinue) {
			$browser = $b
			break
		}
	}
	if (-not $browser) {
		$browserPaths = @(
			"${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
			"${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
			"${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe",
			"${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe",
			"${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
			"${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
		)
		foreach ($bp in $browserPaths) {
			if (Test-Path $bp) { $browser = $bp; break }
		}
	}
	if ($browser) {
		$target = if ($args) { $args } else { @() }
		Start-Process -FilePath $browser -ArgumentList $target
	} else {
		_ui_err "Nenhum navegador suportado encontrado."
	}
}
Set-Alias "open-browser" "Invoke-OpenBrowser" -Force -Option AllScope
Set-Alias "open-web" "Invoke-OpenBrowser" -Force -Option AllScope
Set-Alias "ow" "Invoke-OpenBrowser" -Force -Option AllScope

function Invoke-OpenOnlyOffice {
	$candidates = @("onlyoffice-desktopeditors", "desktopeditors")
	$bin = $candidates | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
	if (-not $bin) {
		$ooPath = "${env:ProgramFiles}\ONLYOFFICE\DesktopEditors\DesktopEditors.exe"
		if (Test-Path $ooPath) { $bin = $ooPath }
	}
	if ($bin) {
		$target = if ($args) { $args } else { @() }
		Start-Process -FilePath $bin -ArgumentList $target
	} else {
		_ui_err "OnlyOffice não encontrado."
	}
}
Set-Alias "open-onlyoffice" "Invoke-OpenOnlyOffice" -Force -Option AllScope
Set-Alias "oo" "Invoke-OpenOnlyOffice" -Force -Option AllScope

function Invoke-OpenLibreOffice {
	$candidates = @("libreoffice", "soffice")
	$bin = $candidates | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
	if (-not $bin) {
		$loPath = "${env:ProgramFiles}\LibreOffice\program\soffice.exe"
		if (Test-Path $loPath) { $bin = $loPath }
	}
	if ($bin) {
		$target = if ($args) { $args } else { @() }
		Start-Process -FilePath $bin -ArgumentList $target
	} else {
		_ui_err "LibreOffice não encontrado."
	}
}
Set-Alias "open-libreoffice" "Invoke-OpenLibreOffice" -Force -Option AllScope
Set-Alias "ol" "Invoke-OpenLibreOffice" -Force -Option AllScope

function Invoke-OpenTerminal {
	$target = if ($args) { $args } else { @() }
	if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
		Start-Process -FilePath "wt.exe" -ArgumentList $target
	} elseif (Get-Command alacritty -ErrorAction SilentlyContinue) {
		Start-Process -FilePath "alacritty" -ArgumentList $target
	} else {
		Start-Process -FilePath "powershell.exe"
	}
}
Set-Alias "open-terminal" "Invoke-OpenTerminal" -Force -Option AllScope
Set-Alias "ot" "Invoke-OpenTerminal" -Force -Option AllScope

function Invoke-OpenThunderbird {
	$bin = if (Get-Command thunderbird -ErrorAction SilentlyContinue) { "thunderbird" }
		elseif (Test-Path "${env:ProgramFiles}\Mozilla Thunderbird\thunderbird.exe") { "${env:ProgramFiles}\Mozilla Thunderbird\thunderbird.exe" }
		else { $null }
	if ($bin) {
		$target = if ($args) { $args } else { @() }
		Start-Process -FilePath $bin -ArgumentList $target
	} else {
		_ui_err "Thunderbird não encontrado."
	}
}
Set-Alias "open-thunderbird" "Invoke-OpenThunderbird" -Force -Option AllScope
Set-Alias "omail" "Invoke-OpenThunderbird" -Force -Option AllScope
Set-Alias "oth" "Invoke-OpenThunderbird" -Force -Option AllScope

function Invoke-OpenKate {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "kate" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-kate" "Invoke-OpenKate" -Force -Option AllScope
Set-Alias "ok" "Invoke-OpenKate" -Force -Option AllScope

function Invoke-OpenGeany {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "geany" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-geany" "Invoke-OpenGeany" -Force -Option AllScope
Set-Alias "og" "Invoke-OpenGeany" -Force -Option AllScope

function Invoke-OpenCode {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "code" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-code" "Invoke-OpenCode" -Force -Option AllScope
Set-Alias "oc" "Invoke-OpenCode" -Force -Option AllScope

function Invoke-OpenCodium {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "codium" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-codium" "Invoke-OpenCodium" -Force -Option AllScope
Set-Alias "ocm" "Invoke-OpenCodium" -Force -Option AllScope

function Invoke-OpenZed {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "zed" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-zed" "Invoke-OpenZed" -Force -Option AllScope
Set-Alias "oz" "Invoke-OpenZed" -Force -Option AllScope

function Invoke-OpenAntigravity {
	$target = if ($args) { $args } else { "." }
	Start-Process -FilePath "antigravity-ide" -ArgumentList $target -WindowStyle Hidden
}
Set-Alias "open-antigravity" "Invoke-OpenAntigravity" -Force -Option AllScope
Set-Alias "open-ant" "Invoke-OpenAntigravity" -Force -Option AllScope
Set-Alias "oa" "Invoke-OpenAntigravity" -Force -Option AllScope
Set-Alias "ant" "Invoke-OpenAntigravity" -Force -Option AllScope
Set-Alias "open-emacs" "oe" -Force -Option AllScope

function Invoke-UniversalEditor {
	$target = if ($args) { $args } else { @(".") }
	if (Get-Command nvim -ErrorAction SilentlyContinue) {
		nvim @target
	} elseif (Get-Command vim -ErrorAction SilentlyContinue) {
		vim @target
	} elseif (Get-Command hx -ErrorAction SilentlyContinue) {
		hx @target
	} elseif (Get-Command emacs -ErrorAction SilentlyContinue) {
		emacs -nw @target
	} elseif (Get-Command emacs.exe -ErrorAction SilentlyContinue) {
		emacs.exe -nw @target
	} else {
		notepad.exe @target
	}
}
Set-Alias "editor" "Invoke-UniversalEditor" -Force -Option AllScope
Set-Alias "e" "Invoke-UniversalEditor" -Force -Option AllScope

function Invoke-OpenHelix {
	$target = if ($args) { $args } else { @(".") }
	hx @target
}
Set-Alias "open-helix" "Invoke-OpenHelix" -Force -Option AllScope
Set-Alias "open-hx" "Invoke-OpenHelix" -Force -Option AllScope
Set-Alias "oh" "Invoke-OpenHelix" -Force -Option AllScope
Set-Alias "h" "Invoke-OpenHelix" -Force -Option AllScope

function Invoke-OpenSmart {
	if (-not $args) {
		_ui_warn "Uso: o <arquivo|diretorio|url>"
		return
	}
	foreach ($target in $args) {
		if ($target -match '^https?://') {
			Start-Process $target
			continue
		}
		if (Test-Path $target -PathType Container) {
			explorer.exe $target
			continue
		}
		$ext = [System.IO.Path]::GetExtension($target).ToLower()
		$docExts = @('.pdf', '.epub', '.djvu', '.sqlite', '.sqlite3', '.db', '.org', '.md', '.txt', '.tex', '.el', '.sh', '.py', '.c', '.h', '.rs', '.go', '.js', '.ts', '.json', '.yaml', '.yml', '.toml', '.xml', '.csv', '.log', '.diff', '.patch', '.zip', '.tar', '.gz', '.xz', '.7z')
		if ($docExts -contains $ext) {
			if (Get-Command emacsclientw -ErrorAction SilentlyContinue) {
				Start-Process -FilePath "emacsclientw" -ArgumentList @("-n", $target) -WindowStyle Hidden
				continue
			} elseif (Get-Command emacs -ErrorAction SilentlyContinue) {
				emacs -nw $target
				continue
			}
		}
		Start-Process $target
	}
}
Set-Alias "open-smart" "Invoke-OpenSmart" -Force -Option AllScope
Set-Alias "o" "Invoke-OpenSmart" -Force -Option AllScope
Set-Alias "open" "Invoke-OpenSmart" -Force -Option AllScope

function Invoke-TakeDir([string]$dir) {
	if (-not $dir) {
		Write-Error "Uso: take <diretorio>"
		return
	}
	if (-not (Test-Path $dir)) {
		New-Item -ItemType Directory -Path $dir -Force | Out-Null
	}
	Set-Location $dir
}
Set-Alias "take-dir" "Invoke-TakeDir" -Force -Option AllScope
Set-Alias "take" "Invoke-TakeDir" -Force -Option AllScope
Set-Alias "mkcd" "Invoke-TakeDir" -Force -Option AllScope

function Invoke-CdGitRoot {
	$root = git rev-parse --show-toplevel 2>$null
	if ($root) {
		Set-Location $root
	} else {
		_ui_err "Não está dentro de um repositório git."
	}
}
Set-Alias "cd-git-root" "Invoke-CdGitRoot" -Force -Option AllScope
Set-Alias "cdb" "Invoke-CdGitRoot" -Force -Option AllScope

function Invoke-HistSearch([string]$term) {
	if (-not $term) {
		Get-History -Count 30
	} else {
		Get-History | Where-Object { $_.CommandLine -like "*$term*" }
	}
}
Set-Alias "hist" "Invoke-HistSearch" -Force -Option AllScope
Set-Alias "hg" "Invoke-HistSearch" -Force -Option AllScope

function Invoke-ExtractArchive([string]$file) {
	if (-not $file) {
		Write-Error "Uso: extract <arquivo>"
		return
	}
	if (-not (Test-Path $file)) {
		_ui_err "Arquivo '$file' não encontrado."
		return
	}
	switch -Wildcard ($file) {
		"*.zip" { Expand-Archive -Path $file -DestinationPath . -Force }
		"*.tar.gz" { tar -xzvf $file }
		"*.tgz" { tar -xzvf $file }
		"*.tar.bz2" { tar -xjvf $file }
		"*.tbz2" { tar -xjvf $file }
		"*.tar.xz" { tar -xJvf $file }
		"*.txz" { tar -xJvf $file }
		"*.tar" { tar -xvf $file }
		"*.7z" { if (Get-Command 7z -ErrorAction SilentlyContinue) { 7z x $file } else { tar -xvf $file } }
		"*.rar" { if (Get-Command unrar -ErrorAction SilentlyContinue) { unrar x $file } else { _ui_err "unrar não encontrado." } }
		default { _ui_err "Formato não suportado para extração: '$file'" }
	}
}
Set-Alias "extract" "Invoke-ExtractArchive" -Force -Option AllScope
Set-Alias "x" "Invoke-ExtractArchive" -Force -Option AllScope

function path-front([string]$dir) {
	if ($dir -and (Test-Path $dir)) {
		$env:PATH = "$dir;$env:PATH"
	}
}
function path-back([string]$dir) {
	if ($dir -and (Test-Path $dir)) {
		$env:PATH = "$env:PATH;$dir"
	}
}
function path-dedup {
	$parts = $env:PATH -split ';' | Where-Object { $_ -and (Test-Path $_) }
	$unique = @()
	foreach ($p in $parts) {
		if ($unique -notcontains $p) {
			$unique += $p
		}
	}
	$env:PATH = $unique -join ';'
}

### ================================
### MODERN RUST TOOLS ALIASES
### ================================

if (Get-Command rg -ErrorAction SilentlyContinue) {
	Set-Alias "r" "rg" -Force -Option AllScope
	Set-Alias "g" "rg" -Force -Option AllScope
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
	function Invoke-EzaCompact { eza --icons=auto --group-directories-first @args }
	function Invoke-EzaLong { eza -la --icons=auto --group-directories-first --git @args }
	function Invoke-EzaAll { eza -a --icons=auto --group-directories-first @args }
	function Invoke-EzaTree { eza --tree --icons=auto --group-directories-first @args }
	function Invoke-EzaRecurseCompact { eza -R --icons=auto --group-directories-first @args }
	function Invoke-EzaRecurseAll { eza -aR --icons=auto --group-directories-first @args }
	function Invoke-EzaRecurseLong { eza -laR --icons=auto --group-directories-first --git @args }
	Set-Alias "l" "Invoke-EzaCompact" -Force -Option AllScope
	Set-Alias "ll" "Invoke-EzaLong" -Force -Option AllScope
	Set-Alias "la" "Invoke-EzaAll" -Force -Option AllScope
	Set-Alias "lt" "Invoke-EzaTree" -Force -Option AllScope
	Set-Alias "lr" "Invoke-EzaRecurseCompact" -Force -Option AllScope
	Set-Alias "lar" "Invoke-EzaRecurseAll" -Force -Option AllScope
	Set-Alias "llr" "Invoke-EzaRecurseLong" -Force -Option AllScope
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
	function Invoke-BatPlain { bat --paging=never @args }
	Set-Alias "c" "Invoke-BatPlain" -Force -Option AllScope
	Set-Alias "b" "bat" -Force -Option AllScope
}

if (Get-Command fd -ErrorAction SilentlyContinue) {
	Set-Alias "f" "fd" -Force -Option AllScope
}

if (Get-Command dust -ErrorAction SilentlyContinue) {
	Set-Alias "d" "dust" -Force -Option AllScope
}

if (Get-Command procs -ErrorAction SilentlyContinue) {
	Set-Alias "p" "procs" -Force -Option AllScope
}

if (Get-Command btm -ErrorAction SilentlyContinue) {
	Set-Alias "t" "btm" -Force -Option AllScope
}

if (-not (Get-Command delta -ErrorAction SilentlyContinue) -and (Get-Command git-delta -ErrorAction SilentlyContinue)) {
	Set-Alias "delta" "git-delta" -Force -Option AllScope
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	Invoke-Expression (& zoxide init powershell | Out-String)
}

### ================================
### GOOGLE ANTIGRAVITY CLI ALIASES
### ================================

Set-Alias "a" "agy" -Force -Option AllScope

function agy-continue { agy -c @args }
function agyc { agy -c @args }
function agyr { agy -c @args }
function agy-return { agy -c @args }

function agy-auto { agy --dangerously-skip-permissions @args }
function agy-danger { agy --dangerously-skip-permissions @args }
function agya { agy --dangerously-skip-permissions @args }
function agyd { agy --dangerously-skip-permissions @args }
function aa { agy --dangerously-skip-permissions @args }
function ad { agy --dangerously-skip-permissions @args }

function agy-continue-auto { agy -c --dangerously-skip-permissions @args }
function agy-continue-danger { agy -c --dangerously-skip-permissions @args }
function agyca { agy -c --dangerously-skip-permissions @args }
function agycd { agy -c --dangerously-skip-permissions @args }
function agyra { agy -c --dangerously-skip-permissions @args }
function agyrd { agy -c --dangerously-skip-permissions @args }
function agy-return-auto { agy -c --dangerously-skip-permissions @args }
function agy-return-danger { agy -c --dangerously-skip-permissions @args }
