# Lua-Flash Player 0.5 — Objetos, estado e jogos próprios

O **Lua-Flash Player** executa animações `.lflash` e jogos declarativos `.lfgame` usando Lua + [LÖVE 11.5](https://love2d.org/). É uma plataforma nova, sem execução de SWF, FLA, XFL ou ActionScript da Adobe.

## Executar

```bash
love player-lua
```

Abra a demonstração **PACOTE**: clique na bola azul. O primeiro toque incrementa o estado `toques`; a partir do segundo toque, acertos no corpo da bola dão pontos. O brilho também dá pontos. Clique no cenário para perder um ponto, ou pressione `Z` para voltar ao primeiro quadro. A meta é 6 pontos em 40 segundos.

Você pode soltar arquivos `.lfgame` ou `.lflash` na janela e salvá-los com `Ctrl+S`.

## LUAFGAME 2 — Novo formato 0.5

Os jogos `.lfgame` são arquivos de **dados**, com cena `.lflash` incorporada e regras de execução limitadas.

- **OBJECT:** atribui um nome a uma combinação camada/forma, por exemplo `bola`.
- **STATE:** variável inteira local da partida, por exemplo `toques=0`.
- **RULE:** uma condição acionada por clique num objeto nomeado (`CLICKID`) ou tecla (`KEY`).
- **Ações:** `SCORE`, `SEEK`, `PLAY`, `PAUSE`, `ADD`, `SET`.
- **Condições:** executar ações somente se uma variável for `GE` (maior ou igual), `LE` (menor ou igual) ou `EQ` (igual) ao valor indicado.

Limites: 256 objetos, 64 variáveis, 128 regras, títulos de até 120 bytes e pacotes de até 25 MB. Variáveis são limitadas entre 0 e 1.000.000, e as regras são verificadas antes da execução.

O formato **LUAFGAME 1 (Player 0.4)** continua sendo aceito. Não é preciso converter arquivos antigos. A preservação dos bytes na regravação também é testada.

**Sobre os IDs:** nesta primeira versão, nomes como `bola` dão identidade estável *dentro do pacote* às regras e ao objeto associado. A associação ainda aponta para a posição da forma na camada. Se o autor reordenar as formas e publicar novamente, precisará revisar essa associação. A próxima etapa deve introduzir identificadores persistentes no modelo de objetos.

Nenhum código Lua externo é executado. `LUAFGAME 2` não é um interpretador de Lua genérico nem uma sandbox para scripts arbitrários.

## Criar um jogo a partir de um documento existente

```bash
lua tools/make_game.lua cena.lflash meu-jogo.lfgame 2 1 10 30 smooth
```

Isso cria um `.lfgame` **versão 2** com o objeto `alvo` associado à forma 1 da camada 2, uma regra para pontuar ao clicar, meta de 10 pontos e 30 segundos de duração. O argumento `smooth` ativa interpolação. Não são necessários ajustes no Studio.

Para uma demonstração das regras condicionais:

```bash
lua tools/export_example.lua dist/Exemplo-0.5.lfgame
```

Abra o `.lfgame` no Player por arrastar/soltar.

## Recursos anteriores preservados

Reprodução, pausa, navegação de quadros, velocidade de 0,25× a 4×, repetição, tela cheia, interpolação visual opcional, mouse, toque, teclado, detecção de objetos e minijogo original no botão **JOGAR**.

## Testes e pacote

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/input_test.lua
lua tests/package_test.lua
lua tests/package_v2_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O último comando gera `dist/Lua-Flash-Player-0.5.love`. O pacote não é um EXE autônomo e precisa do LÖVE.

**Estado experimental:** faltam áudio sincronizado, imagens e fontes importáveis, um sistema de instâncias com IDs persistentes no modelo visual, scripts isolados para jogos, publicação para Android/Web e testes de desempenho em dispositivos reais.
