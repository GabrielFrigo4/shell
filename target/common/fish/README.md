# 🐟 Fish Shell Configuration

> Configuração e runtime universal para Fish Shell (`fish`) no ecossistema Universal Shell.

---

## 🎯 Finalidade

Este diretório provê o runtime interativo, prompt temático multiplataforma, biblioteca semântica de interface (`_ui_*`) e família de comandos de orquestração `up*` para o **Fish Shell**.

---

## 📂 Catálogo de Arquivos

| Arquivo                        | Tipo        | Descrição                                                                     |
| :----------------------------- | :---------- | :---------------------------------------------------------------------------- |
| [`config.fish`](config.fish)   | Fish Config | Inicialização do ambiente, detecção do `$SHELL_REPO_DIR` e prompt temático    |
| [`ui.fish`](ui.fish)           | Fish Script | Biblioteca semântica de emissão de status (`_ui_step`, `_ui_ok`, `_ui_warn`)  |
| [`updates.fish`](updates.fish) | Fish Script | Família completa de orquestração `up*` (`upsh`, `upvt`, `uped`, `uprc`, etc.) |

---

## 🚀 Como Usar / Sincronizar

O script de instalação do Universal Shell (`Shell/install.sh`) sincroniza automaticamente esta configuração para o caminho canônico do usuário:

```sh
# Via instalador oficial:
./install.sh -s fish

# Ou manualmente via link simbólico:
mkdir -p ~/.config/fish
ln -sf "$(pwd)/config.fish" ~/.config/fish/config.fish
```

---

## ⚡ Comandos da Família `up*`

| Comando                   | Descrição                                                                      |
| :------------------------ | :----------------------------------------------------------------------------- |
| `update-shell` / `upsh`   | Atualiza o repositório Universal Shell via git pull resiliente e recarrega     |
| `update-vault` / `upvt`   | Sincroniza o cofre criptográfico Universal Vault e recarrega chaves SSH        |
| `update-editors` / `uped` | Atualiza a Suíte de Editores (`~/.emacs.d`, `helix`, `nvim`, `vimfiles`)       |
| `update-profile` / `uprc` | Atualiza o Universal Profile e reaplica sincronização de dotfiles              |
| `update-git` / `upgit`    | Varre e atualiza recursivamente todos os repositórios Git (profundidade até 3) |
| `update-all` / `upall`    | Orquestra atualização de sistema e repositórios do ecossistema                 |
