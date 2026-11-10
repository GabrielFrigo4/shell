#!/usr/bin/env sh
# ----------------------------------------------------------------
# Module: Universal Shell Completion Engine & Flags Registry
# ----------------------------------------------------------------

### --------------------------------
### BASH COMPLETION ENGINE
### --------------------------------
if [ -n "${BASH_VERSION:-}" ]; then
	eval '_complete_wm_session() {
		local cur prev words cword
		if declare -F _init_completion > "/dev/null" 2>&1; then
			_init_completion -n : 2> "/dev/null" || {
				cur="${COMP_WORDS[COMP_CWORD]}"
				prev="${COMP_WORDS[COMP_CWORD-1]}"
			}
		else
			cur="${COMP_WORDS[COMP_CWORD]}"
			prev="${COMP_WORDS[COMP_CWORD-1]}"
		fi

		local cmd="${COMP_WORDS[0]}"
		local wayland_wms="sway labwc river hyprland niri wayfire dwl cage"
		local x11_wms="openbox cwm dwm fvwm twm matchbox matchbox-window-manager"
		local flavors="-g --gnome -k --kde -x --xfce -m --mate -c --cinnamon --lxqt --lxde --budgie --pantheon --deepin --cosmic"
		local common_opts="-l --list --pipeline -w --wm ${flavors}"

		case "${cmd}" in
			wwm|window-manager-wayland|wgui|graphical-launcher-wayland)
				if [ "${prev}" = "-w" ] || [ "${prev}" = "--wm" ]; then
					COMPREPLY=( $(compgen -W "${wayland_wms}" -- "${cur}") )
					return 0
				fi
				local way_flags="--sway --labwc --river --cage --hyprland --niri --wayfire --dwl"
				case "${cur}" in
					-*)
						COMPREPLY=( $(compgen -W "${common_opts} ${way_flags}" -- "${cur}") )
						return 0
						;;
				esac
				;;
			xwm|window-manager-x11|xgui|graphical-launcher-x11)
				if [ "${prev}" = "-w" ] || [ "${prev}" = "--wm" ]; then
					COMPREPLY=( $(compgen -W "${x11_wms}" -- "${cur}") )
					return 0
				fi
				local x11_flags="--openbox --cwm --dwm --fvwm --twm --matchbox --matchbox-window-manager"
				case "${cur}" in
					-*)
						COMPREPLY=( $(compgen -W "${common_opts} ${x11_flags}" -- "${cur}") )
						return 0
						;;
				esac
				;;
			wm|window-manager|gui|graphical-launcher)
				if [ "${prev}" = "-w" ] || [ "${prev}" = "--wm" ]; then
					COMPREPLY=( $(compgen -W "${wayland_wms} ${x11_wms}" -- "${cur}") )
					return 0
				fi
				local all_flags="--sway --labwc --river --cage --hyprland --niri --wayfire --dwl --openbox --cwm --dwm --fvwm --twm --matchbox --matchbox-window-manager"
				case "${cur}" in
					-*)
						COMPREPLY=( $(compgen -W "${common_opts} ${all_flags}" -- "${cur}") )
						return 0
						;;
				esac
				;;
		esac

		case "${cmd}" in
			gui|graphical-launcher|wgui|graphical-launcher-wayland|xgui|graphical-launcher-x11)
				COMPREPLY=( $(compgen -c -- "${cur}") )
				return 0
				;;
		esac
	}
	complete -F _complete_wm_session wm window-manager wwm window-manager-wayland xwm window-manager-x11 gui graphical-launcher wgui graphical-launcher-wayland xgui graphical-launcher-x11 2> "/dev/null" || true'
fi

### --------------------------------
### ZSH COMPLETION ENGINE
### --------------------------------
if [ -n "${ZSH_VERSION:-}" ]; then
	eval '_zsh_wm_complete() {
		local -a common_opts wayland_opts x11_opts wayland_wms x11_wms all_wms
		common_opts=(
			"-l[Exibir ordem do pipeline de gerenciadores]"
			"--list[Exibir ordem do pipeline de gerenciadores]"
			"--pipeline[Exibir ordem do pipeline de gerenciadores]"
			"-w[Selecionar gerenciador de janelas]:wm:->wm_list"
			"--wm[Selecionar gerenciador de janelas]:wm:->wm_list"
			"-g[Ambiente GNOME]" "--gnome[Ambiente GNOME]"
			"-k[Ambiente KDE]" "--kde[Ambiente KDE]"
			"-x[Ambiente XFCE]" "--xfce[Ambiente XFCE]"
			"-m[Ambiente MATE]" "--mate[Ambiente MATE]"
			"-c[Ambiente Cinnamon]" "--cinnamon[Ambiente Cinnamon]"
			"--lxqt[Ambiente LXQt]"
			"--lxde[Ambiente LXDE]"
			"--budgie[Ambiente Budgie]"
			"--pantheon[Ambiente Pantheon]"
			"--deepin[Ambiente Deepin]"
			"--cosmic[Ambiente COSMIC]"
		)
		wayland_opts=(
			"--sway[Executar compositor Sway]"
			"--labwc[Executar compositor Labwc]"
			"--river[Executar compositor River]"
			"--hyprland[Executar compositor Hyprland]"
			"--niri[Executar compositor Niri]"
			"--wayfire[Executar compositor Wayfire]"
			"--dwl[Executar compositor DWL]"
			"--cage[Executar compositor Cage]"
		)
		x11_opts=(
			"--openbox[Executar gerenciador Openbox]"
			"--cwm[Executar gerenciador CWM]"
			"--dwm[Executar gerenciador DWM]"
			"--fvwm[Executar gerenciador FVWM]"
			"--twm[Executar gerenciador TWM]"
			"--matchbox[Executar gerenciador Matchbox]"
			"--matchbox-window-manager[Executar gerenciador Matchbox]"
		)
		wayland_wms=(sway labwc river hyprland niri wayfire dwl cage)
		x11_wms=(openbox cwm dwm fvwm twm matchbox matchbox-window-manager)
		all_wms=(${wayland_wms} ${x11_wms})

		case "${words[1]}" in
			wwm|window-manager-wayland|wgui|graphical-launcher-wayland)
				_arguments -s -S "${common_opts[@]}" "${wayland_opts[@]}" "*:comando:_command_names" && return 0
				;;
			xwm|window-manager-x11|xgui|graphical-launcher-x11)
				_arguments -s -S "${common_opts[@]}" "${x11_opts[@]}" "*:comando:_command_names" && return 0
				;;
			wm|window-manager|gui|graphical-launcher)
				_arguments -s -S "${common_opts[@]}" "${wayland_opts[@]}" "${x11_opts[@]}" "*:comando:_command_names" && return 0
				;;
		esac

		if [ "${state:-}" = "wm_list" ]; then
			case "${words[1]}" in
				wwm|window-manager-wayland|wgui|graphical-launcher-wayland)
					_describe "compositor wayland" wayland_wms && return 0
					;;
				xwm|window-manager-x11|xgui|graphical-launcher-x11)
					_describe "gerenciador x11" x11_wms && return 0
					;;
				*)
					_describe "gerenciador de janelas" all_wms && return 0
					;;
			esac
		fi
	}
	compdef _zsh_wm_complete wm window-manager wwm window-manager-wayland xwm window-manager-x11 gui graphical-launcher wgui graphical-launcher-wayland xgui graphical-launcher-x11 2> "/dev/null" || true'
fi
