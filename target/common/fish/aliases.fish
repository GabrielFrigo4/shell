# ----------------------------------------------------------------
# Module: Fish Shell Ecosystem Orchestration & Update Functions
# ----------------------------------------------------------------

function update-shell -d "Atualiza o repositório Universal Shell via git pull"
    for arg in $argv
        switch $arg
            case '-h' '--help'
                echo "Uso: upsh [opções] (alias: update-shell)"
                echo ""
                echo "Atualiza o repositório Universal Shell via git pull resiliente e recarrega."
                echo ""
                echo "Opções:"
                echo "  -s, --status    Audita o status do repositório Git local sem puxar"
                echo "  -n, --dry-run   Simula a sincronização sem efetuar pull"
                echo "  -h, --help      Exibe esta ajuda"
                return 0
        end
    end

    set -l target ""
    set -l candidates "$SHELL_REPO_DIR" "/usr/local/share/shell" "$HOME/.local/share/shell" "$HOME/.config/shell" "$HOME/.shell"
    for cand in $candidates
        if test -n "$cand" -a -d "$cand/.git"
            set target "$cand"
            break
        end
    end

    if test -z "$target"
        _ui_info "Repositório do Universal Shell não encontrado."
        return 1
    end

    set -l mode "update"
    for arg in $argv
        switch $arg
            case '-s' '--status'
                set mode "status"
            case '-n' '--dry-run'
                set mode "dry-run"
        end
    end

    if test "$mode" = "status"
        _ui_step "Auditando repositório do Universal Shell em $target..."
        git -C "$target" status -s -b
        return 0
    else if test "$mode" = "dry-run"
        _ui_step "[DRY-RUN] Atualização do Universal Shell em $target..."
        _ui_sub "git -C $target pull --ff-only"
        return 0
    end

    _ui_step "Atualizando Universal Shell em $target..."
    git -C "$target" pull --ff-only
    _ui_ok "Universal Shell atualizado com sucesso!"
end
alias upsh="update-shell"

function update-vault -d "Sincroniza o repositório Universal Vault e recarrega"
    for arg in $argv
        switch $arg
            case '-h' '--help'
                echo "Uso: upvt [opções] (alias: update-vault)"
                echo ""
                echo "Sincroniza segredos do Vault e recarrega chaves SSH."
                return 0
        end
    end

    set -l target ""
    set -l candidates "$VAULT_DIR" "$HOME/.local/share/vault" "$HOME/.config/vault" "$HOME/.vault"
    for cand in $candidates
        if test -n "$cand" -a -d "$cand/.git"
            set target "$cand"
            break
        end
    end

    if test -z "$target"
        _ui_info "Repositório do Universal Vault não encontrado."
        return 1
    end

    for arg in $argv
        switch $arg
            case '-s' '--status'
                _ui_step "Status do Universal Vault em: $target..."
                git -C "$target" status -s -b
                return 0
            case '-n' '--dry-run'
                _ui_step "[DRY-RUN] Atualização do Universal Vault em: $target..."
                _ui_sub "git -C $target pull --ff-only"
                return 0
        end
    end

    _ui_step "Atualizando Universal Vault em: $target..."
    git -C "$target" pull --ff-only
    _ui_ok "Universal Vault atualizado com sucesso!"
end
alias upvt="update-vault"

function update-editors -d "Atualiza os repositórios da Suíte de Editores"
    for arg in $argv
        switch $arg
            case '-h' '--help'
                echo "Uso: uped [opções] (alias: update-editors)"
                echo ""
                echo "Inspeciona e atualiza ~/.emacs.d, ~/.config/nvim, helix e vim."
                return 0
        end
    end

    set -l is_status 0
    set -l is_dry 0
    for arg in $argv
        switch $arg
            case '-s' '--status'
                set is_status 1
            case '-n' '--dry-run'
                set is_dry 1
        end
    end

    set -l editor_dirs "$HOME/.emacs.d" "$HOME/.config/nvim" "$HOME/.config/helix" "$HOME/.vim" "$HOME/vimfiles"
    set -l found 0
    _ui_step "Auditando Suíte de Editores..."
    for ed in $editor_dirs
        if test -d "$ed/.git"
            set found (math $found + 1)
            set -l ed_name (basename $ed)
            if test $is_status -eq 1
                _ui_sub "Status de $ed_name em $ed..."
                git -C "$ed" status -s -b
            else if test $is_dry -eq 1
                _ui_sub "[DRY-RUN] Atualização de $ed_name em $ed"
            else
                _ui_sub "Atualizando $ed_name em $ed..."
                git -C "$ed" pull --ff-only
            end
        end
    end

    if test $found -eq 0
        _ui_info "Nenhum repositório de editor encontrado nos caminhos padrão."
    else
        _ui_ok "Suíte de Editores sincronizada com sucesso!"
    end
