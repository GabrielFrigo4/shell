### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Interactive Key Bindings
### --------------------------------
if [ -t 0 ] && [ -t 1 ]; then
	case "$-" in
		*i*)
			bind "^[[A" ed-search-prev-history 2> "/dev/null" || true
			bind "^[OA" ed-search-prev-history 2> "/dev/null" || true
			bind "^[[B" ed-search-next-history 2> "/dev/null" || true
			bind "^[OB" ed-search-next-history 2> "/dev/null" || true
			bind "^[[5~" ed-search-prev-history 2> "/dev/null" || true
			bind "^[[6~" ed-search-next-history 2> "/dev/null" || true

			bind "^R" em-inc-search-prev 2> "/dev/null" || true
			bind "^S" em-inc-search-next 2> "/dev/null" || true

			bind "^A" ed-move-to-beg 2> "/dev/null" || true
			bind "^E" ed-move-to-end 2> "/dev/null" || true
			bind "^[[H" ed-move-to-beg 2> "/dev/null" || true
			bind "^[OH" ed-move-to-beg 2> "/dev/null" || true
			bind "^[[1~" ed-move-to-beg 2> "/dev/null" || true
			bind "^[[7~" ed-move-to-beg 2> "/dev/null" || true
			bind "^[[F" ed-move-to-end 2> "/dev/null" || true
			bind "^[OF" ed-move-to-end 2> "/dev/null" || true
			bind "^[[4~" ed-move-to-end 2> "/dev/null" || true
			bind "^[[8~" ed-move-to-end 2> "/dev/null" || true

			bind "^[[3~" ed-delete-next-char 2> "/dev/null" || true
			bind "^W" ed-delete-prev-word 2> "/dev/null" || true
			bind "\ed" em-delete-next-word 2> "/dev/null" || true
			bind "\eb" ed-prev-word 2> "/dev/null" || true
			bind "\ef" em-next-word 2> "/dev/null" || true

			bind "\e[1;5C" em-next-word 2> "/dev/null" || true
			bind "\e[1;5D" ed-prev-word 2> "/dev/null" || true
			bind "\e[1;3C" em-next-word 2> "/dev/null" || true
			bind "\e[1;3D" ed-prev-word 2> "/dev/null" || true
			bind "\e[5C" em-next-word 2> "/dev/null" || true
			bind "\e[5D" ed-prev-word 2> "/dev/null" || true

			bind "^U" em-kill-line 2> "/dev/null" || true
			bind "^K" ed-kill-line 2> "/dev/null" || true
			bind "^Y" em-yank 2> "/dev/null" || true
			bind "^L" ed-clear-screen 2> "/dev/null" || true
			;;
	esac
fi
