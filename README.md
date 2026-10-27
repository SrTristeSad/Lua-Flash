# Lua-Flash

**O Flash renasce em Lua** — plataforma independente de animações e jogos em Lua, sem retrocompatibilidade obrigatória com SWF, FLA, XFL ou ActionScript da Adobe.

## Projetos separados

| Aplicação | Diretório | Executar | Status |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.9 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.9: imagens animadas e áudio por quadro

O novo **LUAFGAME 6** estende nossos jogos `.lfgame` com:

- **Sequências de PNG:** alterna imagens de um sprite a cada quantidade configurada de quadros da timeline, inclusive quando o Player pausa, busca outro quadro ou ajusta a velocidade.
- **Efeitos WAV por quadro:** sons acontecem quando a reprodução avança sobre determinados quadros, respeitando pausa e repetição.
- **Compatibilidade:** jogos LUAFGAME 1–5 continuam abrindo e preservam seus dados.
- **Segurança:** recursos e ações continuam declarativos; jogos importados não executam scripts Lua externos.

Abra **PACOTE** para testar a demonstração com duas imagens originais e um efeito sincronizado aos quadros 23 e 45. O minijogo **JOGAR** anterior permanece disponível.

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e, na raiz do repositório:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.9.lfgame
```

O arquivo `dist/Lua-Flash-Player-0.9.love` precisa do LÖVE instalado (ainda não é um EXE). Builds de teste estão disponíveis nos artefatos do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [LUAFGAME 6](docs/FORMAT_LUAFGAME6.md) · [Roadmap](docs/ROADMAP.md).

Lua-Flash é independente, sem vínculo com a Adobe.