end
alias uped="update-editors"

function update-profile -d "Atualiza Universal Profile e sincroniza dotfiles"
    for arg in $argv
        switch $arg
            case '-h' '--help'
                echo "Uso: uprc [opções] (alias: update-profile, sync-profile)"
                echo ""
                echo "Atualiza o repositório Universal Profile e sincroniza dotfiles."
                return 0
        end
    end

    set -l target ""
    set -l candidates "$PROFILE_DIR" "$HOME/.local/share/profile" "$HOME/.config/profile" "$HOME/.profile.d"
    for cand in $candidates
        if test -n "$cand" -a -d "$cand/.git"
            set target "$cand"
            break
        end
    end

    if test -z "$target"
        _ui_info "Repositório do Universal Profile não encontrado."
        return 1
    end

    for arg in $argv
        switch $arg
            case '-s' '--status'
                _ui_step "Status do Universal Profile em: $target..."
                git -C "$target" status -s -b
                return 0
            case '-n' '--dry-run'
                _ui_step "[DRY-RUN] Atualização do Universal Profile em: $target..."
                _ui_sub "git -C $target pull --ff-only"
                return 0
        end
    end

    _ui_step "Atualizando Universal Profile em: $target..."
    git -C "$target" pull --ff-only
    if test -f "$target/profile.sh"
        _ui_sub "Sincronizando dotfiles via profile.sh..."
        sh "$target/profile.sh" sync $argv
    end
    _ui_ok "Universal Profile atualizado e sincronizado com sucesso!"
end
alias uprc="update-profile"
alias upprofile="update-profile"
alias sync-profile="update-profile"

function update-git -d "Varre e atualiza recursivamente repositórios Git"
    set -l root_dir "."
    if test (count $argv) -gt 0; and not string match -r '^-' -- $argv[1]
        set root_dir $argv[1]
    end

    for arg in $argv
        switch $arg
            case '-h' '--help'
                echo "Uso: upgit [diretório] [opções] (alias: update-git)"
                echo ""
                echo "Varre e atualiza repositórios Git recursivamente."
                return 0
        end
    end

    _ui_step "Buscando repositórios Git em: $root_dir"
    for git_dir in (find "$root_dir" -maxdepth 3 -type d -name ".git" 2>/dev/null)
        set -l repo (dirname "$git_dir")
        set -l branch (git -C "$repo" branch --show-current 2>/dev/null; or echo "detached")
        _ui_sub "Atualizando $repo [$branch]..."
        git -C "$repo" pull --ff-only 2>/dev/null; or git -C "$repo" pull 2>/dev/null
    end
    _ui_ok "Operação Git concluída!"
end
alias upgit="update-git"

function clean-system -d "Limpeza de pacotes órfãos, dependências obsoletas e caches do sistema"
    _ui_step "Executando limpeza de pacotes órfãos e caches do sistema..."
    if type -q apt
        _ui_sub "Removendo pacotes órfãos via apt autoremove..."
        sudo apt autoremove --yes; or doas apt autoremove --yes
        _ui_sub "Limpando cache de pacotes baixados pelo apt..."
        sudo apt clean 2>/dev/null; or doas apt clean 2>/dev/null
    else if type -q dnf
        _ui_sub "Removendo pacotes órfãos via dnf autoremove..."
        sudo dnf autoremove --assumeyes; or doas dnf autoremove --assumeyes
    else if type -q pacman
        set -l orphans (pacman -Qtdq 2>/dev/null)
        if test -n "$orphans"
            _ui_sub "Removendo pacotes órfãos via pacman..."
            sudo pacman -Rns --noconfirm $orphans; or doas pacman -Rns --noconfirm $orphans
        end
    else if type -q pkg
        _ui_sub "Removendo pacotes órfãos via pkg autoremove..."
        sudo pkg autoremove --yes; or doas pkg autoremove --yes
        _ui_sub "Limpando cache de pacotes via pkg clean..."
        sudo pkg clean --yes 2>/dev/null; or doas pkg clean --yes 2>/dev/null
    else if type -q brew
        _ui_sub "Executando limpeza de dependências obsoletas via Homebrew..."
        brew cleanup --prune=all
    end

    if type -q flatpak
        _ui_sub "Removendo runtimes órfãos do Flatpak..."
        command flatpak uninstall --unused --assumeyes 2>/dev/null
    end

    _ui_ok "Limpeza do sistema concluída com sucesso!"
