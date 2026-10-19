# ----------------------------------------------------------------
# Module: NuShell Interactive Configuration
# ----------------------------------------------------------------

### ================================
### SHELL ENVIRONMENT
### ================================

$env.config.buffer_editor = "notepad++";
$env.config.show_banner = false;

let _msys_root = ($env.MSYS2_ROOT? | default "C:\\msys64")
let _msys_home_base = ($env.MSYS2_HOME? | default ([$_msys_root, "home"] | path join))
let _msys_user = ($env.MSYS2_USER? | default ($env.USERNAME? | default ""))

let _msys_target = ([$_msys_home_base, $_msys_user] | path join)
let _msys_target_lower = ([$_msys_home_base, ($_msys_user | str lowercase)] | path join)

let MsysHome = if ($_msys_target | path exists) {
	$_msys_target
} else if ($_msys_target_lower | path exists) {
	$_msys_target_lower
} else {
	""
}

def get-msys-shell [] {
	let roots = [
		($env.MSYS2_ROOT? | default ""),
		"C:\\msys64",
		"D:\\msys64",
		"E:\\msys64",
		([($env.LOCALAPPDATA? | default ""), "Programs", "msys64"] | path join),
		"C:\\Program Files\\Git"
	]
	let candidate_shells = ["zsh.exe", "bash.exe", "sh.exe", "ksh.exe"]
	for sh_name in $candidate_shells {
		for r in $roots {
			if ($r | is-not-empty) {
				let bin1 = ([$r, "usr", "bin", $sh_name] | path join)
				if ($bin1 | path exists) { return $bin1 }
				let bin2 = ([$r, "bin", $sh_name] | path join)
				if ($bin2 | path exists) { return $bin2 }
			}
		}
	}
	for sh_name in ["zsh", "bash", "sh", "ksh"] {
		let detected = (which -a $sh_name | where { |it| not ($it.path | str lowercase | str contains "system32") } | get -o 0)
		if ($detected | is-not-empty) {
			return $detected.path
		}
	}
	null
}

def get-git-cmd [] {
	let candidates = [
		"C:\\Program Files\\Git\\cmd\\git.exe",
		"C:\\Program Files\\Git\\bin\\git.exe",
		"C:\\Program Files (x86)\\Git\\cmd\\git.exe",
		(if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "Programs", "Git", "cmd", "git.exe"] | path join } else { "" }),
		(if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "Programs", "Git", "bin", "git.exe"] | path join } else { "" }),
		([$env.USERPROFILE, "scoop", "shims", "git.exe"] | path join)
	]
	for c in $candidates {
		if ($c | is-not-empty) and ($c | path exists) { return $c }
	}
	let detected = (which -a git | where { |it| not ($it.path | str contains "msys64") } | get -o 0.path | default "git")
	$detected
}

def get-gh-cmd [] {
	let candidates = [
		"C:\\Program Files\\GitHub CLI\\gh.exe",
		"C:\\Program Files (x86)\\GitHub CLI\\gh.exe",
		(if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "Programs", "GitHub CLI", "gh.exe"] | path join } else { "" }),
		([$env.USERPROFILE, "scoop", "shims", "gh.exe"] | path join)
	]
	for c in $candidates {
		if ($c | is-not-empty) and ($c | path exists) { return $c }
	}
	let detected = (which -a gh | where { |it| not ($it.path | str contains "msys64") } | get -o 0.path | default "")
	$detected
}

let _vault_candidates = [
	($env.VAULT_DIR? | default ""),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".local" "share" "vault"),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".config" "vault"),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".vault"),
	(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "vault"] | path join } else { "" }),
	(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "vault"] | path join } else { "" }),
	(if ($MsysHome | is-not-empty) { [$MsysHome, ".vault"] | path join } else { "" })
]
let _active_vault = ($_vault_candidates | where { |p| ($p | is-not-empty) and ($p | path exists) } | get -o 0)

