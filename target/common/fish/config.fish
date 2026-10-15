# ----------------------------------------------------------------
# Module: Fish Shell Universal Runtime Configuration
# ----------------------------------------------------------------

# ----------------------------------------------------------------
# Environment & PATH
# ----------------------------------------------------------------
if not set -q SHELL_REPO_DIR
    set -l script_dir ""
    set -l current_file (status filename 2>/dev/null)
    if test -n "$current_file"
        set -l f_dir (path dirname "$current_file" 2>/dev/null)
        set script_dir (path dirname (path dirname (path dirname "$f_dir" 2>/dev/null) 2>/dev/null) 2>/dev/null)
    end
    set -l repo_candidates "$HOME/.local/share/shell" "/usr/local/share/shell" "$HOME/.config/shell" "$HOME/.shell" "$script_dir"
    for cand in $repo_candidates
        if test -n "$cand" -a -f "$cand/shell.sh"
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
# Modular Subsystems
# ----------------------------------------------------------------
set -l fish_dir (path dirname (status filename 2>/dev/null) 2>/dev/null)
if test -z "$fish_dir" -a -n "$SHELL_REPO_DIR"
    set fish_dir "$SHELL_REPO_DIR/target/common/fish"
end

if test -n "$fish_dir"
    test -f "$fish_dir/ui.fish"; and source "$fish_dir/ui.fish"
    test -f "$fish_dir/prompt.fish"; and source "$fish_dir/prompt.fish"
    test -f "$fish_dir/aliases.fish"; and source "$fish_dir/aliases.fish"
end
