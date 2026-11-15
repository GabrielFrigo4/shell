# 💙 PowerShell Profiles

> Perfis avançados para PowerShell Core (`pwsh`) e Windows PowerShell nativo.

---

## 🎯 Finalidade

Este diretório provê scripts de inicialização, atalhos, funções auxiliares e integração de variáveis de ambiente para o **PowerShell** em Windows, Linux e macOS.

---

## 📂 Catálogo de Arquivos & Arquitetura Zero-Fork

| Arquivo                                                                | Tipo              | Descrição                                                                                  |
| :--------------------------------------------------------------------- | :---------------- | :----------------------------------------------------------------------------------------- |
| [`Microsoft.PowerShell_profile.ps1`](Microsoft.PowerShell_profile.ps1) | PowerShell Script | Entrypoint veloz: `.NET` Registry, `_Test-ModuleInPath`, prompt e lazy Chocolatey          |
| [`profile.ps1`](profile.ps1)                                           | PowerShell Script | Runtime completo (`PYTHONPYCACHEPREFIX`, `_Find-PathCommands`, Vault, `Set-Alias` e `up*`) |

### ⚡ Otimizações de Boot & Segurança

- **Metadados do SO via .NET (Zero Fork):** Consulta versão/build do Windows diretamente via `[Microsoft.Win32.Registry]::GetValue(...)` em memória, eliminando spawns de `reg.exe` ou `wmic`.
- **Sondagem Rápida de Módulos (`_Test-ModuleInPath`):** Verifica `Terminal-Icons` e `PSReadLine` diretamente nos diretórios de `$env:PSModulePath`, evitando a varredura lenta de `Get-Module -ListAvailable`.
- **Lazy Loading de Chocolatey:** O wrapper `Update-SessionEnvironment` / `refreshenv` importa `chocolateyProfile.psm1` apenas na primeira invocação, mantendo o boot instantâneo.
- **Aliasing Antifrágil & Cache Python:** Utiliza `Set-Alias -Force -Option AllScope` (evitando recursão circular case-insensitive como `Clean-System`), descobre ferramentas Rust via `_Find-PathCommands`, define `$env:PYTHONPYCACHEPREFIX` (`${XDG_CACHE_HOME:-${HOME}/.cache}/pycache`) e parametriza servidores remotos via `$env:PERSONAL_SERVER_*` / `$env:VENTURE_SERVER_*`.

---

## 🚀 Como Usar / Sincronizar

```sh
sh install.sh -s pwsh
```

### Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE)
Copy-Item "profile.ps1" $PROFILE -Force
```

---

## ⚡ Comandos e Atualizadores da Família `up*`

| Comando                                                   | Descrição                                                                       |
| :-------------------------------------------------------- | :------------------------------------------------------------------------------ |
| `upgit [caminho]`                                         | Varre e atualiza recursivamente todos os repositórios Git (profundidade até 3)  |
| `uped`                                                    | Atualiza a Suíte de Editores (`~/.emacs.d`, `helix`, `nvim`, `vimfiles`)        |
| `uprc` / `upprofile`                                      | Atualiza o Universal Profile e sincroniza dotfiles via `profile.sh` (MSYS2)     |
| `sync-profile`                                            | Sincroniza dotfiles via `profile.sh` (`-Status`, `-Pull`, `-DryRun`, `-Backup`) |
| `upvt`                                                    | Atualiza o repositório privado Universal Vault                                  |
| `vault-perms`                                             | Ajusta e endurece permissões de segurança do Vault (`icacls` / `chmod`)         |
| `upsh`                                                    | Atualiza o repositório Universal Shell                                          |
| `upall`                                                   | Orquestra atualização de sistema (`upsys`), Profile, Vault e Editores           |
| `upget` / `upscp` / `upcho`                               | Atualizadores de pacotes (Winget, Scoop e Chocolatey)                           |
| `upsys`                                                   | Atualiza Winget, Scoop e Chocolatey em lote                                     |
| `clean-system` / `cleansys` / `clearsys` / `clear-system` | Limpeza de caches de pacotes e dependências obsoletas (Scoop, Chocolatey)       |
| `upwin`                                                   | Executa a atualização do Windows Update                                         |
