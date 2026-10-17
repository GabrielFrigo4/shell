# 📟 Windows Command Prompt (CMD) & Clink

> Perfil moderno para o Prompt de Comando do Windows com Clink e autocompletion Lua.

---

## 🎯 Finalidade

Este diretório provê scripts de inicialização, atalhos do teclado e autocompletion estilo GNU Readline para o **CMD** no Windows através do utilitário Clink e scripts Lua.

---

## 📂 Catálogo de Arquivos

| Arquivo                                  | Tipo             | Descrição                                               |
| :--------------------------------------- | :--------------- | :------------------------------------------------------ |
| [`profile.cmd`](profile.cmd)             | Script Batch     | Script executado ao abrir uma nova sessão do CMD        |
| [`autorun.cmd`](autorun.cmd)             | Script Batch     | Inicializador e bootstrap para parâmetro AutoRun do CMD |
| [`profile.lua`](profile.lua)             | Script Lua Clink | Integração do Clink com histórico avançado e Git prompt |
| [`setup-profile.reg`](setup-profile.reg) | Registro Windows | Injeção do `profile.cmd` no parâmetro `AutoRun` do CMD  |

---

## 🚀 Como Usar no Windows

Execute no CMD ou PowerShell:

```cmd
reg import setup-profile.reg
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
