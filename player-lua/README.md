# Lua-Flash Player 0.13 — animação de transformações

Runtime autoral em Lua com [LÖVE 11.5](https://love2d.org/). Abre animações `.lflash` e jogos declarativos `.lfgame`, inclusive os formatos LUAFGAME 1–8. Não abre SWF/ActionScript.

## Novo na 0.13

Agora os sprites podem ter sua própria sequência de *quadros-chave de transformação*, além da animação de PNGs da versão 0.9:

- **Posição:** deslocamentos X e Y em unidades do palco, adicionados à posição STATIC ou FOLLOW.
- **Rotação:** graus com interpolação pelo caminho mais curto entre dois keyframes. O pivô é herdado da transformação v7 ou, na ausência dela, fica no centro da imagem.
- **Escala:** valores X/Y em porcentagem, interpolados linearmente de forma independente.
- **Interação:** pintura, cliques e máscaras alfa usam a mesma transformação da posição atual da timeline.
- **Colisões:** a verificação temporal da versão 0.11 consulta as posições intermediárias dos sprites, aplicando também a transformação interpolada.

A interpolação acontece mesmo quando a interpolação visual das formas vetoriais está desligada; o parâmetro da animação de sprites é independente da opção de suavização de vetores.

A demonstração **PACOTE** exibe uma estrela PNG com movimento e variações de rotação e tamanho ao longo de 90 quadros. A animação da bola vetorial e os sons por quadro continuam disponíveis.

## Criar um jogo LUAFGAME 8

Após preparar um jogo v7 com sprites, defina uma sequência de quadros-chave:

```bash
lua tools/animate_transform.lua entrada.lfgame saida.lfgame 1 \
  1,0,0,0,100,100 \
  23,30,-45,90,150,85 \
  45,-20,30,180,75,150 \
  90,0,0,360,100,100
```

Depois do índice do sprite (`1`), cada parâmetro representa:

```text
frame,x,y,anguloGraus,escalaXPercent,escalaYPercent
```

As posições são deslocamentos em relação ao sprite original, não coordenadas absolutas; ângulo e escalas são valores absolutos. O arquivo original é preservado e o resultado pode ser arrastado para o Player.

O formato exige ao menos dois keyframes por sprite e o primeiro no quadro 1. Aceita até 64 trilhas e 128 quadros-chave por trilha, respeitando um limite total de 2.048 keyframes.

## Executar e testar

```bash
love player-lua
lua tests/package_v8_test.lua
lua tests/package_v7_test.lua
lua tests/swept_collision_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI verifica versões antigas, formatos inválidos, interações com PNG transformado, colisões com deslocamento e a inicialização gráfica do LÖVE real.

**Limitações:** a animação interpola linearmente posição/escala e o ângulo pelo arco mais curto; não há curvas Bézier ou easing configurável, rotação de formas vetoriais, hierarquia pai-filho, fusão de keyframes em GUI, máscara exata para colisão contínua ou EXE nativo. O Studio continua sem alterações.
