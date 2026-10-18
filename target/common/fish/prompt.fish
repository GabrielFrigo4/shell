# ----------------------------------------------------------------
# Module: Fish Shell Prompt Configuration
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
        set git_info (set_color -o brblack)""$git_info(set_color -o brblack)""
    end

    set -l os_name (uname -s 2>/dev/null; or echo "UNIX")
    set -l os_icon ""
    set -l kernel_rel ""
    switch "$os_name"
        case 'Linux'
            set os_icon "󰌽"
            if test -f /etc/os-release
                set os_name (string match -r '^VERSION_ID="?([^"\n]+)"?' < /etc/os-release)[2]
            end
            test -z "$os_name"; and set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
            set -l krel (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
            test -n "$krel"; and set kernel_rel " "(set_color -o blue)" "(set_color -o magenta)"$krel"
        case 'FreeBSD'
            set os_icon ""
            set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
        case 'Darwin'
            set os_icon "󰀵"
            set os_name (sw_vers -productVersion 2>/dev/null; or uname -r)
        case 'OpenBSD'
            set os_icon "󰈺"
            set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
        case 'MINGW*' 'MSYS*' 'CYGWIN*'
            set os_icon "󰍲"
            set os_name "Windows"
    end

    set -l sep (set_color -o brblack)
    set -l l1 "$sep"(set_color -o blue)"$os_icon "(set_color -o magenta)"$os_name"$kernel_rel" "(set_color -o blue)" "(set_color -o magenta)"fish"$sep""
    set -l l2 "$sep┌──"(set_color -o blue)" "(set_color -o green)"$time"$sep"─"(set_color -o blue)" "(set_color -o green)"$c_date"$sep"─"(set_color -o yellow)" "(set_color -o cyan)"$pwd_segment"$sep"─ "(set_color -o blue)" "(set_color -o green)"$user"$sep" $git_info"
    set -l l3 "$sep└─"(set_color -o blue)""(set_color normal)" "

    echo ""
    echo $l1
    echo $l2
    echo -n $l3
end