if ($_active_vault | is-not-empty) {
	let _pattern = ($"($_active_vault)/**/*.env" | str replace -a '\' '/')
	for f in (glob $_pattern) {
		let base_name = ($f | path basename)
		if ($base_name | str contains "template") or ($base_name | str contains "example") {
			continue
		}
		let is_locked = (try { (open --raw $f | bytes at 0..10 | decode | str contains "GITCRYPT") } catch { false })
		if $is_locked {
			continue
		}
		let raw_lines = (open $f | lines | where { |it|
			let trimmed = ($it | str trim)
			($trimmed | is-not-empty) and (not ($trimmed | str starts-with '#')) and ($trimmed | str contains '=')
		})
		for line in $raw_lines {
			let parts = ($line | split row -n 2 '=')
			let key = ($parts | get 0 | str trim)
			mut val = ($parts | get 1 | str trim | str replace -r '^"(.*)"$' '$1' | str replace -r "^'(.*)'$" '$1')
			$val = ($val | str replace -r '\$\{VAULT_DIR:-[^\}]+\}' $_active_vault)
			$val = ($val | str replace -a '${VAULT_DIR}' $_active_vault | str replace -a '$VAULT_DIR' $_active_vault)
			$val = ($val | str replace -a '${HOME}' ($env.USERPROFILE? | default ($env.HOME? | default "~")) | str replace -a '$HOME' ($env.USERPROFILE? | default ($env.HOME? | default "~")))
			load-env { $key: $val }
		}
	}
}

### ================================
### SHELL VARIABLES
### ================================

let Home = $"($env.USERPROFILE)";
let System32 = "C:\\Windows\\System32";
let OneDrive = $"($Home)\\onedrive";
let Desktop = $"($OneDrive)\\Área de Trabalho";
let Documents = $"($OneDrive)\\Documentos";
let Images = $"($OneDrive)\\Imagens";
let Workspace = $"($OneDrive)\\Workspace";
let Downloads = $"($Home)\\Downloads";
let VIRTUAL_STORE = $"($env.LOCALAPPDATA)\\VirtualStore";
let FASM_STORE = $"($VIRTUAL_STORE)\\Program Files\\FASM";
let FASM2_STORE = $"($VIRTUAL_STORE)\\Program Files\\FASM2";
let FASMG_STORE = $"($VIRTUAL_STORE)\\Program Files\\FASMG";
let FASMARM_STORE = $"($VIRTUAL_STORE)\\Program Files\\FASMARM";

### ================================
### WINDOWS FUNCTIONS
### ================================

def win-man [term: string] {
	start $"https://learn.microsoft.com/en-us/search/?terms=($term)";
};

### ================================
### UNIX FUNCTIONS
### ================================

def unix-man [section: string, command: string] {
	mut number = $section;
	if (not ('0123456789' | str contains ($section | str substring (-1..)))) {
		$number = $section | str substring (..-2);
	}
	wsl w3m $"https://www.man7.org/linux/man-pages/man($number)/($command).($section).html";
};

### ================================
### SSH KEY RESOLUTION
### ================================

def resolve-vault-ssh-key [explicit_key: string, key_name: string] {
	if ($explicit_key | is-not-empty) and ($explicit_key | path exists) {
		return $explicit_key
	}
	let user_home = ($env.USERPROFILE? | default ($env.HOME? | default "~"))
	let candidates = [
		(if ($env.VAULT_DIR? | is-not-empty) { [$env.VAULT_DIR, "keys", $key_name] | path join } else { "" }),
		([$user_home, ".local", "share", "vault", "keys", $key_name] | path join),
		([$user_home, ".config", "vault", "keys", $key_name] | path join),
		([$user_home, ".vault", "keys", $key_name] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "vault", "keys", $key_name] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "vault", "keys", $key_name] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".vault", "keys", $key_name] | path join } else { "" })
	]
	$candidates | where { |p| ($p | is-not-empty) and ($p | path exists) } | get -o 0
}

### ================================
### SHELL ALIASES
### ================================

alias wh = which;
alias show = start .;
alias brw = lynx -use_mouse=on -nobrowse=on -nopause=on -show_cursor=off;
alias man = wsl man;
alias wman = win-man;
alias uman = unix-man;
alias mandoc = unix-man;
alias Goto-Home = cd $"($Home)";
alias Goto-OneDrive = cd $"($OneDrive)";
alias Goto-Desktop = cd $"($Desktop)";
alias Goto-Documents = cd $"($Documents)";
alias Goto-Workspace = cd $"($Workspace)";
alias Goto-Images = cd $"($Images)";
alias Goto-Downloads = cd $"($Downloads)";
alias Goto-Virtual-Store = cd $"($VIRTUAL_STORE)";
alias Goto-FASM-Store = cd $"($FASM_STORE)";
alias Goto-Machine = cd $"($System32)";
alias Goto-Msys = cd (if ($MsysHome | is-not-empty) { $MsysHome } else { "C:\\msys64" });
alias Show-Explorer = explorer.exe .;
alias Show-Home = explorer.exe $"($Home)";
alias Show-OneDrive = explorer.exe $"($OneDrive)";
alias Show-Desktop = explorer.exe $"($Desktop)";
alias Show-Documents = explorer.exe $"($Documents)";
alias Show-Workspace = explorer.exe $"($Workspace)";
alias Show-Images = explorer.exe $"($Images)";
alias Show-Downloads = explorer.exe $"($Downloads)";
alias Show-Virtual-Store = explorer.exe $"($VIRTUAL_STORE)";
alias Show-FASM-Store = explorer.exe $"($FASM_STORE)";
alias Show-Machine = explorer.exe $"($System32)";
alias Show-Msys = explorer.exe (if ($MsysHome | is-not-empty) { $MsysHome } else { "C:\\msys64" });

def --wrapped personal-server [...rest] {
	let ip = ($env.PERSONAL_SERVER_IP? | default "144.22.210.65")
	let user = ($env.PERSONAL_SERVER_USER? | default "ubuntu")
	let key = (resolve-vault-ssh-key ($env.PERSONAL_SERVER_KEY? | default "") "ssh-key-personal-server.key")
	if ($key | is-not-empty) {
		$env.PERSONAL_SERVER_KEY = $key
		ssh -i $key $"($user)@($ip)" ...$rest
	} else {
		ssh $"($user)@($ip)" ...$rest
	}
}

