---
name: deep-investigation
description: >-
  Deep root-cause technical investigation, official documentation research, and upstream source analysis.
  Use when diagnosing low-level bugs, kernel/parser discrepancies, or shell behaviors,
  always prioritizing primary official sources and the most current software versions.
---

# Deep Investigation — Primary Sources & Modern Upstream Analysis

Esta skill define o protocolo de investigação técnica de excelência no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

Quando nos deparamos com falhas obscuras, bugs de renderização de terminal, desvios de sintaxe de shell ou comportamentos inesperados do sistema operacional, **nunca devemos recorrer a adivinhações superficiais ou "correções mágicas" de tentativa e erro**.

---

## 1. Regra de Ouro: SEMPRE a Versão Mais Atual

1. **Nunca se Limite a Versões Obsoletas:**
   - Respostas de fóruns de 10 anos atrás, tutoriais de Linux legado ou documentações de versões descontinuadas frequentemente propagam limitações que já foram superadas há muito tempo.
   - Sempre verifique a versão em que o usuário ou ambiente de CI está operando (ex: **FreeBSD 15.1 / 15-CURRENT**, **POSIX Issue 8 (2024)**, **Bash 5.2+**, **Zsh 5.9+**).
2. **Consulte a Man Page Específica da Versão:**
   - Ao inspecionar manuais no FreeBSD, use sempre a versão ativa:
     - `https://man.freebsd.org/cgi/man.cgi?query=<cmd>&manpath=FreeBSD+15.1-RELEASE`
     - Não se limite a resultados genéricos que apontam para o FreeBSD 7, 8 ou 9.
3. **Acompanhe a Evolução de Padrões:**
   - Se o POSIX Issue 8 oficializou `$''` (ANSI-C Quoting), adote-o com confiança em vez de se prender a restrições do POSIX 2004 / 2008.

---

## 2. Hierarquia Estrita de Fontes Primárias

Ao realizar pesquisas técnicas ou investigar a causa raiz de um comportamento:

```
Nível 1: Código-Fonte Upstream (Ground Truth)
   ↳ Repositórios oficiais: freebsd-src (C/Kernel/Userland), Bash C sources, Zsh sources.

Nível 2: Documentação Oficial Ativa da Plataforma
   ↳ man.freebsd.org (15.1), man7.org (Linux), POSIX IEEE Std 1003.1 (Issue 8).

Nível 3: Release Notes e Commit Logs Upstream
   ↳ Histórico de commits no git oficial que introduziram ou alteraram o recurso.

Nível 4 (Apenas Contexto / Baixa Prioridade): Fóruns e Q&A
   ↳ StackOverflow, Reddit, blogs pessoais. Use apenas para encontrar pistas de palavras-chave,
     MAS NUNCA cite como verdade sem validar diretamente contra o Nível 1 ou Nível 2.
```

---

## 3. Protocolo de Investigação de Causa Raiz em 4 Passos

### Passo 1: Isolar a Falha e o Erro Literal
- Capture o texto exato do erro emitido pelo compilador, parser ou interpretador:
  - Ex: `./library/functions.sh: 27: Syntax error: Bad function name`.
  - Ex: `:[~] $ f@Vostro3520 (sh)` com cursor em cima da primeira letra.
- Não altere o código às cegas antes de entender a mensagem.

### Passo 2: Rastrear o Mecanismo Interno (Engenharia Reversa)
- Pergunte a si mesmo:
  - *Qual é o binário exato executando essa linha?* (Ex: `/bin/sh` no Ubuntu é `dash`, enquanto no FreeBSD é `FreeBSD sh`).
  - *Qual biblioteca está controlando o terminal?* (Ex: `libedit` no FreeBSD `sh` vs `readline` no Bash).
  - *Como o parser interpreta esse caractere?* (Ex: o hífen `-` na BNF POSIX de funções vs na BNF do FreeBSD `sh`).

### Passo 3: Confirmar na Documentação Oficial Atual
- Busque diretamente na documentação ou código-fonte da versão moderna:
  - Ex: Verificar `man sh` no FreeBSD 15.1 revelando suporte a `\[` e `\]` para sequências não-imprimíveis e `\e` para ESC.
  - Ex: Verificar `histedit.c` no repositório `freebsd-src` e encontrar `el_set(el, EL_PROMPT_ESC, getprompt, '\001')`.

### Passo 4: Documentar com Clareza e Evidências
- Ao explicar a solução para o usuário ou registrar nos princípios do repositório:
  - Apresente a causa mecânica exata.
  - Explique a diferença entre interpretadores e plataformas.
  - Demonstre a correção canônica baseada na fonte oficial.
