---
name: macos-shell
description: >-
  Deep technical reference and runbook for macOS (Darwin) shell environments, Homebrew prefix management
  (Apple Silicon vs Intel), GPL license freeze quirks (Bash 3.2), BSD coreutils differences, and macOS dark mode.
  Use when maintaining, developing, or auditing macOS-specific shell behaviors and path cascades.
---

# macOS (Darwin) Shell — Architecture, Homebrew & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades do subsistema Darwin e padrões de engenharia para o ecossistema **macOS** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. O Congelamento do Bash 3.2 e a Transição para o Zsh

1. **GPLv3 Embargo:**
   - A Apple interrompeu a atualização do GNU Bash no macOS na versão **3.2.57 (lançada em 2007)** para evitar a licença GPLv3.
   - O `/bin/bash` nativo do macOS não possui suporte a arrays associativos (`declare -A`), `globstar` (`**`), `read -t` moderno nem regex matches aprimorados.
2. **Zsh como Shell Padrão:**
   - A partir do macOS Catalina (10.15), o `/bin/zsh` (licenciado sob MIT/BSD-like) tornou-se o shell padrão oficial do sistema.
   - O Zsh no macOS é moderno e compatível com as convenções de alto desempenho do ecossistema.
3. **Bash Moderno via Homebrew:**
   - Caso o usuário utilize Bash no macOS, o executável deve vir do Homebrew (`/opt/homebrew/bin/bash` ou `/usr/local/bin/bash`).

---

## 2. Prefíxos Homebrew e Apple Silicon vs Intel

O caminho de binários do Homebrew varia conforme a arquitetura da CPU:

| Arquitetura               | Prefixo Base    | Binários de Usuário | Binários de Admin    |
| :------------------------ | :-------------- | :------------------ | :------------------- |
| **Apple Silicon (ARM64)** | `/opt/homebrew` | `/opt/homebrew/bin` | `/opt/homebrew/sbin` |
| **Intel (x86_64)**        | `/usr/local`    | `/usr/local/bin`    | `/usr/local/sbin`    |

### Regra de Injeção no `PATH`:

Utilize sempre a função canônica `path-front` de `library/functions.sh`:

```sh
[ -d "/opt/homebrew/bin" ] && path-front "/opt/homebrew/bin"
[ -d "/opt/homebrew/sbin" ] && path-front "/opt/homebrew/sbin"
```

Isso garante que ferramentas modernas do Homebrew tenham precedência sobre os binários BSD arcaicos em `/usr/bin`.

---

## 3. Armadilhas BSD Userland vs GNU Coreutils

O macOS utiliza ferramentas derivadas do BSD 4.4, com incompatibilidades sintáticas notórias com o Linux GNU:

1. **`sed -i` (Edição in-place):**
   - **macOS / BSD:** Exige um argumento de extensão de backup. Para editar sem backup: `sed -i '' 's/foo/bar/g' file`.
   - **Linux / GNU:** Não aceita aspas vazias como extensão: `sed -i 's/foo/bar/g' file`.
   - **Padrão Portável do Repositório:** Use reescrita atômica via redirecionamento temporário (`cat >|` ou `perl`/`python3`) em vez de `sed -i` em scripts compartilhados.
2. **`stat` (Metadados de arquivos):**
   - **macOS:** `stat -f %z file` (tamanho) ou `stat -f %m file` (mtime).
   - **Linux:** `stat -c %s file` ou `stat -c %Y file`.
3. **`readlink -f`:**
   - Inexistente ou sem suporte a `-f` no `readlink` padrão do macOS. Use `realpath` ou resolução canônica POSIX via `cd -P`.

---

## 4. Detecção de Dark Mode no macOS

No macOS, a preferência do sistema é capturada de forma limpa via comando `defaults`:

```sh
_is_dark_mode() {
    [ "$(command defaults read -g AppleInterfaceStyle 2> "/dev/null")" = "Dark" ]
}
```
