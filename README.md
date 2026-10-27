# Lua-Flash

**Uma nova plataforma de animacao e jogos em Lua: Player e Studio separados.** Recuperamos o fluxo de criacao e execucao do Flash, mas nao implementamos compatibilidade com SWF, FLA, XFL ou ActionScript antigos.

## Pastas dos aplicativos

| Projeto | Pasta | Executar |
|---|---|---|
| **Player Lua** | [`player-lua/`](player-lua/) | `love player-lua` |
| **Studio Lua** | [`studio-lua/`](studio-lua/) | `love studio-lua` |

**O Player e o foco atual.** Abre uma demonstracao animada propria e arquivos `.lflash` arrastados para a janela. O Studio conserva as ferramentas de desenho, camadas, timeline e pre-visualizacao ja iniciadas.

Os dois projetos sao **apps LÖVE separados**, com pontos de entrada, janelas e pastas independentes. O codigo do modelo `.lflash` e o renderizador ficam espelhados em `player-lua/src/` e `studio-lua/src/`, com testes que impedem divergencias. A origem canonica nesta fase e o Player. Execute `python tools/sync_core.py` ao modificar esses arquivos.

## Requisitos e testes

- [LÖVE 11.5](https://love2d.org/) para rodar as interfaces de desktop.
- `lua tests/model_test.lua` para testes do formato e do relogio do runtime, a partir da raiz.
- `python tools/sync_core.py --check` para conferir sincronizacao dos modulos compartilhados.

Nao existe player de SWF nem interpretador de scripts Lua de terceiros nesta versao. Esta e a versao **0.1 experimental**, ainda sem homologacao grafica completa.

Veja [o plano tecnico](docs/ROADMAP.md) e a [analise historica do Flash Player](docs/ANALISE_FLASH_PLAYER_32.md). Projeto independente, sem afiliacao com a Adobe.
