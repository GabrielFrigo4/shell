### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Interactive Key Bindings
### --------------------------------
if [ -t 1 ] && case "$-" in *i*) true;; *) false;; esac; then
	bind "^[[A"=up-history 2> "/dev/null" || true
	bind "^[OA"=up-history 2> "/dev/null" || true
	bind "^[[B"=down-history 2> "/dev/null" || true
	bind "^[OB"=down-history 2> "/dev/null" || true
	bind "^[[5~"=up-history 2> "/dev/null" || true
	bind "^[[6~"=down-history 2> "/dev/null" || true

	bind "^R"=search-history 2> "/dev/null" || true

	bind "^[[H"=beginning-of-line 2> "/dev/null" || true
	bind "^[OH"=beginning-of-line 2> "/dev/null" || true
	bind "^[[1~"=beginning-of-line 2> "/dev/null" || true
	bind "^[[7~"=beginning-of-line 2> "/dev/null" || true
	bind "^[[F"=end-of-line 2> "/dev/null" || true
	bind "^[OF"=end-of-line 2> "/dev/null" || true
	bind "^[[4~"=end-of-line 2> "/dev/null" || true
	bind "^[[8~"=end-of-line 2> "/dev/null" || true

	bind "^[[3~"=delete-char-forward 2> "/dev/null" || true
	bind "^W"=delete-word-backward 2> "/dev/null" || true
	bind "^U"=kill-to-beginning-of-line 2> "/dev/null" || true
	bind "^K"=kill-to-end-of-line 2> "/dev/null" || true
	bind "^L"=clear-screen 2> "/dev/null" || true
fi