def --wrapped venture-server [...rest] {
	let ip = ($env.VENTURE_SERVER_IP? | default "137.131.238.161")
	let user = ($env.VENTURE_SERVER_USER? | default "ubuntu")
	let key = (resolve-vault-ssh-key ($env.VENTURE_SERVER_KEY? | default "") "ssh-key-venture-server.key")
	if ($key | is-not-empty) {
		$env.VENTURE_SERVER_KEY = $key
		ssh -i $key $"($user)@($ip)" ...$rest
	} else {
		ssh $"($user)@($ip)" ...$rest
	}
}

alias ek = taskkill /IM emacs.exe /F;
alias es = runemacs --fg-daemon;
alias ec = emacsclientw --create-frame --alternate-editor "";
alias oe = emacsclientw --create-frame --alternate-editor "" .;
alias ov = vim .;
alias on = nvim .;
alias oc = code .;
alias ocm = codium .;
alias oz = zed .;
alias oa = antigravity-ide .;
alias ant = antigravity-ide;

### ================================
### GOOGLE ANTIGRAVITY CLI ALIASES
### ================================

alias agy-continue = agy -c;
alias agyc = agy -c;

alias agy-auto = agy --dangerously-skip-permissions;
alias agy-danger = agy --dangerously-skip-permissions;
alias agya = agy --dangerously-skip-permissions;
alias agyd = agy --dangerously-skip-permissions;

alias agy-continue-auto = agy -c --dangerously-skip-permissions;
alias agy-continue-danger = agy -c --dangerously-skip-permissions;
alias agyca = agy -c --dangerously-skip-permissions;
alias agycd = agy -c --dangerously-skip-permissions;

### ================================
### EMISSAO E UI SEMANTICA
### ================================

# ----------------------------------------------------------------
# Utility: Universal Shell UI & Emission Helper (Nushell)
# ----------------------------------------------------------------

def _ui_step [msg: string] { print $"(ansi cyan_bold)==>(ansi reset) ($msg)" }
def _ui_sub  [msg: string] { print $"(ansi blue_bold)  ↳(ansi reset) ($msg)" }
def _ui_ok   [msg: string] { print $"(ansi green_bold)  ✅(ansi reset) ($msg)" }
def _ui_warn [msg: string] { print $"(ansi yellow_bold)  ⚠️ (ansi reset) ($msg)" }
def _ui_err  [msg: string] { print -e $"(ansi red_bold)  ❌(ansi reset) ($msg)" }
def _ui_info [msg: string] { print $"(ansi magenta_bold)  ℹ️ (ansi reset) ($msg)" }

def _ui_banner [title: string] {
	let sep = "================================================================"
	print ""
	print $"(ansi cyan_bold)($sep)(ansi reset)"
	print $"(ansi white_bold)  ($title)(ansi reset)"
	print $"(ansi cyan_bold)($sep)(ansi reset)"
	print ""
}

### ================================
### SHELL FUNCTIONS
### ================================

