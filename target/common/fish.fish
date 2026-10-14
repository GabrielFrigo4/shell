# ----------------------------------------------------------------
# Module: Fish Shell Universal Runtime Configuration
# ----------------------------------------------------------------

# ----------------------------------------------------------------
# Environment & PATH
# ----------------------------------------------------------------
if not set -q SHELL_REPO_DIR
    set -l repo_candidates "$HOME/.local/share/shell" "/usr/local/share/shell" "$HOME/.config/shell" "$HOME/.shell" (dirname (dirname (dirname (status filename))))
    for cand in $repo_candidates
        if test -f "$cand/shell.sh"
            set -gx SHELL_REPO_DIR "$cand"
            break
        end
    end
end

for p in "$HOME/.local/bin" "$HOME/.cargo/bin"
    if test -d "$p"; and not contains "$p" $PATH
        set -gx PATH "$p" $PATH
    end
end

# ----------------------------------------------------------------
# Semantic UI Emission Helpers
# ----------------------------------------------------------------
function _ui_has_color
    test -t 1; or return 1
    switch "$TERM"
        case 'dumb' ''
            return 1
        case '*'
            return 0
    end
end

function _ui_step
    if _ui_has_color
        set_color -o cyan
        echo -n "==> "
        set_color normal
    else
        printf "==> "
    end
    echo $argv
end

function _ui_sub
    if _ui_has_color
        set_color -o blue
        echo -n "  ↳ "
        set_color normal
    else
        printf "  -> "
    end
    echo $argv
end

function _ui_ok
    if _ui_has_color
        set_color -o green
        echo -n "  ✅ "
        set_color normal
    else
        printf "  OK "
    end
    echo $argv
end

function _ui_warn
    if _ui_has_color
        set_color -o yellow
        echo -n "  ⚠️  "
        set_color normal
    else
        printf "  WARN "
    end
    echo $argv
end

function _ui_err
    if test -t 2
        set_color -o red
        echo -n "  ❌ " >&2
        set_color normal
    else
        printf "  FAIL " >&2
    end
    echo $argv >&2
end

function _ui_info
    if _ui_has_color
        set_color -o magenta
        echo -n "  ℹ️  "
        set_color normal
    else
        printf "  INFO "
    end
    echo $argv
end

function _ui_banner
    set -l sep "================================================================"
    echo ""
    if _ui_has_color
        set_color -o cyan
        echo $sep
        echo "  $argv[1]"
        echo $sep
        set_color normal
    else
        echo $sep
        echo "  $argv[1]"
        echo $sep
    end
    echo ""
end

# ----------------------------------------------------------------
# Prompt Configuration
# ----------------------------------------------------------------
function fish_mode_prompt; end

function fish_prompt
    set -l last_status $status
    set -l time (date "+%H:%M:%S")
    set -l c_date (date "+%d/%m/%y")
    set -l user (whoami 2>/dev/null; or echo "user")
    set -l pwd_segment (prompt_pwd)

    set -l git_info ""
    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$branch"
        set -l dirty ""
        set -l st (git status --porcelain=v1 -uno --ignore-submodules=dirty 2>/dev/null)
        test -n "$st"; and set dirty "*"
        set git_info (set_color -o red)"󰊢 "(set_color -o magenta)"$branch"(set_color -o yellow)"$dirty"
        set git_info (set_color -o brblack)"❮"$git_info(set_color -o brblack)"❯"
    end

    set -l os_name (uname -s 2>/dev/null; or echo "UNIX")
    set -l os_icon ""
    switch "$os_name"
        case 'Linux'
            set os_icon "󰌽"
        case 'FreeBSD'
            set os_icon ""
        case 'Darwin'
            set os_icon "󰀵"
        case 'OpenBSD'
            set os_icon "󰈺"
        case 'MINGW*' 'MSYS*' 'CYGWIN*'
            set os_icon "󰍲"
            set os_name "Windows"
    end

    set -l sep (set_color -o brblack)
    set -l l1 "$sep"(set_color -o blue)"$os_icon "(set_color -o magenta)"$os_name"$sep"─"(set_color -o blue)" "(set_color -o magenta)"fish"$sep""
    set -l l2 "$sep┌──❮"(set_color -o blue)" "(set_color -o green)"$time"$sep"❯─❮"(set_color -o blue)" "(set_color -o green)"$c_date"$sep"❯─❮"(set_color -o yellow)" "(set_color -o cyan)"$pwd_segment"$sep"❯─ ❮"(set_color -o blue)" "(set_color -o green)"$user"$sep"❯ $git_info"
    set -l l3 "$sep└─"(set_color -o blue)""(set_color normal)" "

    echo ""
    echo $l1
    echo $l2
    echo -n $l3
end

# ----------------------------------------------------------------
# Ecosystem Orchestration & Update Functions
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

function update-all -d "Orquestra atualização completa do sistema e ecossistema"
    _ui_banner "Atualização Global do Ecossistema e Sistema"
    update-shell $argv
    update-profile $argv
    update-vault $argv
    update-editors $argv
    _ui_banner "Atualização Global Concluída com Sucesso"
end
alias upall="update-all"
