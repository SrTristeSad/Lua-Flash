# Lua-Flash

O **Flash renasce em Lua**: plataforma independente para criar, publicar e executar jogos e animações próprios, sem compatibilidade obrigatória com os arquivos antigos da Adobe.

## Projetos separados

| Projeto | Pasta | Executar | Versão |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.5 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental (preservado) |

## Player 0.5

Além das animações `.lflash`, o Player abre jogos `.lfgame`. O novo **LUAFGAME 2** permite nomes para objetos clicáveis, estados locais, comandos `ADD`/`SET` e regras condicionais de pontuação. Os jogos v1 continuam funcionando. O Player nunca executa código Lua incluído em pacotes externos.

A demonstração **PACOTE** mostra como um objeto pode acumular toques e pontuar somente depois de uma condição. Também há minijogo tradicional (**JOGAR**) e importação de projetos por arrastar/soltar.

## Executar e testar

Instale [LÖVE 11.5](https://love2d.org/) para abrir o Player:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.5.lfgame
```

A saída é `dist/Lua-Flash-Player-0.5.love` (requer LÖVE) e um jogo de exemplo `.lfgame`. O [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) executa testes e publica os arquivos de demonstração como artefatos.

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Análise histórica](docs/ANALISE_FLASH_PLAYER_32.md).

Este projeto não é afiliado à Adobe.