def upget [] {
	if (which winget | is-empty) {
		_ui_info "Winget não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Winget..."
	winget upgrade --all
	_ui_ok "Winget atualizado com sucesso!"
}

def upscp [] {
	if (which scoop | is-empty) {
		_ui_info "Scoop não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Scoop..."
	scoop update
	scoop update --all
	_ui_ok "Scoop atualizado com sucesso!"
}

def upcho [] {
	if (which choco | is-empty) {
		_ui_info "Chocolatey não encontrado no sistema."
		return
	}
	_ui_step "Atualizando pacotes via Chocolatey..."
	let pw = if (which pwsh | is-not-empty) { "pwsh" } else { "powershell" }
	^$pw -NoProfile -Command "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs -Wait"
	_ui_ok "Chocolatey atualizado com sucesso!"
}

def upwin [] {
	_ui_step "Executando Windows Update com reinicialização automática se necessário..."
	let pw = if (which pwsh | is-not-empty) { "pwsh" } else { "powershell" }
	^$pw -NoProfile -Command "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
	_ui_ok "Windows Update finalizado!"
}

def upsys [] {
	_ui_step "Atualizando gerenciadores de pacotes do sistema..."
	mut found = false
	if (which winget | is-not-empty) {
		$found = true
		upget
	}
	if (which scoop | is-not-empty) {
		$found = true
		upscp
	}
	if (which choco | is-not-empty) {
		$found = true
		upcho
	}
	if not $found {
		_ui_warn "Nenhum gerenciador de pacotes suportado (winget, scoop, choco) encontrado no sistema."
		return
	}
	_ui_ok "Atualização de pacotes do sistema concluída!"
}

def clean-system [...args: string] {
	let sub_args = ($args | str join " ")
	if ($sub_args | str contains "--help") or ($sub_args | str contains "-h") {
		print "Uso: clean-system [opções] (alias: cleansys, sysclean, syscls, clear-system, clearsys)"
		print ""
		print "Limpeza de pacotes órfãos e caches no Windows."
		return
	}
	_ui_step "Executando limpeza de pacotes e caches do sistema..."
	if (which scoop | is-not-empty) {
		_ui_sub "Limpando cache do Scoop..."
		do -i { scoop cache rm * }
		do -i { scoop cleanup * }
	}
	if (which choco | is-not-empty) {
		_ui_sub "Limpando cache do Chocolatey..."
		do -i { ^powershell -NoProfile -Command "Start-Process choco -ArgumentList 'cache remove' -Verb RunAs -Wait" }
	}
	_ui_ok "Limpeza do sistema concluída!"
}

def upgit [
	root?: string      # Diretório raiz para busca (padrão: '.')
	--status (-s)      # Audita status de branches, commits divergentes e alterações
	--dry-run (-n)     # Simula a sincronização sem efetuar git pull
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run
	let target_root = if ($root | is-not-empty) { $root } else { "." }

	let action_title = if ($is_status) { "Auditando status de" } else if ($is_dry) { "Simulando atualização de" } else { "Buscando e atualizando" }
	_ui_step $"($action_title) repositórios Git em: ($target_root)"
	print ""

	let g1 = (try { glob $"($target_root)/.git" } catch { [] })
	let g2 = (try { glob $"($target_root)/*/.git" } catch { [] })
	let g3 = (try { glob $"($target_root)/*/*/.git" } catch { [] })
	let repos = ($g1 | append $g2 | append $g3 | uniq)

	if ($repos | is-empty) {
		_ui_info $"Nenhum repositório Git encontrado em ($target_root) (profundidade máxima: 3)."
		return
	}

	let git_bin = (get-git-cmd)
	for repo in $repos {
		let dir = ($repo | path dirname)
		let branch = (do { ^$git_bin -C $dir branch --show-current } | complete).stdout | str trim
		let branch_lbl = if ($branch | is-empty) { "detached" } else { $branch }

		if ($is_status) {
			let st = (do { ^$git_bin -C $dir status -s } | complete).stdout | str trim
			let unpushed = (do { ^$git_bin -C $dir cherry -v } | complete).stdout | str trim
			if ($st | is-not-empty) or ($unpushed | is-not-empty) {
				_ui_warn $"($dir) [($branch_lbl)]: divergências detectadas"
				if ($unpushed | is-not-empty) { print $"  (ansi yellow_bold)↳ Commits pendentes de push(ansi reset)" }
				if ($st | is-not-empty) { print $"  (ansi dark_gray)($st)(ansi reset)" }
			} else {
				_ui_ok $"($dir) [($branch_lbl)]: sincronizado e limpo"
			}
		} else if ($is_dry) {
			_ui_sub $"[DRY-RUN PULL] ($dir) [($branch_lbl)]"
		} else {
			_ui_sub $"Atualizando ($dir)..."
			let res = (do { ^$git_bin -C $dir pull --ff-only } | complete)
			if $res.exit_code != 0 {
				^$git_bin -C $dir pull
			}
		}
	}
	print ""
	_ui_ok "Operação Git concluída!"
}

def psgit [
	root?: string      # Diretório raiz para busca (padrão: '.')
	--status (-s)      # Audita commits locais pendentes de envio (cherry -v)
	--dry-run (-n)     # Simula o push sem enviar commits
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run
	let target_root = if ($root | is-not-empty) { $root } else { "." }

	let action_title = if ($is_status) { "Auditando commits pendentes em" } else if ($is_dry) { "Simulando push de" } else { "Buscando e enviando" }
	_ui_step $"($action_title) repositórios Git em: ($target_root)"
	print ""

	let g1 = (try { glob $"($root)/.git" } catch { [] })
	let g2 = (try { glob $"($root)/*/.git" } catch { [] })
	let g3 = (try { glob $"($root)/*/*/.git" } catch { [] })
	let repos = ($g3 | append $g2 | append $g1 | uniq)

	if ($repos | is-empty) {
		_ui_info $"Nenhum repositório Git encontrado em ($root) (profundidade máxima: 3)."
		return
	}

	for repo in $repos {
		let dir = ($repo | path dirname)
		let unpushed = (do { ^git -C $dir cherry -v } | complete).stdout | str trim
		let branch = (do { ^git -C $dir branch --show-current } | complete).stdout | str trim
		let branch_lbl = if ($branch | is-empty) { "detached" } else { $branch }

		if ($unpushed | is-not-empty) {
			if ($is_status) {
				_ui_warn $"($dir) [($branch_lbl)]: commits pendentes de envio"
				print $"  (ansi yellow_bold)($unpushed)(ansi reset)"
			} else if ($is_dry) {
				_ui_sub $"[DRY-RUN PUSH] ($dir) [($branch_lbl)]"
			} else {
				_ui_sub $"Enviando ($dir) [($branch_lbl)]..."
				let res = (do { ^git -C $dir push } | complete)
				if $res.exit_code == 0 {
					_ui_ok $"($dir): push concluído com sucesso!"
				} else {
					_ui_err $"($dir): falha no push."
				}
			}
		} else {
			if ($is_status) {
				_ui_ok $"($dir) [($branch_lbl)]: nada a enviar"
			} else {
				_ui_ok $"($dir): já atualizado com o remote."
			}
		}
	}
	print ""
	_ui_ok "Operação Push Git concluída!"
}

def sync-extensions [
	--export           # Exporta lista declarativa de extensões
	--status (-s)      # Audita extensões declaradas no manifesto
	--dry-run (-n)     # Simula a sincronização sem modificar o ambiente
	target_arg?: string # Editor alvo (auto, code, codium, antigravity)
	...args: string
] {
	_ui_step "Sincronizando extensões de IDE declarativas..."
	let candidates = [
		($env.PROFILE_DIR? | default ""),
		([$env.USERPROFILE, ".local", "share", "profile"] | path join),
		([$env.USERPROFILE, ".config", "profile"] | path join),
		([$env.USERPROFILE, ".profile"] | path join),
		([$env.USERPROFILE, "OneDrive", "Documentos", "Profile"] | path join),
		([$env.USERPROFILE, "Documents", "Profile"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "profile"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "profile"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".profile"] | path join } else { "" })
	]
	let target = ($candidates | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)

	if ($target | is-not-empty) {
		let action_arg = if $export { "export" } else if $status { "status" } else { "install" }
		let sub_flags = [
			$action_arg,
			(if $dry_run { "--dry-run" } else { null }),
			(if ($target_arg | is-not-empty) { $target_arg } else { null })
		] | compact
		let sub_args = ($sub_flags | append $args | str join " ")

		let sh = (get-msys-shell)
		if ($sh | is-not-empty) {
			let target_posix = ($target | str replace -a '\' '/' | str replace -r '^[Cc]:' '/c' | str replace -r '^[Dd]:' '/d')
			^$sh -c $"MSYS=winsymlinks:nativestrict '($target_posix)/profile.sh' extensions ($sub_args)"
		} else {
			_ui_warn "Ambiente MSYS2/POSIX shell não detectado no PATH."
		}
	} else {
		_ui_info "Repositório do Profile não encontrado."
	}
}

def uped [
	--status (-s)        # Audita o status Git de cada editor instalado
	--dry-run (-n)       # Simula a sincronização sem puxar alterações
	--extensions (-e)    # Sincroniza também as extensões declarativas de IDE
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run
	let is_ext = $extensions
	let action_title = if ($is_status) { "Auditando status da" } else if ($is_dry) { "Simulando atualização da" } else { "Atualizando a" }
	_ui_step $"($action_title) Suíte de Editores no Windows..."
	mut found = false

	let emacs_paths = [
		([$env.USERPROFILE, ".emacs.d"] | path join),
		(if ($env.APPDATA? | is-not-empty) { [$env.APPDATA, ".emacs.d"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".emacs.d"] | path join } else { "" })
	]
	let emacs_dir = ($emacs_paths | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)
	if ($emacs_dir | is-not-empty) {
		$found = true
		if ($is_status) {
			_ui_sub $"Status de Emacs em ($emacs_dir)..."
			^git -C $emacs_dir status -s -b
		} else if ($is_dry) {
			_ui_sub $"[DRY-RUN] Atualização de Emacs em ($emacs_dir)..."
			_ui_sub $"git -C ($emacs_dir) pull --ff-only"
		} else {
			_ui_sub $"Atualizando Emacs em ($emacs_dir)..."
			if ([$emacs_dir, "usr", "local"] | path join | path exists) {
				do -i { ^git -C $emacs_dir clean -fd "usr/local" }
			}
			^git -C $emacs_dir pull --ff-only
			if ([$emacs_dir, ".gitmodules"] | path join | path exists) {
				_ui_sub "Sincronizando submódulos Elisp..."
				^git -C $emacs_dir submodule update --init --recursive --remote --merge
			}
			_ui_ok "Emacs atualizado com sucesso!"
		}
	}

	let helix_paths = [
		(if ($env.APPDATA? | is-not-empty) { [$env.APPDATA, "helix"] | path join } else { "" }),
		([$env.USERPROFILE, ".config", "helix"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "helix"] | path join } else { "" })
	]
	let helix_dir = ($helix_paths | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)
	if ($helix_dir | is-not-empty) {
		$found = true
		if ($is_status) {
			_ui_sub $"Status de Helix em ($helix_dir)..."
			^git -C $helix_dir status -s -b
		} else if ($is_dry) {
			_ui_sub $"[DRY-RUN] Atualização de Helix em ($helix_dir)..."
			_ui_sub $"git -C ($helix_dir) pull --ff-only"
		} else {
			_ui_sub $"Atualizando Helix em ($helix_dir)..."
			^git -C $helix_dir pull --ff-only
			_ui_ok "Helix atualizado com sucesso!"
		}
	}

	let nvim_paths = [
		(if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "nvim"] | path join } else { "" }),
		([$env.USERPROFILE, ".config", "nvim"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "nvim"] | path join } else { "" })
	]
	let nvim_dir = ($nvim_paths | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)
	if ($nvim_dir | is-not-empty) {
		$found = true
		if ($is_status) {
			_ui_sub $"Status de NeoVim em ($nvim_dir)..."
			^git -C $nvim_dir status -s -b
		} else if ($is_dry) {
			_ui_sub $"[DRY-RUN] Atualização de NeoVim em ($nvim_dir)..."
			_ui_sub $"git -C ($nvim_dir) pull --ff-only"
		} else {
			_ui_sub $"Atualizando NeoVim em ($nvim_dir)..."
			^git -C $nvim_dir pull --ff-only
			_ui_ok "NeoVim atualizado com sucesso!"
		}
	}

	let vim_paths = [
		([$env.USERPROFILE, "vimfiles"] | path join),
		([$env.USERPROFILE, ".vim"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".vim"] | path join } else { "" })
	]
	let vim_dir = ($vim_paths | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)
	if ($vim_dir | is-not-empty) {
		$found = true
		if ($is_status) {
			_ui_sub $"Status de Vim em ($vim_dir)..."
			^git -C $vim_dir status -s -b
		} else if ($is_dry) {
			_ui_sub $"[DRY-RUN] Atualização de Vim em ($vim_dir)..."
			_ui_sub $"git -C ($vim_dir) pull --ff-only"
		} else {
			_ui_sub $"Atualizando Vim em ($vim_dir)..."
			^git -C $vim_dir pull --ff-only
			_ui_ok "Vim atualizado com sucesso!"
		}
	}

	if (not $found) {
		_ui_info "Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, helix, nvim, vimfiles)."
	} else {
		_ui_ok "Suíte de Editores sincronizada com sucesso!"
	}

	if ($is_ext) {
		sync-extensions ...$args
	}
}

