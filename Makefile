.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Shell Runtime Engine
# ----------------------------------------------------------------

.PHONY: help hooks bench test format install ci

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
		find target/openbsd/ksh target/common/ksh.sh theme/ksh.sh -name "*.sh" -exec ksh -n {} +; \
	elif command -v oksh > "/dev/null" 2>&1; then \
		find target/openbsd/ksh target/common/ksh.sh theme/ksh.sh -name "*.sh" -exec oksh -n {} +; \
	fi
	echo "✅ Sintaxe de todos os módulos de shell validada com sucesso!"

format:
	if command -v prettier > "/dev/null" 2>&1; then \
		prettier --write "**/*.md"; \
	elif command -v npx > "/dev/null" 2>&1; then \
		npx prettier --write "**/*.md"; \
	else \
		echo "⚠️ Prettier não encontrado para formatação de Markdown."; \
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
