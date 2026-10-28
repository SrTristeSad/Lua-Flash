# Lua-Flash

**O Flash renasce em Lua** — Player de jogos e animações com formatos próprios, sem execução de SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicativo | Pasta | Estado |
|---|---|---|
| [Player Lua](player-lua/) | `player-lua/` | **0.27 experimental** |
| [Studio Lua](studio-lua/) | `studio-lua/` | 0.1 experimental, preservado |

## Player 0.27 — renderização indexada e monitoramento de CPU

A versão 0.27 acelera a reprodução **vetorial por quadros exatos**. As chaves de cada camada são indexadas na abertura do projeto, permitindo encontrar o quadro ativo por **busca binária** em vez de percorrer todas as chaves a cada desenho. O resultado da busca de um quadro é reutilizado enquanto ele permanece na tela.

A cena cacheada referencia as formas originais e **não altera os dados do projeto**. Abrir outro arquivo cria um índice novo. A interpolação suave já possuía busca binária própria e permanece com seu renderizador; colisões, áudio e edição conservam a lógica anterior.

O painel **F3** agora mostra quantas cenas vetoriais foram montadas/reutilizadas e amostras de **tempo de CPU para desenho e atualização**. As médias e picos recentes ficam num histórico circular limitado a 120 amostras por categoria. São métricas do lado Lua, **não tempos exclusivos de GPU**.

Adicionamos um teste de correção com **18 camadas, 32 chaves por camada e 20 formas por chave (11.520 formas)**; ele compara a seleção do índice com `Model.frame`, verifica reutilização, invalidação e desenho LÖVE simulado. Há também um teste de 40.000 amostras de CPU para confirmar que os diagnósticos não acumulam memória indefinidamente.

Formatos **LUAFGAME 1–9** e animações `.lflash` continuam compatíveis. **O Studio não foi modificado**.

## Downloads

A execução verde no [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) oferece:

- **`lua-flash-player-0.27-windows-x64-portable`**: ZIP portátil do Windows com o `Lua-Flash-Player.exe` e as DLLs do LÖVE 11.5 incluídas, sem instalação separada do LÖVE;
- **`lua-flash-player-0.27-love-and-game`**: pacote `.love` e exemplos para computadores com [LÖVE](https://love2d.org/) instalado.

O executável Windows não é assinado digitalmente e pode gerar aviso SmartScreen. O recurso de versão Windows é **0.27.0.0**. Antes de declarar a versão 1.0 estável, serão necessários testes em hardware físico e medições reais de GPU.

## Testar

```bash
love player-lua
lua tests/render_cache_test.lua
lua tests/perf_monitor_test.lua
lua tests/stress_player_test.lua
lua tests/endurance_player_test.lua
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente da Adobe.
