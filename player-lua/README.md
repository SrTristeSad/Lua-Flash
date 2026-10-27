# Lua-Flash Player 0.8 — PNG com interação e colisão

O Player Lua executa animações autorais `.lflash` e jogos `.lfgame`, usando Lua e [LÖVE 11.5](https://love2d.org/). Não executa SWF ou scripts Lua contidos em arquivos externos.

## Executar

```bash
love player-lua
```

Clique em **PACOTE** para abrir a demonstração LUAFGAME 5. O pequeno PNG passa a **seguir a bola**, pode ser clicado e pode provocar uma colisão com a barreira vermelha. A pontuação e os estados declarativos seguem funcionando.

Controles novos de áudio: **F8** diminui 10%, **F9** aumenta 10%, **F10** silencia/reativa. Esses ajustes atingem os efeitos WAV da partida. Os demais controles do Player (play/pause, timeline, velocidade, loop, tela cheia e importação por arrastar/soltar) continuam disponíveis.

## Formato LUAFGAME 5

Um jogo `.lfgame` v5 é um envelope binário do jogo v4, complementado por associações `SPRITE_BIND`.

- `SPRITE_BIND índice objeto STATIC` associa uma imagem ao ID de um objeto, preservando a posição x/y configurada no sprite.
- `SPRITE_BIND índice objeto FOLLOW` mantém a imagem centralizada sobre a forma vetorial animada daquele objeto. Se a forma deixa de existir, o sprite associado deixa de aparecer naquele trecho.
- **Hit-testing:** sprites associados aparecem na frente das formas vetoriais e capturam o clique primeiro, usando seu ID para regras `CLICKID`.
- **Colisões:** para objetos associados a sprites, o retângulo do PNG substitui a forma vetorial no cálculo de contato. As demais formas continuam usando as regras geométricas da versão 0.6.
- **Sem leitura de pixels transparentes:** o hit-testing e as colisões são por retângulos alinhados aos eixos, portanto regiões transparentes dentro do PNG também podem receber cliques.
- O vínculo é salvo no `.lfgame`; **não** altera os documentos editáveis do Studio. Os formatos LUAFGAME 1–4 continuam compatíveis.

Limites: até 64 vínculos de sprite (um por índice e por objeto), seguindo os limites de mídia v4. Os arquivos são validados antes de serem instalados, e o Player não executa código de terceiros.

[Detalhes técnicos do LUAFGAME 5](../docs/FORMAT_LUAFGAME5.md).

## Publicar um jogo com PNG interativo

A partir da raiz do repositório:

```bash
# 1. Converter animação do Studio para jogo.
lua tools/make_game.lua cena.lflash base.lfgame 2 1 8 30 smooth

# 2. Incorporar PNG e WAV originais.
lua tools/attach_media.lua base.lfgame com-midia.lfgame imagem.png 600 260 64 64 efeito.wav CLICKID alvo

# 3. Associar o primeiro sprite ao ID "alvo" e acompanhá-lo.
lua tools/bind_sprite.lua com-midia.lfgame jogo-final.lfgame 1 alvo FOLLOW
```

Abra `jogo-final.lfgame` no Player por arrastar/soltar. Se quiser um botão fixo no palco em vez de um sprite animado, substitua `FOLLOW` por `STATIC`.

Para testar sem imagens externas, há um exemplo original:

```bash
python3 tools/generate_media_fixtures.py --directory dist
lua tools/export_example.lua dist/Exemplo-0.8.lfgame
```

## Testes e pacote

```bash
lua tests/package_test.lua
lua tests/package_v2_test.lua
lua tests/package_v3_test.lua
lua tests/package_v4_test.lua
lua tests/package_v5_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O GitHub Actions também inicia o Player usando o LÖVE real em ambiente gráfico virtual, verifica a importação de mídia e gera exemplos `.lfgame` v4/v5.

## Limitações atuais

Os sprites ainda não têm máscaras de colisão precisas por pixel, animação própria de atlas/spritesheet ou rotação; o áudio ainda não segue uma linha do tempo dedicada. Falta integrar IDs ao formato editável do Studio, introduzir uma API Lua de jogos com isolamento adequado e disponibilizar builds desktop nativos ou para Android/Web.

**Esta é uma versão experimental**; a CI não substitui testes manuais em dispositivos reais.
