# Lua-Flash Player 0.27 — cache vetorial e CPU

Player experimental de jogos declarativos LUAFGAME 1–9 (`.lfgame`) e animações `.lflash` em Lua/LÖVE. O Studio é independente e não recebe modificações do Player.

## Cache de renderização por quadro

`src/render_cache.lua` indexa os números de quadros-chave de cada camada em ordem crescente. Para uma posição inteira, a busca binária escolhe a última chave cuja posição seja menor ou igual à posição desejada, preservando exatamente o comportamento de `Model.frame`.

Quando o mesmo quadro é desenhado novamente, uma pequena cena vetorial indexada é reutilizada. Cada quadro ativo referencia a lista de formas original; não é feita cópia do projeto nem criado um cache ilimitado para todos os quadros. O cache mantém somente a última cena, e a troca de arquivo reinicializa o índice.

Isso otimiza o modo **sem interpolação**, no qual antes o renderizador original percorria as chaves de todas as camadas. O modo interpolado mantém a implementação já existente, com busca binária por chave. O código compartilhado com o Studio não foi modificado.

Em um documento com K chaves por camada, a localização de uma chave muda de O(K) para O(log K) na primeira exibição do quadro, enquanto quadros repetidos reutilizam a cena. O trabalho de desenhar as formas continua proporcional à quantidade visível. Nenhum ganho de FPS específico é prometido.

O teste `tests/render_cache_test.lua` usa 18 camadas e 11.520 formas vetoriais; compara o resultado com `Model.frame`, verifica camadas invisíveis, quadros intermediários, reuso da mesma cena, reconstrução manual quando chaves são alteradas e passagem pelo renderizador LÖVE.

## Diagnóstico de CPU no F3

O módulo `src/perf_monitor.lua` armazena até **120 durações por tipo de callback** (`update` e `draw`). O painel **F3** mostra:

- Tempo médio e máximo recente, em milissegundos, gasto na atualização e desenho do lado do Lua;
- Quantidade de reconstruções e reutilizações de cenas vetoriais;
- FPS, memória Lua, recursos, máscaras e canais de áudio já disponíveis.

O cronômetro usa `love.timer.getTime()` quando há LÖVE real, com fallback `os.clock()` em simulações. Não representa tempo de apresentação da GPU nem mede VRAM, driver ou processamento assíncrono da placa de vídeo. Os registros são limitados para não crescerem indefinidamente.

## Testes e execução

```bash
lua tests/render_cache_test.lua
lua tests/perf_monitor_test.lua
lua tests/stress_player_test.lua
lua tests/endurance_player_test.lua
lua tests/gui_smoke.lua
python3 tools/package_player.py
```

A CI executa regressões LUAFGAME, o Player no LÖVE gráfico com display virtual e a build Windows x64. O executável portátil contém o LÖVE oficial 11.5, ícone próprio e metadados **0.27.0.0**. Não exige instalar LÖVE no PC, mas ainda não possui assinatura digital.

**Limitações:** benchmark e perfil de CPU/GPU/VRAM em computadores Windows físicos continuam pendentes. O cache exato pode ser reconstruído quando um documento for alterado, usando seu método `reindex`; o editor do Player atual altera trilhas de sprites, não chaves vetoriais da cena.

Os atalhos anteriores continuam: F1 ajuda, F2 alto contraste, F3 diagnóstico, E editor, Tab navegação, Ctrl+S salvar, Ctrl+Z/Y desfazer/refazer e Ctrl+mais/menos/zero alterar fonte.