def uprc [
	--status (-s)        # Audita o status do Profile e compara divergências
	--dry-run (-n)       # Simula a sincronização sem alterar arquivos
	--backup (-b)        # Cria backup (.bak) antes de substituir arquivos
	--extensions (-e)    # Sincroniza extensões declarativas de IDE
	--pull               # Reconcilia alterações do sistema de volta ao Git
	...args: string
] {
	let is_query = $status
	let is_dry = $dry_run
	let is_backup = $backup
	let is_ext = $extensions
	let is_pull = $pull

	let candidates = [
		($env.PROFILE_DIR? | default ""),
		([$env.USERPROFILE, ".local", "share", "profile"] | path join),
		([$env.USERPROFILE, ".config", "profile"] | path join),
		([$env.USERPROFILE, ".profile"] | path join),
		([$env.USERPROFILE, "OneDrive", "Documentos", "Profile"] | path join),
		([$env.USERPROFILE, "Documents", "Profile"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "profile"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "profile"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".profile"] | path join } else { "" })
	]
	let target = ($candidates | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)

	if ($target | is-not-empty) {
		if (not $is_query) and (not $is_pull) and (not $is_dry) {
			_ui_step $"Atualizando Universal Profile em: ($target)..."
			let git_bin = (get-git-cmd)
			let dirty = (^$git_bin -C $target status --porcelain | str trim)
			if ($dirty | is-not-empty) {
				_ui_warn $"Alterações locais não commitadas detectadas em: ($target). Ignorando git pull para preservar dados."
			} else {
				^$git_bin -C $target pull --ff-only
			}
		}
		let sh_sync = ([$target, "profile.sh"] | path join)
		if ($sh_sync | path exists) {
			_ui_sub "Sincronizando dotfiles via profile.sh (MSYS2 / POSIX)..."
			let sh = (get-msys-shell)
			if ($sh | is-not-empty) {
				let sync_flags = [
					(if $is_query { "--status" } else { null }),
					(if $is_dry { "--dry-run" } else { null }),
					(if $is_backup { "--backup" } else { null }),
					(if $is_ext { "--extensions" } else { null }),
					(if $is_pull { "--pull" } else { null })
				] | compact
				let sub_args = ($sync_flags | append $args | str join " ")

				let target_posix = ($target | str replace -a '\' '/' | str replace -r '^[Cc]:' '/c' | str replace -r '^[Dd]:' '/d')
				^$sh -c $"MSYS=winsymlinks:nativestrict '($target_posix)/profile.sh' sync ($sub_args)"
			} else {
				_ui_warn "Ambiente MSYS2/POSIX shell não detectado no PATH (excluído WSL em System32)."
			}
		}
		_ui_ok "Universal Profile atualizado e sincronizado com sucesso!"
	} else {
		_ui_info "Repositório do Profile não encontrado."
	}
}

