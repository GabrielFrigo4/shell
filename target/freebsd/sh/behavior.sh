### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Interactive Key Bindings
### --------------------------------
if [ -t 0 ] && [ -t 1 ]; then
	case "$-" in
		*i*)
			bind "^I" sh-complete 2> "/dev/null" || true

			bind "^[[A" ed-search-prev-history 2> "/dev/null" || true
			bind "^[OA" ed-search-prev-history 2> "/dev/null" || true
			bind "^[[B" ed-search-next-history 2> "/dev/null" || true
			bind "^[OB" ed-search-next-history 2> "/dev/null" || true
			bind "^[[5~" ed-search-prev-history 2> "/dev/null" || true
			bind "^[[6~" ed-search-next-history 2> "/dev/null" || true
			bind "\e[1;2A" ed-search-prev-history 2> "/dev/null" || true
			bind "\e[1;2B" ed-search-next-history 2> "/dev/null" || true
			bind "\e[a" ed-search-prev-history 2> "/dev/null" || true
			bind "\e[b" ed-search-next-history 2> "/dev/null" || true

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
			bind "\e[3;5~" em-delete-next-word 2> "/dev/null" || true
			bind "^?" ed-delete-prev-char 2> "/dev/null" || true
			bind "^H" ed-delete-prev-char 2> "/dev/null" || true
			bind "^W" ed-delete-prev-word 2> "/dev/null" || true
			bind "\ed" em-delete-next-word 2> "/dev/null" || true
			bind "\e^?" ed-delete-prev-word 2> "/dev/null" || true
			bind "\e^H" ed-delete-prev-word 2> "/dev/null" || true
			bind "\eb" ed-prev-word 2> "/dev/null" || true
			bind "\ef" em-next-word 2> "/dev/null" || true

			bind "\e[1;5C" em-next-word 2> "/dev/null" || true
			bind "\e[1;5D" ed-prev-word 2> "/dev/null" || true
			bind "\e[1;3C" em-next-word 2> "/dev/null" || true
			bind "\e[1;3D" ed-prev-word 2> "/dev/null" || true
			bind "\e[5C" em-next-word 2> "/dev/null" || true
			bind "\e[5D" ed-prev-word 2> "/dev/null" || true
			bind "\e\e[C" em-next-word 2> "/dev/null" || true
			bind "\e\e[D" ed-prev-word 2> "/dev/null" || true
			bind "\e[1;2C" em-next-word 2> "/dev/null" || true
			bind "\e[1;2D" ed-prev-word 2> "/dev/null" || true
			bind "\e[c" em-next-word 2> "/dev/null" || true
			bind "\e[d" ed-prev-word 2> "/dev/null" || true

			bind "^U" em-kill-line 2> "/dev/null" || true
			bind "^K" ed-kill-line 2> "/dev/null" || true
			bind "^Y" em-yank 2> "/dev/null" || true
			bind "^L" ed-clear-screen 2> "/dev/null" || true

			bind -s "\eOp" "0" 2> "/dev/null" || true
			bind -s "\eOq" "1" 2> "/dev/null" || true
			bind -s "\eOr" "2" 2> "/dev/null" || true
			bind -s "\eOs" "3" 2> "/dev/null" || true
			bind -s "\eOt" "4" 2> "/dev/null" || true
			bind -s "\eOu" "5" 2> "/dev/null" || true
			bind -s "\eOv" "6" 2> "/dev/null" || true
			bind -s "\eOw" "7" 2> "/dev/null" || true
			bind -s "\eOx" "8" 2> "/dev/null" || true
			bind -s "\eOy" "9" 2> "/dev/null" || true
			bind -s "\eOn" "." 2> "/dev/null" || true
			bind "\eOM" ed-newline 2> "/dev/null" || true
			bind -s "\eOj" "*" 2> "/dev/null" || true
			bind -s "\eOk" "+" 2> "/dev/null" || true
			bind -s "\eOl" "," 2> "/dev/null" || true
			bind -s "\eOm" "-" 2> "/dev/null" || true
			bind -s "\eOo" "/" 2> "/dev/null" || true
			;;
	esac
fi
