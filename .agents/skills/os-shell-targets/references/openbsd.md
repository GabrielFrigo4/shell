# 🐡 OpenBSD Shell — Korn Shell (`ksh`) & Primitivas de Segurança

No OpenBSD, tanto usuários comuns quanto o `root` utilizam o **Public Domain Korn Shell (`/bin/ksh`)** como interpretador padrão do base system.

---

## 🐚 Alvo Interativo Exclusivo (`target/openbsd/ksh`)

1. O OpenBSD é o **único sistema operacional** com `ksh` suportado como alvo interativo nativo.
2. Não existe `target/openbsd/sh`, pois `/bin/sh` no OpenBSD é um hardlink para `/bin/ksh`.
3. A tríade de shells suportados no OpenBSD é `zsh`, `bash` e `ksh`.

---

## 🎨 Particularidades do Prompt no OpenBSD `ksh`

1. **Ausência de ANSI-C Quoting (`$''`):** O pdksh interpreta `$'\e'` literalmente como caracteres `$\e`.
2. **Captura Canônica de Escape via Hexadecimal:**
    ```sh
    _esc="$(printf '\x1b' 2>"/dev/null" || echo -n $'\x1b')"
    ```
3. **Delimitador de Largura Zero (`\x01`):** No `PS1` do OpenBSD `ksh`, qualquer sequência invisível ANSI **deve** ser delimitada pelo caractere de controle hexadecimal `\x01`:
    ```sh
    _color_bold="$(printf '\x01%s[1m\x01' "$_esc")"
    ```
    Sem esses delimitadores `\x01`, o editor de linha calcula incorretamente a largura da tela e quebra o cursor ao digitar comandos longos.

---

## 🛡️ Primitivas de Segurança: `pledge`, `unveil` & `doas`

- **`pledge(2)`:** Restringe chamadas de sistema (ex: `stdio`, `rpath`, `inet`). Se o comando tentar violar, o kernel encerra o processo com `SIGABRT`.
- **`unveil(2)`:** Oculta áreas do sistema de arquivos para o processo.
- **`doas`:** Substituto oficial do `sudo` no base system (`/etc/doas.conf`). A função `_as_root` testa prioritariamente `doas` antes de `sudo`.
- **Gerenciamento de Pacotes:** `pkg_add <pacote>` e `pkg_add -u` para atualização.
