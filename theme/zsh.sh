### ================================
### SHELL OPTIONS SETUP
### ================================

### --------------------------------
### Expansion
### --------------------------------
setopt PROMPT_SUBST

### --------------------------------
### Globbing
### --------------------------------
setopt EXTENDED_GLOB
setopt GLOB_DOTS

### --------------------------------
### History
### --------------------------------
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY

### --------------------------------
### Interaction
### --------------------------------
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt RM_STAR_WAIT
setopt NO_CLOBBER
unsetopt BEEP

### --------------------------------
### Navigation
### --------------------------------
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt COMPLETE_IN_WORD

### ================================
### SHELL APPEARANCE
### ================================

() {
	zstyle ':prompt:colors' reset     '%f%b'

	zstyle ':prompt:colors' n_black   '%b%F{0}'
	zstyle ':prompt:colors' n_red     '%b%F{1}'
	zstyle ':prompt:colors' n_green   '%b%F{2}'
	zstyle ':prompt:colors' n_yellow  '%b%F{3}'
	zstyle ':prompt:colors' n_blue    '%b%F{4}'
	zstyle ':prompt:colors' n_magenta '%b%F{5}'
	zstyle ':prompt:colors' n_cyan    '%b%F{6}'
	zstyle ':prompt:colors' n_white   '%b%F{7}'

	zstyle ':prompt:colors' b_gray    '%B%F{8}'
	zstyle ':prompt:colors' b_red     '%B%F{9}'
	zstyle ':prompt:colors' b_green   '%B%F{10}'
	zstyle ':prompt:colors' b_yellow  '%B%F{11}'
	zstyle ':prompt:colors' b_blue    '%B%F{12}'
	zstyle ':prompt:colors' b_magenta '%B%F{13}'
	zstyle ':prompt:colors' b_cyan    '%B%F{14}'
	zstyle ':prompt:colors' b_white   '%B%F{15}'

	_git_branch() {
		if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
			local _branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
			if [[ -n "${_branch}" ]]; then
				local _indicator=""
				[[ -n "$(command git status --short -uno 2> "/dev/null" | command tail -n1)" ]] && _indicator="%B%F{11}*"
				if _is_raw_tty; then
					echo " %B%F{12}(%B%F{9}${_branch}${_indicator}%B%F{12})%f%b "
				else
					echo "❮%B%F{9}󰊢 %B%F{13}${_branch}${_indicator}%b%F{3}❯"
				fi
			fi
		elif [[ -d ".got" ]] && command -v got > "/dev/null" 2>&1; then
			local _branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
			if [[ -n "${_branch}" ]]; then
				if _is_raw_tty; then
					echo " %B%F{12}(%B%F{13}${_branch}%B%F{12})%f%b "
				else
					echo "❮%B%F{9}󰊢 %B%F{13}${_branch}%b%F{3}❯"
				fi
			fi
		fi
	}

	local z
	zstyle -s ':prompt:colors' reset z

	local k K r R g G y Y b B m M c C w W
	zstyle -s ':prompt:colors' n_black   k; zstyle -s ':prompt:colors' b_gray    K
	zstyle -s ':prompt:colors' n_red     r; zstyle -s ':prompt:colors' b_red     R
	zstyle -s ':prompt:colors' n_green   g; zstyle -s ':prompt:colors' b_green   G
	zstyle -s ':prompt:colors' n_yellow  y; zstyle -s ':prompt:colors' b_yellow  Y
	zstyle -s ':prompt:colors' n_blue    b; zstyle -s ':prompt:colors' b_blue    B
	zstyle -s ':prompt:colors' n_magenta m; zstyle -s ':prompt:colors' b_magenta M
	zstyle -s ':prompt:colors' n_cyan    c; zstyle -s ':prompt:colors' b_cyan    C
	zstyle -s ':prompt:colors' n_white   w; zstyle -s ':prompt:colors' b_white   W

	local u
	if [ "$(id -u)" -eq 0 ]; then
		zstyle -s ':prompt:colors' b_red u
	else
		zstyle -s ':prompt:colors' b_green u
	fi

	local _os_icon="${PROMPT_OS_ICON}"
	local _os_name="${PROMPT_OS_NAME}"
	local _sh_name="$ZSH_NAME"

	local _os_color
	case "$PROMPT_OS_COLOR" in
		red)  _os_color="$R" ;;
		blue) _os_color="$B" ;;
		*)    _os_color="$B" ;;
	esac

	if _is_raw_tty; then
		export PROMPT="${u}%n${B}@${M}%m ${B}(${C}zsh${B})${K}:${K}[${Y}%c${K}]${z}\$(_git_branch)${C}%#${z} "
	else
		export PROMPT="
${y}${_os_color}${_os_icon}${M}${_os_name}${y}─${B} ${M}${_sh_name}${y}
${y}┌──❮ ${G} %*${y} ❯─❮ ${G} %D{%d/%m/%y}${y} ❯─❮ ${Y} ${C}%c${y} ❯─ ❮${B} ${u}%n${y}❯ \$(_git_branch)
${y}└─${B}${z} "
	fi
}
