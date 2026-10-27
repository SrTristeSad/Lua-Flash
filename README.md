# Lua-Flash

O **Flash renasce em Lua**: uma nova plataforma independente para criar, publicar e executar animações e jogos. Sem suporte a SWF, FLA, XFL ou ActionScript antigos da Adobe.

## Aplicativos

| Projeto | Pasta | Rodar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.4 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Novidade: jogos externos em formato próprio

O Player agora abre `.lfgame`: cenas `.lflash` mais regras de interação, como clique em objetos, teclas, pontuação, controle da timeline e objetivo de vitória. O formato é **declarativo e validado**: os jogos recebidos não executam scripts Lua arbitrários.

Clique em **PACOTE** para jogar o exemplo interno. Também é possível exportá-lo, arrastá-lo de volta para o Player ou criar um jogo simples a partir de um documento `.lflash` existente.

## Executar / gerar pacote

Instale [LÖVE 11.5](https://love2d.org/). Na raiz do repositório:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.4.lfgame
```

O script de empacotamento cria `dist/Lua-Flash-Player-0.4.love`. **O arquivo .love necessita do LÖVE instalado.**

As versões publicadas pelo [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) incluem o Player e exemplos `.lfgame`.

## Testes

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/input_test.lua
lua tests/package_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
```

Para criar seu próprio jogo simples, consulte [o manual do Player](player-lua/README.md). O [roadmap](docs/ROADMAP.md) define as próximas etapas.

O projeto é independente, sem vínculo com a Adobe. Interfaces e desempenho ainda precisam de avaliação manual em sistemas reais.
