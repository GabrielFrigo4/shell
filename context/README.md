# 🎯 context/ — Orquestração por Contexto de Uso

Esta pasta gerencia as especializações dinâmicas do **Universal Shell Environment** de acordo com a carga de trabalho ativa da máquina (`SHELL_CONTEXT`).

---

## 📁 Estrutura de Contextos

- 💻 **`desktop/`**: Estação de trabalho gráfica (Linux, FreeBSD, OpenBSD, NetBSD, illumos, macOS, Windows MSYS2) com editores de código (`nvim`, `code`, `zed`), atalhos de janelas Wayland/X11 e montagem de smartphones (`mount-device`).
- 🌐 **`server/`**: Máquinas de produção e servidores dedicados com aliases rápidos para administração de rede, serviços (`systemctl`, `svcs`, `rcctl`, `service`) e logs (`journalctl`, `/var/log/messages`, `/var/adm/messages`).
- 📦 **`container/`**: Ambientes de contêineres que compartilham o kernel hospedeiro (Linux namespaces/cgroups, FreeBSD Jails, Solaris/illumos Zones) com carregamento ultraleve e comandos mínimos (lembre-se: contêiner compartilha o kernel, não é máquina virtual!).
- 🧩 **`wsl/`**: Ambientes WSL2 integrados com o Windows nativo via `common.sh` (`clip`, `explorer.exe`, `powershell`) e `linux.sh` (`wslpath`, `win-path`, `wsl-path`, `cd-win`, `open-win`, `WSL_HOST_IP`, `wsl-drop-caches`).

---

## ⚙️ Contrato de Arquitetura em Duas Camadas

Dentro de cada contexto:

1. **`common.sh`**: Sourced primeiro. Exporta aliases e variáveis genéricas do contexto, independentes do sistema operacional.
2. **`{OS}.sh`** (ex: `linux.sh`, `freebsd.sh`, `openbsd.sh`, `netbsd.sh`, `illumos.sh`, `macos.sh`, `windows.sh`): Sourced em seguida. Adiciona comandos ou wrappers que utilizam binários exclusivos daquele kernel ou plataforma.

Consulte mais detalhes em **[docs/CONTEXTS.md](../docs/CONTEXTS.md)**.
