### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Interactive Key Bindings
### --------------------------------
if case "$-" in *i*) true;; *) false;; esac; then
	bind "^[[A" ed-search-prev-history
	bind "^[OA" ed-search-prev-history
	bind "^[[B" ed-search-next-history
	bind "^[OB" ed-search-next-history
	bind "^[[5~" ed-search-prev-history
	bind "^[[6~" ed-search-next-history

	bind "^R" em-inc-search-prev
	bind "^S" em-inc-search-next

	bind "^A" ed-move-to-beg
	bind "^E" ed-move-to-end
	bind "^[[H" ed-move-to-beg
	bind "^[OH" ed-move-to-beg
	bind "^[[1~" ed-move-to-beg
	bind "^[[7~" ed-move-to-beg
	bind "^[[F" ed-move-to-end
	bind "^[OF" ed-move-to-end
	bind "^[[4~" ed-move-to-end
	bind "^[[8~" ed-move-to-end

	bind "^[[3~" ed-delete-next-char
	bind "^W" ed-delete-prev-word
	bind "\ed" em-delete-next-word
	bind "\eb" ed-prev-word
	bind "\ef" em-next-word

	bind "\e[1;5C" em-next-word
	bind "\e[1;5D" ed-prev-word
	bind "\e[1;3C" em-next-word
	bind "\e[1;3D" ed-prev-word
	bind "\e[5C" em-next-word
	bind "\e[5D" ed-prev-word

	bind "^U" em-kill-line
	bind "^K" ed-kill-line
	bind "^Y" em-yank
	bind "^L" ed-clear-screen
fi