end
alias cleansys="clean-system"
alias clearsys="clean-system"
alias sysclean="clean-system"
alias syscls="clean-system"
alias clear-system="clean-system"

function update-all -d "Orquestra atualização completa do sistema e ecossistema"
    _ui_banner "Atualização Global do Ecossistema e Sistema"
    update-shell $argv
    update-profile $argv
    update-vault $argv
    update-editors $argv
    clean-system $argv
    _ui_banner "Atualização Global Concluída com Sucesso"
end
alias upall="update-all"

# ----------------------------------------------------------------
# Module: Desktop Applications & Editor Aliases
# ----------------------------------------------------------------

function open-vlc -d "Abre o VLC media player"
    if type -q vlc
        vlc $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "vlc não encontrado."
        return 127
    end
end
alias ov="open-vlc"

function open-mpv -d "Abre o MPV media player"
    if type -q mpv
        mpv $argv
    else
        _ui_err "mpv não encontrado."
        return 127
    end
end
alias om="open-mpv"

function open-wireshark -d "Abre o Wireshark analisador de rede"
    if type -q wireshark
        wireshark $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "wireshark não encontrado."
        return 127
    end
end
alias open-shark="open-wireshark"
alias os="open-wireshark"

function open-firefox -d "Abre o navegador Mozilla Firefox"
    if type -q firefox
        firefox $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "firefox não encontrado."
        return 127
    end
end
alias of="open-firefox"

function open-browser -d "Abre o navegador web universal via cascata de preferência"
    set -l browser ""
    for cand in google-chrome google-chrome-stable brave-browser brave chromium chromium-browser
        if type -q $cand
            set browser $cand
            break
        end
    end
    if test -z "$browser"; and test (uname -s 2>/dev/null) = "FreeBSD"; and type -q chrome
        set browser "chrome"
    end
    if test -z "$browser"
        for cand in microsoft-edge firefox
            if type -q $cand
                set browser $cand
                break
            end
        end
    end
    if test -z "$browser"; and test (uname -s 2>/dev/null) = "Darwin"
        open -a Safari $argv
        return 0
    end
    if test -n "$browser"
        $browser $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "Nenhum navegador web suportado encontrado."
        return 127
    end
end
alias open-web="open-browser"
alias ow="open-browser"

function open-onlyoffice -d "Abre o OnlyOffice Desktop Editors"
    set -l bin ""
    for cand in onlyoffice-desktopeditors desktopeditors
        if type -q $cand
            set bin $cand
            break
        end
    end
    if test -n "$bin"
        $bin $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "OnlyOffice não encontrado."
        return 127
    end
end
alias oo="open-onlyoffice"

function open-libreoffice -d "Abre a suíte LibreOffice"
    set -l bin ""
    for cand in libreoffice soffice
        if type -q $cand
            set bin $cand
            break
        end
    end
    if test -n "$bin"
        $bin $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "LibreOffice não encontrado."
        return 127
    end
end
alias ol="open-libreoffice"

function open-terminal -d "Abre novo emulador de terminal"
    set -l term ""
    for cand in konsole kgx gnome-terminal xfce4-terminal foot alacritty kitty wezterm xterm
        if type -q $cand
            set term $cand
            break
        end
    end
    if test -n "$term"
        $term $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "Nenhum emulador de terminal suportado encontrado."
        return 127
    end
end
alias ot="open-terminal"

function open-thunderbird -d "Abre o cliente de e-mail Mozilla Thunderbird"
    if type -q thunderbird
        thunderbird $argv >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        _ui_err "thunderbird não encontrado."
        return 127
    end
end
alias open-mail="open-thunderbird"
alias omail="open-thunderbird"
alias oth="open-thunderbird"

function open-kate -d "Abre o editor Kate"
    if type -q kate; kate $argv >/dev/null 2>&1 &; disown 2>/dev/null; else; _ui_err "kate não encontrado."; return 127; end
end
alias ok="open-kate"

function open-geany -d "Abre o editor Geany"
    if type -q geany; geany $argv >/dev/null 2>&1 &; disown 2>/dev/null; else; _ui_err "geany não encontrado."; return 127; end
end
alias og="open-geany"

