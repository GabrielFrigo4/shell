# 🔮 PLANS — Ideias Avançadas & Roadmap de Performance Futura

> Este documento registra formalmente propostas e experimentos conceituais de otimização extrema e arquitetura de execução para o **Universal Shell Environment**. São ideias com alto potencial de ganho de desempenho mantidas em reserva para iterações futuras, sem aplicação imediata no código de produção para preservar a simplicidade, modularidade e estabilidade em todos os sistemas operacionais.

---

## 🏛️ 1. Compilação Antecipada de Bytecode no Zsh (`zcompile`)

### Conceito

O Zsh possui o comando builtin `zcompile [flags] <arquivo.zwc> <arquivo.sh>`, que gera uma imagem binária compilada em memória (wordcode). Quando um arquivo `.zwc` correspondente existe ao lado do script `.sh`, o Zsh mapeia o binário diretamente via `mmap(2)` do sistema operacional, pulando 100% da análise léxica e do parser sintático no momento de cada boot.

### Abordagem Mapeada

1. **Geração no Ciclo de Instalação:**
    - Durante o `install.sh` ou em um hook pós-instalação (`make compile`), varrer todos os módulos do repositório gerando os arquivos `.zwc`:
        ```zsh
        for _f in library/*.sh core/*.sh theme/*.sh target/**/*.sh; do
            [ -f "${_f}" ] && zcompile -U "${_f}"
        done
        ```
2. **Atualização Automática:**
    - Adicionar uma etapa no pre-commit ou na função `update-shell` para re-compilar os arquivos `.zwc` apenas quando os `.sh` forem modificados (verificação por timestamp com `test "${_sh}" -nt "${_zwc}"`).
3. **Limpeza e Fallback:**
    - Manter um target `make clean-compile` que execute `rm -f **/*.zwc` para fins de depuração.

### Ganhos Esperados

- Redução de ~25% a 35% na latência de parsing do Zsh, reduzindo o boot de ~17ms para ~12ms.

---

## 📦 2. Bundling de Runtime Monolítico Gerado (`runtime.bundle.sh`)

### Conceito

Atualmente, o processo de boot carrega de 5 a 8 arquivos `.sh` separados via múltiplos comandos `.` (source) e expansão de glob no disco (`for _f in library/*.sh core/*.sh; do . "${_f}"; done`). Cada arquivo exige chamadas de sistema separadas de `stat`, `openat`, `read` e `close`.

### Abordagem Mapeada

1. **Geração Estática do Monólito:**
    - No `install.sh`, concatenar de forma atômica e linear todos os módulos necessários para o SO e shell detectados em um único arquivo:
        - Local: `${XDG_CACHE_HOME:-${HOME}/.cache}/shell/runtime.${OS_NAME}.${TARGET_SHELL}.sh`
2. **Carregamento Otimizado com Fallback Transparente:**
    - O RC (`~/.zshrc`, `~/.bashrc`, `~/.shrc`, `~/.kshrc`) tenta carregar prioritariamente o bundle monolítico:
        ```sh
        _bundle="${XDG_CACHE_HOME:-${HOME}/.cache}/shell/runtime.sh"
        if [ -f "${_bundle}" ]; then
            . "${_bundle}"
        else
            # Fallback automático para o modo modular padrão em disco
            for _f in "${SHELL_REPO_DIR}/library/"*.sh; do [ -f "${_f}" ] && . "${_f}"; done
            for _f in "${SHELL_REPO_DIR}/core/"*.sh; do [ -f "${_f}" ] && . "${_f}"; done
            . "${SHELL_REPO_DIR}/target/${OS_NAME}/${SHELL_NAME}/prompt.sh"
        fi
        ```
3. **Invalidação de Cache:**
    - O bundle conteria no cabeçalho o hash SHA256 do commit ativo do repositório (`git rev-parse HEAD`), invalidando-se e regenerando-se automaticamente ao detectar discrepância.

### Ganhos Esperados

- Eliminação de 80% dos `stat` e `open` syscalls de disco, diminuindo o I/O para um único acesso atômico (< 8ms de boot time).

---

## ⚡ 3. Prompt de Git/Got Assíncrono com Background Workers

### Conceito

A renderização do status do Git/Got no prompt (`_git_branch` em `theme/*.sh`) pode sofrer latência perceptível em repositórios gigantes (com milhares de arquivos ou em discos lentos de rede/NFS).

### Abordagem Mapeada

1. **Worker ZLE Assíncrono (Zsh):**
    - Utilizar a biblioteca nativa `zsh/async` ou workers dedicados disparados em background pelo hook `precmd`.
    - O prompt é exibido instantaneamente com a última branch conhecida; quando o worker finaliza o cálculo de dirty status (`git status --porcelain`), ele envia um sinal `USR1` ou atualiza uma variável em memória e aciona `zle reset-prompt`.
2. **Coprocesso em Background (Bash):**
    - No Bash, utilizar um subshell desanexado com escrita atômica em arquivo temporário em `/tmp` ou no cache ramdisk, lido no próximo ciclo de prompt.

### Ganhos Esperados

- Tempo de renderização de prompt de estritamente **0.0ms** em qualquer diretório Git, eliminando pausas na digitação de comandos sucessivos.

---

> [!TIP]
> Ideias mantidas em reserva para preservação da elegância, auditabilidade e manutenção simples do repositório.
