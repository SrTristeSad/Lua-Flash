# Lua-Flash

O **Flash renasce em Lua** — uma nova plataforma para criar e executar jogos e animacoes com arquivos e runtime proprios. Sem suporte legado a SWF, FLA, XFL ou ActionScript da Adobe.

## Aplicativos separados

| Aplicativo | Pasta | Inicializacao | Situacao |
|---|---|---|---|
| **Player Lua** | [`player-lua/`](player-lua/) | `love player-lua` | **0.2 experimental — foco atual** |
| **Studio Lua** | [`studio-lua/`](studio-lua/) | `love studio-lua` | 0.1 experimental, preservado |

O Player agora possui motor de transporte proprio, abertura de `.lflash`, velocidade 0,25–4×, repeticao, navegacao por quadros, tela cheia e **interpolacao opcional de formas** entre quadros-chave compativeis. A demonstracao nativa usa cinco quadros-chave.

O Studio foi preservado em pasta independente. Os dois aplicativos compartilham formato de documento e renderizador Lua, verificados com `python tools/sync_core.py --check`.

## Executar o Player

Instale [LÖVE 11.5](https://love2d.org/) e rode a partir da raiz:

```bash
love player-lua
```

Para construir o pacote `.love` independente do Studio:

```bash
python3 tools/package_player.py
```

O arquivo resultante sera `dist/Lua-Flash-Player-0.2.love`. Voce pode abri-lo com LÖVE; **nao e um executavel Windows autonomo**. O GitHub Actions tambem publica um pacote de teste na pagina de cada execucao bem-sucedida. Consulte o [manual do Player](player-lua/README.md).

## Testes

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
```

O GitHub Actions executa sintaxe e testes automaticamente; as interfaces ainda precisam de avaliacao visual em LÖVE de verdade. Codigos Lua de terceiros nao sao carregados por arquivos `.lflash`.

[Roadmap](docs/ROADMAP.md) · [Referencia historica Flash Player](docs/ANALISE_FLASH_PLAYER_32.md)

O Lua-Flash e independente e nao e afiliado a Adobe.