function open-code -d "Abre o Visual Studio Code"
    set -l bin ""
    for cand in vscode code
        if type -q $cand; set bin $cand; break; end
    end
    if test -n "$bin"; $bin $argv; else; _ui_err "VS Code não encontrado."; return 127; end
end
alias oc="open-code"

function open-codium -d "Abre o VSCodium"
    if type -q codium; codium $argv; else; _ui_err "codium não encontrado."; return 127; end
end
alias ocm="open-codium"

function open-antigravity -d "Abre o Google Antigravity IDE"
    if type -q antigravity-ide; antigravity-ide $argv; else; _ui_err "antigravity-ide não encontrado."; return 127; end
end
alias open-ant="open-antigravity"
alias oa="open-antigravity"
alias ant="antigravity-ide"

function open-zed -d "Abre o editor Zed"
    if type -q zed; zed $argv; else; _ui_err "zed não encontrado."; return 127; end
end
alias oz="open-zed"

# ----------------------------------------------------------------
# Module: Modern Single-Character & Rust CLI Tools
# ----------------------------------------------------------------

function r
    if type -q rg
        if isatty stdout
            command rg --smart-case $argv
        else
            command rg --smart-case --color=never $argv
        end
    else
        command grep -Ei $argv
    end
end

function g
    r $argv
end

function _shell_ls --argument-names mode
    set -l args $argv[2..-1]
    if type -q eza
        set -l opts --group-directories-first
        if isatty stdout
            set -p opts --icons=auto
        else
            set -p opts --icons=never --color=never
        end
        switch $mode
            case l
                command eza $opts $args
            case ll
                command eza -la $opts --git $args
            case la
                command eza -a $opts $args
            case lt
                command eza --tree $opts $args
            case lr
                command eza -R $opts $args
            case lar
                command eza -aR $opts $args
            case llr
                command eza -laR $opts --git $args
        end
    else if type -q exa
        set -l opts --group-directories-first
        if not isatty stdout
            set -p opts --color=never
        end
        switch $mode
            case l
                command exa $opts $args
            case ll
                command exa -la $opts --git $args
            case la
                command exa -a $opts $args
            case lt
                command exa --tree $opts $args
            case lr
                command exa -R $opts $args
            case lar
                command exa -aR $opts $args
            case llr
                command exa -laR $opts --git $args
        end
    else
        switch $mode
            case lt
                if type -q tree
                    if isatty stdout
                        command tree $args
                    else
                        command tree -n $args
                    end
                else
                    command ls -R $args
                end
            case l
                command ls $args
            case ll
                command ls -laF $args
            case la
                command ls -a $args
            case lr
                command ls -R $args
            case lar
                command ls -aR $args
            case llr
                command ls -laR $args
        end
    end
end

function l; _shell_ls l $argv; end
function ll; _shell_ls ll $argv; end
function la; _shell_ls la $argv; end
function lt; _shell_ls lt $argv; end
function lr; _shell_ls lr $argv; end
function lar; _shell_ls lar $argv; end
function llr; _shell_ls llr $argv; end

function c
    if type -q bat
        if isatty stdout
            command bat --paging=never $argv
        else
            command bat --plain --color=never --paging=never $argv
        end
    else
        command cat $argv
    end
end

function b
    if type -q bat
        if isatty stdout
            command bat $argv
        else
            command bat --plain --color=never --paging=never $argv
        end
    else if isatty stdout
        command less $argv
    else
        command cat $argv
    end
end

function f
    if type -q fd
        if isatty stdout
            command fd $argv
        else
            command fd --color=never $argv
        end
    else
        command find $argv
    end
end

function ff
    if type -q fd
        if isatty stdout
            command fd --hidden --no-ignore $argv
        else
            command fd --hidden --no-ignore --color=never $argv
        end
    else
        command find $argv
    end
end

function d
    if type -q dust
        if isatty stdout
            command dust $argv
        else
            NO_COLOR=1 command dust $argv
        end
    else
        command du -h $argv
    end
end

function p
    if type -q procs
        if isatty stdout
            command procs $argv
        else
            NO_COLOR=1 command procs --color disable $argv
        end
    else
        command ps aux $argv
    end
end

function pst
    if type -q procs
        if isatty stdout
            command procs --tree $argv
        else
            NO_COLOR=1 command procs --tree --color disable $argv
        end
    else
        command ps aux $argv
    end
end

if type -q btm
    alias t="btm"
else if type -q btop
    alias t="btop"
else if type -q htop
    alias t="htop"
else
    alias t="top"
end

if not type -q delta; and type -q git-delta
    alias delta="git-delta"
end
