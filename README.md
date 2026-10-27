# Lua-Flash

**O Flash renasce em Lua** — uma plataforma independente para criar e executar animações e jogos, sem emular SWF, FLA, XFL ou ActionScript da Adobe.

## Projetos separados

| Aplicação | Diretório | Comando | Status |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.12 experimental — desenvolvimento atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.12 — sprites transformados

A novidade é o formato **LUAFGAME 7**, que incorpora transformações declarativas para sprites PNG: **rotação, escalas X/Y independentes e pivô configurável**. As mesmas transformações são utilizadas pelo desenho, pelo reconhecimento de cliques e pelas colisões com outros objetos.

A demonstração **PACOTE** agora mostra um sprite que acompanha um objeto animado com rotação de 45° e escala de 130%. Os formatos LUAFGAME 1–6 e os arquivos `.lflash` permanecem suportados.

**Os jogos recebidos continuam sendo apenas dados validados**: nenhum script Lua externo é executado.

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e, na raiz do projeto:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.12.lfgame
```

`dist/Lua-Flash-Player-0.12.love` requer o LÖVE instalado, não sendo um executável Windows nativo. Os arquivos são publicados como artefatos dos testes no [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [LUAFGAME 7](docs/FORMAT_LUAFGAME7.md) · [Roadmap](docs/ROADMAP.md)

Lua-Flash é um projeto independente, não afiliado à Adobe.
