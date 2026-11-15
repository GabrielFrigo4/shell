# 📟 Windows Command Prompt (CMD) & Clink

> Perfil moderno para o Prompt de Comando do Windows com Clink e autocompletion Lua.

---

## 🎯 Finalidade

Este diretório provê scripts de inicialização, atalhos do teclado e autocompletion estilo GNU Readline para o **CMD** no Windows através do utilitário Clink e scripts Lua.

---

## 📂 Catálogo de Arquivos & Arquitetura Zero-Fork

| Arquivo                                  | Tipo             | Descrição                                                                                                  |
| :--------------------------------------- | :--------------- | :--------------------------------------------------------------------------------------------------------- |
| [`setup-profile.reg`](setup-profile.reg) | Registro Windows | Registra `"AutoRun"="\"%USERPROFILE%\\autorun.cmd\""` no Registro do Windows                               |
| [`autorun.cmd`](autorun.cmd)             | Script Batch     | Ignora subchamadas `/c`, injeta Clink (`--autorun --quiet` sem `--profile ~\clink`) e chama `profile.cmd`  |
| [`profile.cmd`](profile.cmd)             | Script Batch     | Inicializa ambiente interativo CMD e exporta `PYTHONPYCACHEPREFIX` para cache XDG isolado                  |
| [`profile.lua`](profile.lua)             | Script Lua Clink | Prompt Git assíncrono, bootstrap zero-`io.popen` (`os.getfileversion` + `os.globfiles`), histórico e `up*` |

### ⚡ Otimizações de Boot do Clink (`profile.lua`)

- **Zero `io.popen` na Inicialização:** Evita spawns síncronos bloqueantes durante o startup do prompt; resolve metadados Win32 via `os.getfileversion` e atualiza o cache `clink_winver.cache` assincronamente via `clink.promptcoroutine`.
- **Indexação Rápida de Comandos (`os.globfiles`):** Substitui chamadas externas lentas por varredura nativa em memória para descoberta de ferramentas no `PATH`.
- **AutoRun Isolado & `%LOCALAPPDATA%\clink`:** `autorun.cmd` preserva subshells não-interativos (`/c`), carrega scripts Lua diretamente de `%LOCALAPPDATA%\clink` sem passar `--profile ~\clink`, parametriza servidores via `PERSONAL_SERVER_*` / `VENTURE_SERVER_*` e redireciona Python bytecode via `PYTHONPYCACHEPREFIX`.

---

## 🚀 Como Usar no Windows

Execute no CMD ou via instalador MSYS2:

```cmd
reg import setup-profile.reg
```

```sh
sh install.sh -s cmd
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
