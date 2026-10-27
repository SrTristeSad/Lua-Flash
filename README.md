# Lua-Flash

**O Flash renasce em Lua:** uma plataforma independente de animações e jogos, sem executar SWF, FLA, XFL ou ActionScript antigos.

## Aplicações separadas

| Aplicação | Diretório | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.14 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.14 — curvas e edição de animação

O **LUAFGAME 9** acrescenta curvas de animação por trecho aos sprites da versão 0.13. Além de interpolação linear, há aceleração, desaceleração, aceleração/desaceleração, transição suave e quadros mantidos (STEP). A seleção da curva afeta a mesma pose usada pelo desenho, pelos cliques e pelas colisões.

**Novo painel visual:** ao abrir um jogo com trilhas de transformações (LUAFGAME 8 ou 9), pressione **E** para selecionar um sprite e seu trecho de quadros-chave. Clique em **CURVA** para alternar a interpolação ou pressione **C**. Salve com **Ctrl+S**: um jogo v8 editado é gravado em formato v9. Não é preciso modificar scripts.

Os jogos LUAFGAME 1–8 continuam aceitos sem migração obrigatória e os documentos `.lflash` continuam com o codec anterior. Arquivos recebidos são dados validados, nunca programas Lua externos.

## Executar e empacotar

Instale [LÖVE 11.5](https://love2d.org/) e execute na raiz:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.14.lfgame
```

A distribuição `dist/Lua-Flash-Player-0.14.love` exige o LÖVE instalado (não é um EXE autônomo). Os artefatos de teste estão no [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [LUAFGAME 9](docs/FORMAT_LUAFGAME9.md) · [Roadmap](docs/ROADMAP.md).

Projeto independente e não afiliado à Adobe.
