# 💙 PowerShell Profiles

> Perfis avançados para PowerShell Core (`pwsh`) e Windows PowerShell nativo.

---

## 🎯 Finalidade

Este diretório provê scripts de inicialização, atalhos, funções auxiliares e integração de variáveis de ambiente para o **PowerShell** em Windows, Linux e macOS.

---

## 📂 Catálogo de Arquivos

| Arquivo                                                                | Tipo              | Descrição                                                    |
| :--------------------------------------------------------------------- | :---------------- | :----------------------------------------------------------- |
| [`profile.ps1`](profile.ps1)                                           | PowerShell Script | Perfil completo com atalhos, carregamento do Vault e funções |
| [`Microsoft.PowerShell_profile.ps1`](Microsoft.PowerShell_profile.ps1) | PowerShell Script | Wrapper de redirecionamento canônico                         |

---

## 🚀 Como Usar / Sincronizar

### Windows:

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE)
Copy-Item "profile.ps1" $PROFILE -Force
```

---

## ⚡ Comandos e Atualizadores da Família `up*`

| Comando                     | Descrição                                                                       |
| :-------------------------- | :------------------------------------------------------------------------------ |
| `upgit [caminho]`           | Varre e atualiza recursivamente todos os repositórios Git (profundidade até 3)  |
| `uped`                      | Atualiza a Suíte de Editores (`~/.emacs.d`, `helix`, `nvim`, `vimfiles`)        |
| `uprc` / `upprofile`        | Atualiza o Universal Profile e sincroniza dotfiles via `profile.sh` (MSYS2)     |
| `sync-profile`              | Sincroniza dotfiles via `profile.sh` (`-Status`, `-Pull`, `-DryRun`, `-Backup`) |
| `upvt`                      | Atualiza o repositório privado Universal Vault                                  |
| `vault-perms`               | Ajusta e endurece permissões de segurança do Vault (`icacls` / `chmod`)         |
| `upsh`                      | Atualiza o repositório Universal Shell                                          |
| `upall`                     | Orquestra atualização de sistema (`upsys`), Profile, Vault e Editores           |
| `upget` / `upscp` / `upcho` | Atualizadores de pacotes (Winget, Scoop e Chocolatey)                           |
| `upsys`                     | Atualiza Winget, Scoop e Chocolatey em lote                                     |
| `upwin`                     | Executa a atualização do Windows Update                                         |
