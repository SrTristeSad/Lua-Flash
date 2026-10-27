# Lua-Flash

**O Flash renasce em Lua** — uma plataforma independente para criar e executar animações e jogos próprios, sem necessidade de abrir arquivos SWF, FLA, XFL ou ActionScript antigos.

## Projetos independentes

| Projeto | Pasta | Executar | Versão |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.8 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Player 0.8: sprites interativos

O Player introduz **LUAFGAME 5**: imagens PNG incorporadas aos jogos agora podem ser associadas a objetos nomeados e disparar regras de clique e de colisão. Uma imagem pode ficar fixa (`STATIC`) ou acompanhar o centro de um objeto ao longo da animação (`FOLLOW`).

O Player mantém os formatos antigos `LUAFGAME 1–4`, o áudio WAV acionado por eventos e as ferramentas de publicação próprias. **Pacotes recebidos são dados, nunca scripts Lua executados diretamente.**

A demonstração **PACOTE** usa um PNG que segue a bola animada, com sons de clique/colisão e controles de volume (F8/F9/F10).

## Executar e testar

Instale [LÖVE 11.5](https://love2d.org/) e, na raiz do repositório:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.8.lfgame
```

A distribuição `dist/Lua-Flash-Player-0.8.love` não é um EXE autossuficiente: requer LÖVE. Consulte os artefatos aprovados no [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Especificação LUAFGAME 5](docs/FORMAT_LUAFGAME5.md) · [Roadmap](docs/ROADMAP.md)

Este projeto não é afiliado à Adobe.
