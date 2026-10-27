# Especificação experimental — LUAFGAME 4

O `LUAFGAME 4` é um formato de arquivo `.lfgame` binário emoldurando os dados de um jogo `LUAFGAME 3` e os recursos PNG/WAV embutidos. Não é um arquivo Lua e não contém instruções executáveis.

## Estrutura do pacote

O cabeçalho começa com `LUAFGAME 4\n`. Segue-se:

```text
LUAFGAME 4
GAME_BYTES<TAB>N
<exatamente N bytes de um jogo LUAFGAME 3>
RESOURCE_COUNT<TAB>2
RESOURCE<TAB>estrela<TAB>PNG<TAB>Q
<exatamente Q bytes de PNG>
RESOURCE<TAB>efeito<TAB>WAV<TAB>R
<exatamente R bytes de WAV>
SPRITE_COUNT<TAB>1
SPRITE<TAB>estrela<TAB>600<TAB>260<TAB>64<TAB>64
CUE_COUNT<TAB>2
CUE<TAB>efeito<TAB>CLICKID<TAB>bola<TAB>-
CUE<TAB>efeito<TAB>WIN<TAB>-<TAB>-
ENDGAME4
```

`<TAB>` acima é o separador tab real, e `N/Q/R` são comprimentos em bytes. Cada bloco de dados possui **um caractere newline delimitador**, que não faz parte do conteúdo. O leitor utiliza os comprimentos para localizar corretamente os blocos mesmo quando contêm bytes nulos ou caracteres de controle. Bytes extras após `ENDGAME4\n` são rejeitados.

## Mídia suportada

- **PNG**: assinatura PNG, chunk IHDR, dimensões de 1–1.024, 8-bit RGB ou RGBA.
- **WAV**: RIFF/WAVE PCM 16 bits, cabeçalho simples de 44 bytes, mono/estéreo, 8 kHz–44,1 kHz e até 10 segundos.
- Cada arquivo tem limite de 2 MB; o conjunto de mídia, 12 MB.
- Máximo de 24 recursos, 64 sprites, 64 regras de som, 25 MB no pacote completo.

Os dados passam por validação estrutural antes de o LÖVE criar a imagem ou o áudio. A decodificação real de PNG/WAV é feita pelas bibliotecas do próprio LÖVE; arquivos semanticamente inválidos que ultrapassem a checagem estrutural ainda podem ser rejeitados pelo decodificador. O Player procura preservar o jogo atual quando a importação falha.

## Sprites e efeitos

Uma linha `SPRITE` indica o ID de uma imagem e um retângulo do palco `(x, y, largura, altura)`. Neste estágio, sprites são representações visuais simples **acima** das formas vetoriais, sem hit-testing, transformações animadas nem colisões.

Uma linha `CUE` indica o ID de um recurso WAV e a referência a um evento de jogo já declarado: `CLICKID`, `KEY` ou `COLLIDE`. O evento `WIN` indica vitória da sessão e não exige regra específica. O mesmo WAV pode ser reutilizado por vários eventos.

O som é reproduzido na ocorrência do evento; não é possível anexar música de fundo sincronizada à timeline neste formato. **F10** silencia ou reativa os efeitos durante a partida.

## Compatibilidade

O `src/package_v4.lua` delega a leitura dos formatos LUAFGAME 1, 2 e 3 aos decodificadores anteriores, preservando a representação binária para regravação. O novo formato não executa scripts e **não** oferece compatibilidade SWF ou ActionScript.

## Publicação

```bash
lua tools/make_game.lua cena.lflash base.lfgame 2 1 8 30 smooth
lua tools/attach_media.lua base.lfgame pronto.lfgame imagem.png 600 260 64 64 efeito.wav CLICKID alvo
```

O arquivo final `pronto.lfgame` contém cena, regras e recursos necessários. O Studio permanece independente.
