# Lua-Flash

**O Flash renasce em Lua** — runtime independente de animações e jogos com formatos próprios, sem compatibilidade com SWF, FLA, XFL ou ActionScript antigos.

## Aplicações independentes

| Aplicação | Pasta | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.15 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.15 — edição visual de quadros-chave

O Player já tinha um painel para alterar curvas de animação. Agora ele também permite **inserir, mover e excluir quadros-chave**, alterar os deslocamentos X/Y por botões ou **arrastar o próprio sprite no palco**. As alterações aparecem imediatamente em desenho, hit-testing e colisões e podem ser salvas com **Ctrl+S**.

O mecanismo protege a chave inicial no quadro 1, os limites de posição/tempo, a ordem das chaves e referências de easing; edições inválidas são recusadas sem corromper a sessão.

**Não foi necessário alterar o formato**: continua sendo LUAFGAME 9. Jogos LUAFGAME 1–9 abrem normalmente e os documentos `.lflash` permanecem intactos. Jogos importados nunca executam scripts Lua externos.

## Executar

Instale [LÖVE 11.5](https://love2d.org/), depois:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.15.lfgame
```

O `dist/Lua-Flash-Player-0.15.love` requer LÖVE instalado, não sendo um EXE Windows autônomo. O [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) publica o Player e jogos de demonstração em ZIP.

[Manual do Player](player-lua/README.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md) · [Roadmap](docs/ROADMAP.md).

Projeto independente, não afiliado à Adobe.
