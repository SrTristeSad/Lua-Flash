# Lua-Flash Player 0.12 — rotação, escala e pivô

Runtime de jogos e animações `.lflash`/`.lfgame`, em Lua com [LÖVE 11.5](https://love2d.org/). O Studio continua em sua própria pasta, sem alterações nesta versão.

## O que mudou

**Rotação de PNG:** os sprites podem girar de -360° a +360° ao redor de um pivô. A origem padrão da ferramenta é o centro (50%, 50%).

**Escala independente:** largura e altura podem ser multiplicadas por valores entre 10% e 400%, independentemente. O pivô, também em percentuais, vai de 0% a 100% das dimensões originais do sprite.

**Interação transformada:** cliques e toques são convertidos do espaço do palco de volta para o sistema de coordenadas original do PNG. Por isso, um pixel transparente continua ignorado mesmo que o sprite esteja inclinado, aumentado ou reduzido.

**Colisões:** o motor usa uma caixa ampla transformada para descartar objetos afastados e uma verificação adicional por amostras de pixels opacos projetados no palco. Aplica-se a sprite/sprite e sprite/forma vetorial e trabalha junto da amostragem temporal da versão 0.11.

**Compatibilidade:** os pacotes das versões LUAFGAME 1–6 podem ser lidos e regravados sem migração obrigatória; os jogos importados não executam Lua arbitrário.

## Usar

```bash
love player-lua
```

Clique em **PACOTE** para ver uma estrela PNG girada 45°, ampliada a 130% e acompanhando a bola animada. Use **F8/F9** para diminuir/aumentar o volume e **F10** para silenciar os efeitos. Os controles anteriores de reprodução continuam.

## Publicar um jogo com sprite transformado

Partindo de um jogo v6 que já tenha um sprite PNG:

```bash
lua tools/transform_sprite.lua entrada.lfgame saida.lfgame 1 45 130 130 50 50
```

Os parâmetros são: arquivo de entrada, arquivo de saída, índice do sprite, ângulo em graus, escala X (%), escala Y (%), pivô X (%) e pivô Y (%).

O comando cria um **LUAFGAME 7** sem alterar o arquivo original. Para preparar um jogo v6, continuam disponíveis `tools/make_game.lua`, `tools/attach_media.lua`, `tools/bind_sprite.lua` e `tools/animate_media.lua`.

## Testes

```bash
lua tests/package_v7_test.lua
lua tests/swept_collision_test.lua
lua tests/pixel_mask_test.lua
lua tests/package_v6_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O GitHub Actions também inicializa o Player com o LÖVE real em um monitor virtual e publica o pacote `.love` com jogos de demonstração.

**Limites conhecidos:** as transformações são estáticas dentro de cada pacote (não existem keyframes independentes de rotação/escala ainda). A colisão usa pixels amostrados, portanto não é matemática ou fisicamente contínua e pode perder detalhes muito finos. Ainda faltam benchmarks, homologação em computadores reais e executáveis nativos.
