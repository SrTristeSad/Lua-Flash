# Lua-Flash Player 0.11 — colisões durante movimento

Runtime experimental em Lua + LÖVE 11.5 para reproduzir animações `.lflash` e jogos declarativos `.lfgame` nas versões LUAFGAME 1–6.

## O que mudou

**Colisões rápidas:** antes, o Player analisava somente a posição de destino de cada objeto após `love.update`. Uma bola podia atravessar uma barreira de um quadro para outro sem disparar `COLLIDE`. Agora a sessão calcula posições intermediárias ao longo do avanço real da linha do tempo, sem mudar os arquivos do jogo.

**Limite de trabalho:** o sistema usa até **80 subamostras temporais** por atualização, com pontos explícitos de entrada dos loops. O limite controla CPU, mas não garante detecção perfeita de todas as colisões extremamente rápidas. Continuam as máscaras alfa aproximadas da versão 0.10, limitadas por orçamento de amostragem.

**Sem eventos falsos por busca:** quando o jogador arrasta a timeline ou escolhe manualmente outro quadro, o motor só examina o quadro selecionado. Não considera que o objeto percorreu fisicamente todos os quadros entre origem e destino.

**Repetição e múltiplas voltas:** o relógio registra quantas vezes a reprodução atravessou a borda da timeline. Mesmo uma animação curta que complete duas voltas e termine no quadro inicial terá o percurso verificado. Sons WAV configurados para quadros específicos também consideram essas voltas. Um mesmo WAV ainda é reiniciado se um agendamento se repete na mesma atualização, sem mistura polifônica independente.

**Desempenho:** o conjunto de pares que têm regra de colisão é calculado uma vez ao abrir o jogo. A cena visual interpolada continua com cache pela posição consultada; máscaras PNG opacas são reutilizadas.

## Limitações

- Trata-se de **detecção temporal por amostragem**, não de colisão contínua matemática exata. Objetos muito rápidos ou estreitos ainda podem atravessar sem detecção.
- A precisão geométrica do alfa em larga escala continua sujeita ao limite de amostras do detector PNG.
- Não adiciona rotação, escala animada, áudio em streaming, scripts Lua externos ou IDs persistentes ao documento do Studio.
- Necessita de benchmarks e testes visuais em equipamentos reais.

## Executar / testar

Na raiz do repositório:

```bash
love player-lua
lua tests/swept_collision_test.lua
lua tests/player_test.lua
lua tests/package_v3_test.lua
lua tests/pixel_mask_test.lua
lua tests/package_v6_test.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI também executa os testes antigos, abre o Player com LÖVE no display virtual e publica `Lua-Flash-Player-0.11.love`.

A próxima etapa de desenvolvimento prevê transformações de sprites (rotação/escala) e suporte à colisão transformada. O Studio permanece separado.