def vault-perms [path?: string] {
	let user = ($env.USERNAME? | default ($env.USER? | default "user"))
	let home = ($env.USERPROFILE? | default ($env.HOME? | default "~"))
	let target = if ($path | is-not-empty) { $path } else {
		let candidates = [
			($env.VAULT_DIR? | default ""),
			$"($home)/.local/share/vault",
			$"($home)/.config/vault",
			$"($home)/.vault",
			(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "vault"] | path join } else { "" }),
			(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "vault"] | path join } else { "" }),
			(if ($MsysHome | is-not-empty) { [$MsysHome, ".vault"] | path join } else { "" })
		]
		$candidates | where { |p| ($p | is-not-empty) and ($p | path exists) } | get -o 0
	}
	if ($target == null or not ($target | path exists)) {
		_ui_err $"Diretório do Vault não encontrado: ($target)"
		return
	}
	_ui_step $"Ajustando permissões de segurança em ($target)..."
	let win_target = ($target | path expand | str replace -a '/' '\')
	^icacls $win_target /inheritance:r /grant:r $"($user):\(OI\)\(CI\)F" /c /q
	^icacls $"($win_target)\\*" /reset /t /c /q
	if ([$win_target, ".git"] | path join | path exists) {
		^git -C $win_target config core.hooksPath .githooks
	}
	_ui_ok $"Permissões ajustadas com sucesso [acesso restrito a '($user)']."
}

