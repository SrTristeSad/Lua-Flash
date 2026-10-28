# Lua-Flash

**O Flash renasce em Lua** — plataforma própria para animações e jogos, sem emular SWF/FLA/ActionScript antigos.

## Aplicações independentes

| Aplicação | Pasta | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.16 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Player 0.16 — histórico, rotação/escala e recuperação

O editor de quadros-chave permite agora desfazer e refazer até **32 alterações**, ajustar **rotação** e **escala X/Y** sem comandos externos e criar uma **cópia de recuperação automática** após 12 segundos com mudanças ainda não salvas.

As operações compartilham o mesmo runtime gráfico e de colisões, preservando o formato **LUAFGAME 9**. O histórico registra apenas dados editáveis, sem repetir mídias PNG/WAV em memória.

Atalhos: **E** abre o painel; **Ctrl+Z** desfaz, **Ctrl+Y** ou **Ctrl+Shift+Z** refaz; **Ctrl+S** salva uma cópia; **Ctrl+R** abre a recuperação (apenas se a sessão atual não tiver edições pendentes). A recuperação fica em `player_recovery.lfgame` no diretório de dados do LÖVE.

Formatos LUAFGAME 1–9 e arquivos `.lflash` permanecem aceitos; nenhum jogo externo executa código Lua.

## Executar

Instale [LÖVE](https://love2d.org/) e execute:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.16.lfgame
```

O arquivo `dist/Lua-Flash-Player-0.16.love` exige LÖVE instalado (não é um executável Windows independente). As builds de teste estão disponíveis em [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md) · [Roadmap](docs/ROADMAP.md).

Projeto independente da Adobe.
