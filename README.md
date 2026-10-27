# Lua-Flash

**O Flash renasce em Lua** — uma nova plataforma independente para criar e executar animações e jogos, sem necessidade de compatibilidade com SWF, FLA, XFL ou ActionScript antigos.

## Projetos separados

| Aplicação | Pasta | Comando | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.7 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player Lua 0.7: imagens e sons de jogos

O Player passa a reconhecer o **LUAFGAME 4**, um pacote de dados que contém uma cena `.lflash`, regras de interação e recursos gráficos/sonoros internos. Imagens **PNG** podem ser sobrepostas ao palco; sons **WAV** podem tocar em eventos de clique, colisão e vitória.

O formato mantém compatibilidade de leitura com jogos `LUAFGAME 1`, `2` e `3`. Pacotes não executam scripts Lua externos.

O botão **PACOTE** abre uma demonstração com uma imagem e um efeito sonoro originais. **F10** silencia ou reativa os efeitos.

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e execute, na raiz do repositório:

```bash
love player-lua
```

Para montar uma distribuição `.love` independente do Studio e gerar um exemplo:

```bash
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.7.lfgame
```

A distribuição `dist/Lua-Flash-Player-0.7.love` **não é um EXE autônomo**: exige LÖVE instalado. Os arquivos estão disponíveis como artefatos nas execuções aprovadas do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Especificação LUAFGAME 4](docs/FORMAT_LUAFGAME4.md) · [Roadmap](docs/ROADMAP.md).

Lua-Flash é um projeto próprio, sem vínculo com a Adobe.
