# ----------------------------------------------------------------
# Module: Fish Shell Prompt Configuration
# ----------------------------------------------------------------

function fish_mode_prompt; end

function fish_prompt
    set -l last_status $status
    set -l dt (date "+%H:%M:%S %d/%m/%y" 2>/dev/null | string split " ")
    set -l time "$dt[1]"
    set -l c_date "$dt[2]"

    set -l user "$USER"
    test -z "$user"; and set user "$LOGNAME"
    test -z "$user"; and set user (id -un 2>/dev/null; or echo "user")

    set -l user_color brgreen
    set -l user_icon_color brblue
    set -l terminal_color brblue
    if fish_is_root_user
        set user "root"
        set user_color brmagenta
        set user_icon_color brred
        set terminal_color brred
    end

    set -l pwd_segment (prompt_pwd)

    set -l git_info ""
    set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set -l dirty ""
        set -l st (git status --porcelain=v1 -uno --ignore-submodules=dirty 2>/dev/null)
        test -n "$st"; and set dirty "*"
        set git_info " "(set_color -o brblack)""(set_color -o brred)"󰊢 "(set_color -o brmagenta)"$branch"(set_color -o bryellow)"$dirty"(set_color -o brblack)""
    end

    set -l os_sys (uname -s 2>/dev/null; or echo "UNIX")
    set -l os_name ""
    set -l os_icon ""
    set -l os_color_name "blue"
    set -l kernel_rel ""

    switch "$os_sys"
        case 'Linux'
            set os_icon ""
            set os_color_name "blue"
            set -l distro_id ""
            if test -r /etc/os-release
                set -l os_rel (cat /etc/os-release 2>/dev/null)
                set -l ver_match (string match -r '^VERSION_ID="?([^"\n]+)"?' -- $os_rel)
                if test (count $ver_match) -ge 2
                    set os_name "$ver_match[2]"
                end
                set -l id_match (string match -r '^ID="?([^"\n]+)"?' -- $os_rel)
                if test (count $id_match) -ge 2
                    set distro_id "$id_match[2]"
                end
            end
            switch "$distro_id"
                case 'fedora'; set os_icon ""
                case 'arch'; set os_icon ""; test -z "$os_name"; and set os_name "rolling"
                case 'manjaro'; set os_icon ""
                case 'endeavouros'; set os_icon ""
                case 'garuda'; set os_icon "󰛓"
                case 'cachyos'; set os_icon ""
                case 'artix'; set os_icon ""
                case 'debian'; set os_icon ""
                case 'devuan'; set os_icon ""
                case 'ubuntu'; set os_icon ""
                case 'linuxmint' 'mint'; set os_icon ""
                case 'pop'; set os_icon ""
                case 'kali'; set os_icon ""
                case 'opensuse*' 'sles'; set os_icon ""
                case 'void'; set os_icon ""; test -z "$os_name"; and set os_name "rolling"
                case 'alpine'; set os_icon ""
                case 'gentoo'; set os_icon ""; test -z "$os_name"; and set os_name "rolling"
                case 'nixos'; set os_icon ""
            end
            set -l krel (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
            test -z "$os_name"; and set os_name "$krel"
            test -n "$krel"; and set kernel_rel " "(set_color -o brblue)" "(set_color -o brmagenta)"$krel"
        case 'FreeBSD'
            set os_icon ""
            set os_color_name "red"
            set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
        case 'OpenBSD'
            set os_icon ""
            set os_color_name "yellow"
            set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
        case 'NetBSD'
            set os_icon ""
            set os_color_name "yellow"
            set os_name (uname -r 2>/dev/null | string replace -r '[-+~_].*' '')
        case 'Darwin'
            set os_icon ""
            set os_color_name "cyan"
            set os_name (sw_vers -productVersion 2>/dev/null; or uname -r)
        case 'SunOS'
            set os_icon "󰖨"
            set os_color_name "yellow"
            set os_name (uname -v 2>/dev/null; or uname -r 2>/dev/null; or echo "illumos")
            set os_name (string replace -r '_.*' '' -- "$os_name")
        case 'MINGW*' 'MSYS*' 'CYGWIN*' 'Windows*'
            set os_icon ""
            set os_color_name "blue"
            if set -q MSYSTEM; and test -n "$MSYSTEM"
                set os_name "$MSYSTEM"
            else
                set os_name "MSYS2"
            end
        case '*'
            set os_name "$os_sys"
    end

    if set -q PROMPT_OS_ICON; and test -n "$PROMPT_OS_ICON"
        set os_icon (string trim -r -- "$PROMPT_OS_ICON")
    end
    if set -q PROMPT_OS_NAME; and test -n "$PROMPT_OS_NAME"
        set os_name (string replace -r '[-+~_].*' '' -- "$PROMPT_OS_NAME")
    end
    if set -q PROMPT_OS_COLOR; and test -n "$PROMPT_OS_COLOR"
        set os_color_name "$PROMPT_OS_COLOR"
    end

    set -l os_color brblue
    switch "$os_color_name"
        case 'red';     set os_color brred
        case 'green';   set os_color brgreen
        case 'yellow';  set os_color bryellow
        case 'blue';    set os_color brblue
        case 'magenta'; set os_color brmagenta
        case 'cyan';    set os_color brcyan
        case 'white';   set os_color brwhite
    end

    set -l sep (set_color -o brblack)
    set -l l1 "$sep"(set_color -o $os_color)"$os_icon "(set_color -o brmagenta)"$os_name"$kernel_rel" "(set_color -o brblue)" "(set_color -o brmagenta)"fish"$sep""
    set -l l2 "$sep┌──"(set_color -o brblue)" "(set_color -o brgreen)"$time"$sep"─"(set_color -o brblue)" "(set_color -o brgreen)"$c_date"$sep"─"(set_color -o bryellow)" "(set_color -o brcyan)"$pwd_segment"$sep"─ "(set_color -o $user_icon_color)" "(set_color -o $user_color)"$user"$sep"$git_info"
    set -l l3 "$sep└─"(set_color -o $terminal_color)""(set_color normal)" "

    echo ""
    echo $l1
    echo $l2
    echo -n $l3
end
