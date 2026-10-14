# ----------------------------------------------------------------
# Module: Fish Shell Universal Runtime Configuration
# ----------------------------------------------------------------

set -l fish_dir (dirname (status filename))

# ----------------------------------------------------------------
# Environment & PATH
# ----------------------------------------------------------------
if not set -q SHELL_REPO_DIR
    set -l repo_candidates "$HOME/.local/share/shell" "/usr/local/share/shell" "$HOME/.config/shell" "$HOME/.shell" (dirname (dirname (dirname $fish_dir)))
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
# Libraries & Helpers
# ----------------------------------------------------------------
test -f "$fish_dir/ui.fish"; and source "$fish_dir/ui.fish"
test -f "$fish_dir/updates.fish"; and source "$fish_dir/updates.fish"

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
