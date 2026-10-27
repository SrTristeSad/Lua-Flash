# Lua-Flash Player 0.9 — animações PNG e efeitos de timeline

Reprodutor independente em Lua + [LÖVE 11.5](https://love2d.org/) para arquivos `.lflash` e jogos `.lfgame`. Não executa projetos SWF/ActionScript antigos.

## Uso

Na raiz do repositório:

```bash
love player-lua
```

Clique em **PACOTE**. Na demonstração 0.9, a imagem PNG acompanha a bola e alterna entre **dois desenhos** a cada **7 quadros**; dois efeitos WAV são programados nos quadros **23 e 45**. A velocidade e a pausa da timeline também controlam essa animação. O minijogo antigo continua em **JOGAR**.

O áudio permanece controlável por **F8** (diminuir volume), **F9** (aumentar) e **F10** (silenciar/reativar).

## LUAFGAME 6

O novo formato `.lfgame` preserva integralmente uma cena e recursos do LUAFGAME 5, acrescentando:

- `ANIMATION spriteIndex period count pngIDs`: sequência de 2 a 16 imagens PNG existentes no pacote; duração entre 1 e 120 quadros por imagem.
- `TIMELINE_SOUND frame wavID`: efeito WAV associado a um quadro válido. Máximo de 128 agendamentos.
- O sprite usa a posição fracionária atual da timeline para escolher o PNG. A cena principal e o vínculo de interação continuam os mesmos.
- A reprodução dispara os sons **ao cruzar os quadros** em movimento normal. Não toca um efeito só por ficar parado no quadro ou arrastar a barra de progresso.
- Ao retornar do fim para o começo em modo loop, a verificação considera os quadros finais e iniciais atravessados.
- Os formatos v1, v2, v3, v4 e v5 continuam compatíveis, sem conversão exigida.

**Limitações técnicas:** sons são efeitos WAV curtos com reinício ao retriggerar o mesmo recurso, não música em streaming. Ainda não há sincronismo por amostra de áudio, múltiplos loops completos em uma única atualização, máscara alfa de colisão, atlas de sprites ou rotação. O hit-testing e as colisões de sprites continuam usando retângulos.

Veja a [especificação do LUAFGAME 6](../docs/FORMAT_LUAFGAME6.md).

## Criar um jogo com PNGs animados

Primeiro crie uma cena `.lflash` no Studio, converta-a em jogo, anexe imagem e áudio e vincule um sprite a um objeto:

```bash
lua tools/make_game.lua cena.lflash base.lfgame 2 1 8 30 smooth
lua tools/attach_media.lua base.lfgame com-midia.lfgame primeiro.png 600 260 64 64 efeito.wav CLICKID alvo
lua tools/bind_sprite.lua com-midia.lfgame com-sprite.lfgame 1 alvo FOLLOW
```

Depois, adicione uma **segunda imagem PNG** à sequência e defina um quadro que dispara o WAV já incluído:

```bash
lua tools/animate_media.lua com-sprite.lfgame jogo-animado.lfgame 1 7 segundo.png som_1 23
```

O resultado contém os recursos e regras dentro de um único arquivo `jogo-animado.lfgame`. No exemplo, o sprite 1 alterna imagens a cada 7 quadros e `som_1` toca quando o avanço da timeline cruza o quadro 23. O nome `som_1` é criado pelo primeiro `attach_media.lua`; para um pacote diferente, use o ID de WAV correspondente.

É possível arrastar o resultado para a janela do Player. Os arquivos de entrada permanecem intactos.

## Gerar pacote e executar testes

```bash
lua tests/package_v6_test.lua
lua tests/package_v5_test.lua
lua tests/package_v4_test.lua
lua tests/gui_smoke.lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.9.lfgame
```

A CI verifica também testes de versões anteriores, sintaxe, renderização com **LÖVE real em display virtual**, importação de PNG/WAV e publicação de um jogo v6.

O Studio continua separado e não foi alterado nesta versão. Build `.love` precisa do LÖVE; ainda não há um executável nativo pronto para Windows nem APK.
