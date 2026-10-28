# Lua-Flash

**O Flash renasce em Lua** — runtime independente de animações e jogos com formatos próprios. Não executa SWF, FLA, XFL ou ActionScript antigos.

## Aplicativos separados

| Aplicativo | Diretório | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.19 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.19 — áudio polifônico com canais

A atualização introduz um **mixer de efeitos WAV**, com reprodução simultânea independente, separação entre sons de eventos e da timeline e limites previsíveis de recursos.

- **Até 16 vozes em memória e 4 vozes por WAV** para impedir crescimento descontrolado em jogos muito movimentados.
- **Categorias independentes:** `effects` para cliques, teclado, colisões e vitória; `timeline` para eventos programados por quadro.
- **F5** muda a categoria selecionada; **F6/F7** reduzem/aumentam seu volume; **F8/F9** controlam o volume geral; **F10** ativa/desativa o mudo.
- **F3** mostra número de fontes, vozes ativas, reutilizações e volume das duas categorias.
- **Timeline corrigida:** eventos sonoros são percorridos cronologicamente mesmo quando uma atualização atravessa mais de um loop completo, com teto de 64 disparos por atualização.
- Cada WAV é decodificado uma vez para `SoundData`; fontes adicionais são criadas conforme necessário, e vozes antigas são reutilizadas quando os limites são alcançados.

**Compatibilidade:** o formato continua **LUAFGAME 9**, mantendo os jogos LUAFGAME 1–9 e os projetos `.lflash`. O Studio foi mantido intacto; não há execução de scripts externos fornecidos pelos jogos.

## Executar e testar

Instale [LÖVE](https://love2d.org/) e execute:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.19.lfgame
```

O pacote `dist/Lua-Flash-Player-0.19.love` ainda exige LÖVE instalado, não sendo EXE Windows autônomo. Builds estão disponíveis nos artefatos do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [LUAFGAME 9](docs/FORMAT_LUAFGAME9.md).

Projeto independente e não afiliado à Adobe.
