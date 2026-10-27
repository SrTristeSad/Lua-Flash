# Lua-Flash

**O Flash renasce em Lua** — plataforma independente para criar e executar animações e jogos com formatos próprios. Não emula SWF, FLA, XFL ou ActionScript antigos.

## Projetos

| Aplicação | Pasta | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.13 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.13 — sprites animados por quadros-chave

O **LUAFGAME 8** permite definir *quadros-chave próprios para sprites* com **deslocamento, rotação e escalas X/Y**, interpolados de acordo com a posição na timeline. O sprite continua podendo acompanhar uma forma vetorial via `FOLLOW`, mas agora pode receber seu próprio movimento adicional.

Os cliques, a verificação do alfa, as colisões e a renderização usam o mesmo estado interpolado. O algoritmo de rotação utiliza o caminho angular mais curto entre keyframes, enquanto ângulo e escala permanecem definidos em dados validados.

Jogos LUAFGAME 1–7 e animações `.lflash` continuam abrindo sem conversão obrigatória. Nenhum pacote executa Lua externo.

## Rodar ou gerar pacote

Instale [LÖVE 11.5](https://love2d.org/).

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.13.lfgame
```

`dist/Lua-Flash-Player-0.13.love` ainda exige LÖVE instalado; não é um EXE autossuficiente. Veja o [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) para pacotes de teste.

[Manual do Player](player-lua/README.md) · [Especificação LUAFGAME 8](docs/FORMAT_LUAFGAME8.md) · [Roadmap](docs/ROADMAP.md).

Projeto independente, sem vínculo com a Adobe.
