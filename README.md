# Lua-Flash

**O Flash renasce em Lua** — Player independente para animações e jogos em formatos próprios. Não reproduz SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicativo | Pasta | Estado |
|---|---|---|
| [Player Lua](player-lua/) | `player-lua/` | **0.26 experimental** |
| [Studio Lua](studio-lua/) | `studio-lua/` | 0.1 experimental, preservado |

## Player 0.26 — textos ajustáveis e testes de resistência

A versão 0.26 acrescenta **três opções de tamanho de texto** (normal, grande e extra) para os controles e a interface do Player. Use **Ctrl + +** para aumentar, **Ctrl + -** para diminuir ou **Ctrl + 0** para restaurar o tamanho normal. As fontes são recriadas somente quando a opção muda, e a preferência é salva em `player-font-size.txt` na pasta de dados do LÖVE.

O texto dos botões, o painel de quadros-chave, mensagens e ajuda possuem ajustes de largura para reduzir sobreposições em janelas pequenas. Em casos extremos, rótulos compridos podem ser abreviados com reticências para manter a interface navegável. **F2** continua alternando o tema de alto contraste, de maneira independente da escolha da fonte.

Incluí uma **simulação determinística de 20 minutos de reprodução** com 72.000 atualizações a 60 Hz. O teste verifica loops, amostragem/interpolação, cache, crescimento de memória Lua e integridade do arquivo original. Essa simulação executa os quadros rapidamente na CI e **não é um benchmark de FPS/GPU real** nem substitui testes prolongados em computadores físicos.

Os formatos LUAFGAME 1–9 e animações `.lflash` continuam compatíveis. **O Studio não foi alterado**, e os arquivos de jogos importados não executam código Lua.

## Download e execução

Na [última execução aprovada do GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions), existem dois artefatos:

- **`lua-flash-player-0.26-windows-x64-portable`**: Windows x64, `Lua-Flash-Player.exe` com LÖVE 11.5 e DLLs; extrair o ZIP todo e executar o EXE. Não é necessário instalar LÖVE separadamente.
- **`lua-flash-player-0.26-love-and-game`**: arquivo `.love` e exemplos para sistemas com [LÖVE](https://love2d.org/) instalado.

O executável Windows continua experimental e **não possui assinatura digital**, portanto o SmartScreen pode exibir um aviso. A identificação nativa do EXE é **0.26.0.0**.

## Testar localmente

```bash
love player-lua
lua tests/text_scale_test.lua
lua tests/endurance_player_test.lua
lua tests/gui_smoke.lua
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente, sem vínculo com a Adobe.
