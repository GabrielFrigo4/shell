# Shell

Configurações, aliases e prompts para todos os ambientes do sistema.

## Instalação

Você pode escolher o contexto do ambiente passando o parâmetro `--context` (opções: `desktop`, `server`, `container`). Por padrão, se não informado, assume `desktop`. Ou pode utilizar os scripts de atalho `install-desktop.sh`, `install-server.sh` e `install-container.sh`.

**Linux / FreeBSD / MacOS:**

```sh
sudo git clone "https://github.com/GabrielFrigo4/Shell" "/usr/local/share/shell"
sh "/usr/local/share/shell/install.sh" --context desktop
```

**MSYS2 (Windows):**

```sh
git clone "https://github.com/GabrielFrigo4/Shell" "${HOME}/.shell"
sh "${HOME}/.shell/install.sh" --context desktop
```

Reinicie o shell ou recarregue o RC manualmente:

```sh
. ~/.shrc
. ~/.bashrc
. ~/.zshrc
```

> O script detecta automaticamente o OS e o shell, e injeta as linhas de `source` no arquivo RC correto — tanto para o usuário atual como para o root.

## Estrutura

- **`os/`**: Prompts e aliases separados por Sistema Operacional (mantendo a experiência visual exata 1:1, como Pinguim, Demônio ou Windows).
- **`core/`**: Funções universais.
- **`context/`**: Inicializadores de ambiente.
  - **Desktop**: Com ferramentas ricas e configuração voltada para o uso pessoal.
  - **Server**: Mais enxuto, ideal para servidores em produção.
  - **Container**: Foco em contêineres e jails (LXC, Incus, Bastille), sendo uma versão idêntica ao servidor.
