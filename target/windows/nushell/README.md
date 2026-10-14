# 🦀 NuShell Configuration

> Configurações declarativas para o shell moderno baseado em pipelines estruturados NuShell.

---

## 🎯 Finalidade

Este diretório contém os arquivos de configuração do **NuShell**, definindo variáveis de ambiente, aliases, temas e integração com o Vault (`vault.nu`).

---

## 📂 Catálogo de Arquivos

| Arquivo                  | Tipo                 | Descrição                                           |
| :----------------------- | :------------------- | :-------------------------------------------------- |
| [`config.nu`](config.nu) | NuScript Declarativo | Configuração de atalhos, tabelas e temas do NuShell |
| [`env.nu`](env.nu)       | NuScript Declarativo | Variáveis de ambiente e carregamento do ecossistema |

---

## 🚀 Como Usar / Sincronizar

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

| Comando                     | Descrição                                                                      |
| :-------------------------- | :----------------------------------------------------------------------------- |
| `upgit [caminho]`           | Varre e atualiza recursivamente todos os repositórios Git (profundidade até 3) |
| `uped`                      | Atualiza a Suíte de Editores (`~/.emacs.d`, `helix`, `nvim`, `vimfiles`)       |
| `uprc` / `upprofile`        | Atualiza o Universal Profile e sincroniza dotfiles via `profile.sh` (MSYS2)    |
| `sync-profile`              | Sincroniza dotfiles via `profile.sh` (`--status`, `--pull`, `--dry-run`)       |
| `upvt`                      | Atualiza o repositório privado Universal Vault                                 |
| `vault-perms`               | Ajusta e endurece permissões de segurança do Vault (`icacls` / `chmod`)        |
| `upsh`                      | Atualiza o repositório Universal Shell                                         |
| `upall`                     | Orquestra atualização de sistema (`upsys`), Profile, Vault e Editores          |
| `upget` / `upscp` / `upcho` | Atualizadores de pacotes (Winget, Scoop e Chocolatey)                          |
| `upsys`                     | Atualiza Winget, Scoop e Chocolatey em lote                                    |
| `upwin`                     | Executa a atualização do Windows Update                                        |
