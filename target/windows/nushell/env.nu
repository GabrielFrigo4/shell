# ----------------------------------------------------------------
# Module: NuShell Environment Setup
# ----------------------------------------------------------------

$env.ENV_CONVERSIONS = {
	"PATH": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
	"Path": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
}

$env.HOME = ($env.USERPROFILE? | default ($env.HOME? | default "~"))

let _raw_path = ($env.Path? | default ($env.PATH? | default []))
let _initial_path = if ($_raw_path | describe | str starts-with "list") {
	$_raw_path
} else {
	($_raw_path | split row (char esep))
}

let _cleaned_path = (
	$_initial_path
	| each { |p| $p | str trim | str trim -c '"' }
	| prepend ($env.HOME | path join .local bin)
	| prepend ($env.HOME | path join .cargo bin)
	| prepend ($env.HOME | path join .platformio penv bin)
	| prepend ($env.HOME | path join "scoop" "shims")
	| prepend "C:\\Program Files\\GitHub CLI"
	| prepend "C:\\Program Files\\Git\\cmd"
	| prepend "C:\\Program Files (x86)\\Git\\cmd"
	| prepend (if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "Programs", "Git", "cmd"] | path join } else { "" })
	| prepend (if ($env.LOCALAPPDATA? | is-not-empty) { [$env.LOCALAPPDATA, "Programs", "GitHub CLI"] | path join } else { "" })
	| where { |p| ($p | is-not-empty) and ($p | path exists) }
	| uniq
)

$env.Path = $_cleaned_path
$env.PATH = $_cleaned_path

$env.EMACS_SOCKET_NAME = ($env.HOME | path join ".emacs.d" "var" "server" "auth" "server");
$env.MICRO_TRUECOLOR = 1;

let _msys_root = ($env.MSYS2_ROOT? | default "C:\\msys64")
let _msys_home_base = ($env.MSYS2_HOME? | default ([$_msys_root, "home"] | path join))
let _msys_user = ($env.MSYS2_USER? | default ($env.USERNAME? | default ""))
let _msys_home = ([$_msys_home_base, $_msys_user] | path join)
let _msys_home_lower = ([$_msys_home_base, ($_msys_user | str lowercase)] | path join)
let _resolved_msys = if ($_msys_home | path exists) { $_msys_home } else if ($_msys_home_lower | path exists) { $_msys_home_lower } else { "" }

let _shell_candidates = [
	($env.SHELL_REPO_DIR? | default ""),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".local" "share" "shell"),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".config" "shell"),
	(($env.USERPROFILE? | default ($env.HOME? | default "~")) | path join ".shell"),
	(if ($_resolved_msys | is-not-empty) { [$_resolved_msys, ".local", "share", "shell"] | path join } else { "" }),
	(if ($_resolved_msys | is-not-empty) { [$_resolved_msys, ".config", "shell"] | path join } else { "" }),
	"C:\\Program Files\\Shell"
]
let _active_shell = ($_shell_candidates | where { |p| ($p | is-not-empty) and ([$p, "shell.sh"] | path join | path exists) } | get -o 0)
if ($_active_shell | is-not-empty) and not ($env.SHELL_REPO_DIR? | default "" | is-not-empty) {
	$env.SHELL_REPO_DIR = $_active_shell
}

### ================================
### PROMPT THEME
### ================================

let _win_build = (try {
	let v = (do -i { ^cmd.exe /c ver } | complete | get stdout)
	($v | parse -r "10\\.0\\.(?<bld>\\d+)" | get -o 0.bld | default "0" | into int)
} catch { 0 })
let _win_dv = (try {
	let r = (do -i { ^reg.exe query "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" /v DisplayVersion } | complete | get stdout)
	($r | parse -r "DisplayVersion\\s+REG_SZ\\s+(?<dv>\\S+)" | get -o 0.dv | default "")
} catch { "" })
let _win_name = (if $_win_build >= 22000 {
	if ($_win_dv | is-not-empty) { $"11 ($_win_dv)" } else { "11" }
} else if $_win_build >= 10240 {
	if ($_win_dv | is-not-empty) { $"10 ($_win_dv)" } else { "10" }
} else { "NT 10.0" })
let _win_icon = (if $_win_build >= 22000 { "" } else { "" })
$env.PROMPT_OS_NAME = $_win_name
$env.PROMPT_OS_ICON = $_win_icon

def create_left_prompt [] {
	let gray = (ansi -e '90m')
	let blue = (ansi -e '94m')
	let green = (ansi -e '92m')
	let yellow = (ansi -e '93m')
	let magenta = (ansi -e '95m')
	let cyan = (ansi -e '96m')
	let red = (ansi -e '91m')
	let reset = (ansi reset)

	let time = (date now | format date "%H:%M:%S")
	let date = (date now | format date "%d/%m/%y")
	let home_dir = ($env.HOME? | default ($env.USERPROFILE? | default "~"))
	let dir = (if ($env.PWD == $home_dir) { "~" } else { $env.PWD | path basename })
	let user = ($env.USER? | default ($env.USERNAME? | default "user"))

	mut git_info = ""
	let branch = (do -i { git symbolic-ref --short HEAD } | complete)
	if $branch.exit_code == 0 and ($branch.stdout | str trim | is-not-empty) {
		let bname = ($branch.stdout | str trim)
		let dirty_check = (do -i { git status --porcelain=v1 -uno --ignore-submodules=dirty } | complete)
		let indicator = (if ($dirty_check.stdout | str trim | is-not-empty) { $"($yellow)*" } else { "" })
		$git_info = $" ($gray)($red)󰊢 ($magenta)($bname)($indicator)($gray)"
	}

	let os_icon = ($env.PROMPT_OS_ICON? | default "")
	let os_name = ($env.PROMPT_OS_NAME? | default "Win 11")
	let line1 = $"($gray)($blue)($os_icon) ($magenta)($os_name) ($blue) ($magenta)nu($gray)"
	let line2 = $"($gray)┌──($blue) ($green)($time)($gray)─($blue) ($green)($date)($gray)─($yellow) ($cyan)($dir)($gray)─ ($blue) ($green)($user)($gray)($git_info)"
	let line3 = $"($gray)└─($blue)($reset) "

	$"\n($line1)\n($line2)\n($line3)"
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || "" }
$env.PROMPT_INDICATOR = { || "" }
