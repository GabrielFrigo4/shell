.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Shell Runtime Engine
# ----------------------------------------------------------------

.PHONY: help hooks bench test format prettier install ci clean

### ================================
### HELP & DOCUMENTATION
### ================================
help:
	_e=$$'\e'; \
	cmd() { printf "    $${_e}[36mmake %-22s$${_e}[0m %s\n" "$$1" "$$2"; }; \
	sec() { printf "\n  $${_e}[1;33m%s$${_e}[0m\n" "$$1"; }; \
	sub() { printf "  $${_e}[1;34m  ── %s ──$${_e}[0m\n" "$$1"; }; \
	printf "\n  $${_e}[1;37mUniversal Shell — Motor Interativo de Terminal & Ergonomia$${_e}[0m\n"; \
	printf "  ============================================================\n"; \
	sec "Setup & Ganchos:"; \
	cmd "hooks"          "Configura e aplica permissões canônicas em .githooks"; \
	sec "Instalação & Runtime:"; \
	cmd "install"        "Instala e sincroniza o runtime do Shell"; \
	sec "Desempenho & Benchmark:"; \
	cmd "bench"          "Mede latência de boot e módulos (alvo binário <64ms)"; \
	sec "Qualidade & Testes:"; \
	cmd "test"           "Valida sintaxe Zsh, Bash, POSIX sh e ksh em todos os módulos"; \
	cmd "format"         "Formata arquivos Markdown com Prettier"; \
	cmd "prettier"       "Formata arquivos Markdown com Prettier"; \
	cmd "clean"          "Remove artefatos temporários, caches e ambientes virtuais (.venv)"; \
	cmd "ci"             "Executa suíte completa de testes e quality gate local"; \
	echo ""

### ================================
### TESTING & BENCHMARK
### ================================
test:
	echo "🧪 Validando sintaxe dos scripts do Shell..."
	if command -v zsh > "/dev/null" 2>&1; then \
		find . -name "*.sh" -not -path "*/.git/*" -not -path "*/bash/*" -not -name "bash.sh" -exec zsh -n {} +; \
	fi
	if command -v bash > "/dev/null" 2>&1; then \
		find . -name "*.sh" -not -path "*/.git/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec bash -n {} +; \
	elif sh -c 'f-f() { :; }' 2> "/dev/null"; then \
		find . -name "*.sh" -not -path "*/.git/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec sh -n {} +; \
	fi
	if command -v ksh > "/dev/null" 2>&1; then \
		find target/openbsd/ksh target/common/ksh theme/ksh.sh -name "*.sh" -exec ksh -n {} +; \
	elif command -v oksh > "/dev/null" 2>&1; then \
		find target/openbsd/ksh target/common/ksh theme/ksh.sh -name "*.sh" -exec oksh -n {} +; \
	fi
	if command -v fish > "/dev/null" 2>&1; then \
		fish -n target/common/fish/aliases.fish; \
	fi
	echo "🔍 Validando variáveis e funções canônicas..."
	grep -q 'PYTHONPYCACHEPREFIX=' core/environment.sh || { echo "❌ PYTHONPYCACHEPREFIX ausente em core/environment.sh" >&2; exit 1; }
	for _a in l la ll lar llr; do \
		grep -qE "(alias $${_a}=|^$${_a}\(\))" core/environment.sh || { echo "❌ Comando/Alias $${_a} ausente em core/environment.sh" >&2; exit 1; }; \
	done
	if grep -q '^_shell_ls()' core/environment.sh; then \
		echo "🧪 Validando comportamento limpo em pipe (sem ANSI ou glifos Nerd Fonts)..."; \
		sh -c '. ./library/detect.sh 2> "/dev/null" && . ./core/environment.sh 2> "/dev/null"; \
			for _fn in l la ll lr lar llr; do \
				_out=$$("$${_fn}" core | cat); \
				[ -n "$${_out}" ] || { echo "❌ Saída vazia em $${_fn} | cat" >&2; exit 1; }; \
				printf "%s" "$${_out}" | python3 -c "import sys,re; s=sys.stdin.read(); sys.exit(1 if re.search(r\"\x1b\[|[\ue000-\uf8ff]\", s) else 0)" \
					|| { echo "❌ Escape ANSI ou glifo Nerd Font detectado em $${_fn} | cat" >&2; exit 1; }; \
			done; \
			_out=$$(c Makefile | cat); [ -n "$${_out}" ] && printf "%s" "$${_out}" | python3 -c "import sys,re; s=sys.stdin.read(); sys.exit(1 if re.search(r\"\x1b\[|[\ue000-\uf8ff]\", s) else 0)" || exit 1; \
			_out=$$(g test Makefile | cat); [ -n "$${_out}" ] && printf "%s" "$${_out}" | python3 -c "import sys,re; s=sys.stdin.read(); sys.exit(1 if re.search(r\"\x1b\[|[\ue000-\uf8ff]\", s) else 0)" || exit 1; \
			_out=$$(f core | cat); [ -n "$${_out}" ] && printf "%s" "$${_out}" | python3 -c "import sys,re; s=sys.stdin.read(); sys.exit(1 if re.search(r\"\x1b\[|[\ue000-\uf8ff]\", s) else 0)" || exit 1'; \
	fi
	echo "✅ Sintaxe e invariantes do Shell validadas com sucesso!"

prettier: format

format:
	echo "🎨 Formatando arquivos com Prettier..."
	if command -v prettier > "/dev/null" 2>&1; then \
		find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.jsonc" -o -name "*.yml" -o -name "*.yaml" -o -name "*.html" -o -name "*.css" \) \
			-not -path "*/OSS/*" -not -path "*/.git/*" -not -path "*/.venv/*" -not -path "*/node_modules/*" \
			-not -path "*/var/*" -not -path "*/tmp/*" -not -path "*/build/*" -not -path "*/dist/*" \
			-not -path "*/target/*" -not -path "*/.cache/*" \
			-exec prettier --write {} + 2> "/dev/null" || true; \
	elif command -v npx > "/dev/null" 2>&1; then \
		find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.jsonc" -o -name "*.yml" -o -name "*.yaml" -o -name "*.html" -o -name "*.css" \) \
			-not -path "*/OSS/*" -not -path "*/.git/*" -not -path "*/.venv/*" -not -path "*/node_modules/*" \
			-not -path "*/var/*" -not -path "*/tmp/*" -not -path "*/build/*" -not -path "*/dist/*" \
			-not -path "*/target/*" -not -path "*/.cache/*" \
			-exec npx --yes prettier --write {} + 2> "/dev/null" || true; \
	else \
		echo "⚠️ Prettier não encontrado para formatação."; \
	fi

bench:
	sh benchmark.sh

install:
	sh install.sh

hooks:
	echo "🪝 Configurando ganchos Git (.githooks)..."
	chmod 0755 .githooks/pre-commit .githooks/commit-msg 2> "/dev/null" || true
	git config core.hooksPath .githooks 2> "/dev/null" || true
	echo "  ✅ Shell: core.hooksPath -> .githooks"

ci: test
	sh .githooks/pre-commit
	echo "🚀 Shell pronto para produção e commits!"

### ================================
### CLEANUP
### ================================
clean:
	echo "🧹 Limpando artefatos temporários, caches e ambientes virtuais..."
	rm -rf .venv bin/ build/ dist/ .tmp/ *.log
	find . -type d -name "__pycache__" -exec rm -rf {} + 2> "/dev/null" || true
	echo "✅ Workspace limpo!"
