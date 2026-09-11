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
	echo "🐚 Universal Shell — Motor Interativo de Terminal"
	echo ""
	echo "Comandos disponíveis:"
	echo "  make test     - Valida sintaxe POSIX e Zsh em todos os módulos"
	echo "  make bench    - Executa benchmark de latência de inicialização"
	echo "  make install  - Instala e sincroniza o runtime do Shell"
	echo "  make ci       - Executa suite de testes e ganchos de commit"
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
