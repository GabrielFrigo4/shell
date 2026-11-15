# 🦀 NuShell Configuration

> Configurações declarativas para o shell moderno baseado em pipelines estruturados NuShell.

---

## 🎯 Finalidade

Este diretório provê scripts de inicialização, atalhos, funções auxiliares e integração de variáveis de ambiente para o **NuShell** em Windows, Linux e macOS.

---

## 📂 Catálogo de Arquivos & Arquitetura Nativa

| Arquivo                  | Tipo                 | Descrição                                                                                                         |
| :----------------------- | :------------------- | :---------------------------------------------------------------------------------------------------------------- |
| [`env.nu`](env.nu)       | NuScript Declarativo | `$env.ENV_CONVERSIONS` dual (`PATH`/`Path`), `registry query --hklm`, `PYTHONPYCACHEPREFIX` e `EMACS_SOCKET_NAME` |
| [`config.nu`](config.nu) | NuScript Declarativo | Prompt de 3 linhas, atalhos, carregamento do Vault (`PERSONAL_SERVER_*`/`VENTURE_SERVER_*`) e `up*`               |

### ⚡ Otimizações & Paridade Win32

- **Sincronização Dual de PATH (`$env.ENV_CONVERSIONS`):** Converte e sincroniza simultaneamente `$env.PATH` e `$env.Path`, evitando divergências entre executáveis nativos Win32, wrappers MSYS2 e pipelines do NuShell.
- **Leitura Nativa de Registro (0ms):** Consulta metadados do Windows via builtin `registry query --hklm` (com fallback transparente para `reg.exe`), mantendo o boot instantâneo.
- **Cache Python & Emacs:** Exporta `$env.PYTHONPYCACHEPREFIX` (`$env.XDG_CACHE_HOME/pycache` ou `~/.cache/pycache`) e `$env.EMACS_SOCKET_NAME`, além de sincronizar perfis cruzados (PowerShell, NuShell e Clink) via `upsh`.

---

## 🚀 Como Usar / Sincronizar

```sh
sh install.sh -s nu
```

### Linux, FreeBSD & macOS:

```sh
mkdir -p "${HOME}/.config/nushell"
ln -sf "$(pwd)/config.nu" "${HOME}/.config/nushell/config.nu"
ln -sf "$(pwd)/env.nu" "${HOME}/.config/nushell/env.nu"
```

### Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force -Path "$env:APPDATA\nushell"
New-Item -ItemType SymbolicLink -Force -Path "$env:APPDATA\nushell\config.nu" -Target "$((Get-Location).Path)\config.nu"
New-Item -ItemType SymbolicLink -Force -Path "$env:APPDATA\nushell\env.nu" -Target "$((Get-Location).Path)\env.nu"
```

---

## ⚡ Comandos e Atualizadores da Família `up*`

| Comando                                                   | Descrição                                                                      |
| :-------------------------------------------------------- | :----------------------------------------------------------------------------- |
| `upgit [caminho]`                                         | Varre e atualiza recursivamente todos os repositórios Git (profundidade até 3) |
| `uped`                                                    | Atualiza a Suíte de Editores (`~/.emacs.d`, `helix`, `nvim`, `vimfiles`)       |
| `uprc` / `upprofile`                                      | Atualiza o Universal Profile e sincroniza dotfiles via `profile.sh` (MSYS2)    |
| `sync-profile`                                            | Sincroniza dotfiles via `profile.sh` (`--status`, `--pull`, `--dry-run`)       |
| `upvt`                                                    | Atualiza o repositório privado Universal Vault                                 |
| `vault-perms`                                             | Ajusta e endurece permissões de segurança do Vault (`icacls` / `chmod`)        |
| `upsh`                                                    | Atualiza o repositório Universal Shell                                         |
| `upall`                                                   | Orquestra atualização de sistema (`upsys`), Profile, Vault e Editores          |
| `upget` / `upscp` / `upcho`                               | Atualizadores de pacotes (Winget, Scoop e Chocolatey)                          |
| `upsys`                                                   | Atualiza Winget, Scoop e Chocolatey em lote                                    |
| `clean-system` / `cleansys` / `clearsys` / `clear-system` | Limpeza de caches de pacotes e dependências obsoletas (Scoop, Chocolatey)      |
| `upwin`                                                   | Executa a atualização do Windows Update                                        |