def upvt [
	--status (-s)      # Audita o status do repositório do cofre
	--dry-run (-n)     # Simula o pull sem aplicar alterações
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run

	let candidates = [
		($env.VAULT_DIR? | default ""),
		([$env.USERPROFILE, ".local", "share", "vault"] | path join),
		([$env.USERPROFILE, ".config", "vault"] | path join),
		([$env.USERPROFILE, ".vault"] | path join),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "vault"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "vault"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".vault"] | path join } else { "" })
	]
	let target = ($candidates | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)

	if ($target | is-not-empty) {
		let git_bin = (get-git-cmd)
		let gh_bin = (get-gh-cmd)
		if ($is_status) {
			_ui_step $"Status do Universal Vault em: ($target)..."
			^$git_bin -C $target status -s -b
			return
		}
		if ($is_dry) {
			_ui_step $"[DRY-RUN] Atualização do Universal Vault em: ($target)..."
			_ui_sub $"git -C ($target) pull --ff-only"
			return
		}
		_ui_step $"Atualizando Universal Vault em: ($target)..."

		# 1. Tentativa primária: pull direto com Git for Windows
		let pull_res = (do { ^$git_bin -C $target pull --ff-only } | complete)
		if $pull_res.exit_code == 0 {
			if ($pull_res.stdout | str trim | is-not-empty) { print ($pull_res.stdout | str trim) }
			vault-perms $target
			_ui_ok "Universal Vault atualizado com sucesso!"
			return
		}

		# 2. Fallback antifrágil: injeção de token via http.extraheader com GitHub CLI (Bearer)
		let token = if ($gh_bin | is-not-empty) {
			(do -i { ^$gh_bin auth token } | complete | get stdout | str trim)
		} else {
			(do -i { ^gh auth token } | complete | get stdout | str trim)
		}

		if ($token | is-not-empty) {
			let header_arg = $"http.https://github.com/.extraheader=AUTHORIZATION: bearer ($token)"
			let token_res = (do { ^$git_bin -C $target -c $header_arg pull --ff-only } | complete)
			if $token_res.exit_code == 0 {
				if ($token_res.stdout | str trim | is-not-empty) { print ($token_res.stdout | str trim) }
				vault-perms $target
				_ui_ok "Universal Vault atualizado com sucesso via GitHub CLI Token!"
				return
			}
		}

		# 3. Fallback: helper explícito com barras normais (POSIX)
		if ($gh_bin | is-not-empty) {
			let gh_posix = ($gh_bin | str replace -a '\' '/')
			let helper_arg = $"credential.https://github.com.helper=!\"($gh_posix)\" auth git-credential"
			let helper_res = (do { ^$git_bin -C $target -c $helper_arg pull --ff-only } | complete)
			if $helper_res.exit_code == 0 {
				if ($helper_res.stdout | str trim | is-not-empty) { print ($helper_res.stdout | str trim) }
				vault-perms $target
				_ui_ok "Universal Vault atualizado com sucesso!"
				return
			}
		}

		if ($pull_res.stderr | str trim | is-not-empty) { print ($pull_res.stderr | str trim) }
		_ui_err $"Falha ao atualizar o Universal Vault em: ($target)"
	} else {
		_ui_info "Repositório do Vault não encontrado."
	}
}

