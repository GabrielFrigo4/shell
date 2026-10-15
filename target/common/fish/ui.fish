# ----------------------------------------------------------------
# Module: Fish Shell Semantic UI Helpers
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
