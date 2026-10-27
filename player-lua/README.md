# Lua-Flash Player 0.7 — PNG e WAV nos jogos

O Player Lua é o reprodutor independente de animações `.lflash` e jogos `.lfgame`, utilizando Lua e [LÖVE 11.5](https://love2d.org/). Não implementa leitura de Flash/SWF da Adobe.

## Executar e experimentar

```bash
love player-lua
```

Clique **PACOTE** para abrir o exemplo LUAFGAME 4: o palco recebe um pequeno desenho em PNG e o jogo reproduz um efeito sonoro original ao clicar na bola azul ou ao colidir com a barreira. Também existe um efeito de vitória.

Pressione **F10** para silenciar ou reativar os sons. Os outros controles de reprodução, o minijogo **JOGAR**, os quadros-chave e a interpolação continuam disponíveis.

## LUAFGAME 4 — recursos embutidos

Os pacotes `.lfgame` contêm um jogo declarativo com regras LUAFGAME 3 e podem transportar seus próprios recursos gráficos e efeitos:

- `PNG` RGB/RGBA, 8 bits, largura e altura entre 1 e 1.024 pixels; cada recurso tem limite de 2 MB.
- `WAV` PCM 16-bit, mono ou estéreo, 8.000–44.100 Hz, duração de até 10 segundos; limite de 2 MB por recurso.
- `SPRITE`: desenha uma imagem acima das formas vetoriais, com posição e dimensão definidas em coordenadas do palco.
- `CUE`: associa um WAV a uma regra `CLICKID`, `KEY` ou `COLLIDE`, ou ao evento de vitória `WIN`.

Os sprites são **decorativos nesta versão**: ainda não entram no hit-testing ou nas colisões. Sons são efeitos curtos disparados por eventos; **não há trilha musical sincronizada à timeline** nem streaming de áudio.

Há limites gerais de 25 MB por pacote, 12 MB de mídia bruta, 24 recursos, 64 sprites e 64 associações de efeitos. A validação verifica formato, tamanho, dimensões e referências antes de carregar recursos por memória; arquivos importados não são executados como Lua.

Os jogos v1, v2 e v3 seguem compatíveis. Para detalhes do envelope binário, leia [FORMAT_LUAFGAME4.md](../docs/FORMAT_LUAFGAME4.md).

## Como publicar um jogo com PNG e WAV

Primeiro produza uma cena `.lflash` no Studio e converta-a em um jogo declarativo:

```bash
lua tools/make_game.lua cena.lflash base.lfgame 2 1 8 30 smooth
```

Agora incorpore uma imagem e um áudio existentes (seus ou com licença adequada):

```bash
lua tools/attach_media.lua base.lfgame completo.lfgame estrela.png 600 260 64 64 efeito.wav CLICKID alvo
```

O primeiro arquivo permanece intacto. O segundo contém ambos os recursos e pode ser arrastado diretamente para o Player, sem necessidade de manter os arquivos PNG e WAV separados.

Para gerar **arquivos de teste originais** e uma demonstração já pronta:

```bash
python3 tools/generate_media_fixtures.py --directory dist
lua tools/export_example.lua dist/Exemplo-0.7.lfgame
```

Também é possível associar um áudio a uma colisão declarada:

```bash
lua tools/attach_media.lua base.lfgame completo.lfgame estrela.png 600 260 64 64 efeito.wav COLLIDE bola barreira
```

Isso só será aceito se a cena já tiver objetos e uma regra de colisão com esses IDs.

## Testes e distribuição

```bash
lua tests/package_test.lua
lua tests/package_v2_test.lua
lua tests/package_v3_test.lua
lua tests/package_v4_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O GitHub Actions ainda executa o **LÖVE real em uma tela virtual**, carrega o jogo com os recursos de mídia e testa a importação de PNG/WAV por arquivo.

O pacote `.love` não contém o Studio nem é um EXE Windows autônomo.

## Limites conhecidos

Ainda não há PNG como objeto interativo, colisões de sprites, áudio sincronizado a quadros, MP3/OGG ou vídeo, renderização hierárquica, isolamento de scripts de terceiros ou builds nativos Android/Web. O desempenho e os controles precisam de testes manuais em dispositivos reais.