def upsh [
	--status (-s)      # Audita o status do repositório Git local sem puxar
	--dry-run (-n)     # Simula a sincronização sem efetuar pull
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run

	let candidates = [
		($env.SHELL_REPO_DIR? | default ""),
		([$env.USERPROFILE, ".local", "share", "shell"] | path join),
		([$env.USERPROFILE, ".config", "shell"] | path join),
		([$env.USERPROFILE, ".shell"] | path join),
		"C:\\Program Files\\Shell",
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".local", "share", "shell"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".config", "shell"] | path join } else { "" }),
		(if ($MsysHome | is-not-empty) { [$MsysHome, ".shell"] | path join } else { "" })
	]
	let target = ($candidates | where { |p| ($p | is-not-empty) and ([$p, ".git"] | path join | path exists) } | get -o 0)

	if ($target | is-not-empty) {
		let git_bin = (get-git-cmd)
		if ($is_status) {
			_ui_step $"Status do Universal Shell em: ($target)..."
			^$git_bin -C $target status -s -b
			return
		}
		if ($is_dry) {
			_ui_step $"[DRY-RUN] Atualização do Universal Shell em: ($target)..."
			_ui_sub $"git -C ($target) pull --ff-only"
			return
		}
		_ui_step $"Atualizando Universal Shell em: ($target)..."
		^$git_bin -C $target pull --ff-only
		let nu_dir = ([$target, "target", "windows", "nushell"] | path join)
		if ($nu_dir | path exists) and ($env.APPDATA? | is-not-empty) {
			let app_nu = ([$env.APPDATA, "nushell"] | path join)
			if ($app_nu | path exists) {
				mut nu_synced = false
				for f in ["config.nu", "env.nu"] {
					let src = ([$nu_dir, $f] | path join)
					let dst = ([$app_nu, $f] | path join)
					if ($src | path exists) {
						let is_same = if ($dst | path exists) {
							try { ($dst | path expand) == ($src | path expand) } catch { false }
						} else {
							false
						}
						if not $is_same {
							do -i { cp -f $src $dst }
							$nu_synced = true
						}
					}
				}
				if $nu_synced {
					_ui_sub $"Sincronizados perfis físicos NuShell em: ($app_nu)"
				}
			}
		}
		let pwsh_dir = ([$target, "target", "windows", "powershell"] | path join)
		let docs_cands = [
			([$env.USERPROFILE, "OneDrive", "Documentos", "PowerShell"] | path join),
			([$env.USERPROFILE, "OneDrive", "Documents", "PowerShell"] | path join),
			([$env.USERPROFILE, "Documentos", "PowerShell"] | path join),
			([$env.USERPROFILE, "Documents", "PowerShell"] | path join)
		]
		for d in $docs_cands {
			if ($d | path exists) and ($pwsh_dir | path exists) {
				mut pwsh_synced = false
				for f in ["profile.ps1", "Microsoft.PowerShell_profile.ps1"] {
					let src = ([$pwsh_dir, $f] | path join)
					let dst = ([$d, $f] | path join)
					if ($src | path exists) {
						let is_same = if ($dst | path exists) {
							try { ($dst | path expand) == ($src | path expand) } catch { false }
						} else {
							false
						}
						if not $is_same {
							do -i { cp -f $src $dst }
							$pwsh_synced = true
						}
					}
				}
				if $pwsh_synced {
					_ui_sub $"Sincronizados perfis físicos PowerShell em: ($d)"
				}
				break
			}
		}
		let cmd_dir = ([$target, "target", "windows", "cmd"] | path join)
		if ($cmd_dir | path exists) and ($env.LOCALAPPDATA? | is-not-empty) {
			let app_clink = ([$env.LOCALAPPDATA, "clink"] | path join)
			if ($app_clink | path exists) {
				mut clink_synced = false
				for f in ["profile.lua", "profile.cmd"] {
					let src = ([$cmd_dir, $f] | path join)
					let dst = ([$app_clink, $f] | path join)
					if ($src | path exists) {
						let is_same = if ($dst | path exists) {
							try { ($dst | path expand) == ($src | path expand) } catch { false }
						} else {
							false
						}
						if not $is_same {
							do -i { cp -f $src $dst }
							$clink_synced = true
						}
					}
				}
				if $clink_synced {
					_ui_sub $"Sincronizados perfis físicos Clink em: ($app_clink)"
				}
			}
		}
		_ui_ok "Universal Shell atualizado com sucesso!"
	} else {
		_ui_info "Repositório do Shell não encontrado."
	}
}

def upall [
	--status (-s)      # Executa auditoria e diagnóstico geral sem atualizar
	--dry-run (-n)     # Simula a atualização de todos os componentes
	...args: string
] {
	let is_status = $status
	let is_dry = $dry_run

	if ($is_status) {
		_ui_banner "Status Global do Ecossistema"
		uprc --status
		upvt --status
		upsh --status
		uped --status
		_ui_banner "Verificação de Status Concluída"
		return
	}
	if ($is_dry) {
		_ui_banner "Simulação Global do Ecossistema (Dry-Run)"
		uprc --dry-run
		upvt --dry-run
		upsh --dry-run
		uped --dry-run
		_ui_banner "Simulação Concluída"
		return
	}
	_ui_banner "Atualização Global do Ecossistema e Sistema"
	upsys
	uprc
	upvt
	upsh
	uped
	clean-system
	_ui_banner "Atualização Global Concluída com Sucesso"
}

alias upprofile = uprc;
alias sync-profile = uprc;
alias update-extensions = sync-extensions;
alias upext = sync-extensions;
alias update-git = upgit;
alias plgit = upgit;
alias pull-git = upgit;
alias push-git = psgit;
alias update-editors = uped;
alias update-profile = uprc;
alias update-vault = upvt;
alias update-shell = upsh;
alias update-system = upsys;
alias update-all = upall;
alias cleansys = clean-system;
alias clearsys = clean-system;
alias sysclean = clean-system;
alias syscls = clean-system;
alias clear-system = clean-system;
def er [] { ek; es };
def oa [...args: string] {
	let app = "antigravity-ide"
	let target = if ($args | is-empty) { "." } else { $args | str join " " }
	^pwsh -NoProfile -Command $"Start-Process -FilePath '($app)' -ArgumentList '($target)' -WindowStyle Hidden"
}
def ant [...args: string] {
	let app = "antigravity-ide"
	if ($args | is-empty) {
		^pwsh -NoProfile -Command $"Start-Process -FilePath '($app)' -WindowStyle Hidden"
	} else {
		let args_str = ($args | str join " ")
		^pwsh -NoProfile -Command $"Start-Process -FilePath '($app)' -ArgumentList '($args_str)' -WindowStyle Hidden"
	}
}

### ================================
### SHELL CONFIGURATION
### ================================
