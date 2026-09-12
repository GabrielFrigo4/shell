.POSIX:
.SILENT:

MAKEFLAGS += --no-print-directory -s

# ----------------------------------------------------------------
# Makefile: Shell Runtime Engine
# ----------------------------------------------------------------

.PHONY: help bench test install ci

### ================================
### HELP & DOCUMENTATION
### ================================
help:
	cmd() { printf "    \033[36mmake %-20s\033[0m %s\n" "$$1" "$$2"; }; \
	sec() { printf "\n  \033[1;33m%s\033[0m\n" "$$1"; }; \
	sub() { printf "  \033[1;34m  ── %s ──\033[0m\n" "$$1"; }; \
	printf "\n  \033[1;37mUniversal Shell — Motor Interativo de Terminal & Ergonomia\033[0m\n"; \
	printf "  ============================================================\n"; \
	sec "Instalação & Runtime:"; \
	cmd "install"        "Instala e sincroniza o runtime do Shell"; \
	sec "Desempenho & Benchmark:"; \
	cmd "bench"          "Mede latência de boot e módulos (alvo rigoroso <50ms)"; \
	sec "Qualidade & Testes:"; \
	cmd "test"           "Valida sintaxe POSIX e Zsh em todos os módulos"; \
	cmd "ci"             "Executa suíte completa de testes e quality gate local"; \
	echo ""

### ================================
### TESTING & BENCHMARK
### ================================
test:
	echo "🧪 Validando sintaxe dos scripts do Shell..."
	find . -name "*.sh" -not -path "*/.git/*" -exec sh -n {} +
	echo "✅ Sintaxe de todos os módulos de shell validada com sucesso!"

bench:
	sh scripts/benchmark.sh

install:
	sh install.sh

ci: test
	sh .githooks/pre-commit
	echo "🚀 Shell pronto para produção e commits!"
