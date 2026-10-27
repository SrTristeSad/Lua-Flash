# Lua-Flash Player 0.4 — jogos declarativos

Player independente, escrito principalmente em Lua e executado com [LÖVE 11.5](https://love2d.org/).

**Não emula Adobe Flash nem executa SWF, FLA ou ActionScript.** O objetivo é criar uma plataforma nova, leve e portável.

## Executar

Na raiz do repositório:

```bash
love player-lua
```

O Player abre animações nativas `.lflash` e, **a partir da 0.4**, jogos declarativos `.lfgame`.

## Jogar agora

Clique no botão **PACOTE** para executar um jogo exportável: acerte a bola azul 8 vezes dentro de 30 segundos. Clique ou toque na bola, ou pressione `Z` para testar uma regra que volta ao quadro inicial. Há também o botão **JOGAR**, que preserva o antigo minijogo interno da versão 0.3.

Você também pode **arrastar e soltar** arquivos `.lfgame` na janela. `Ctrl+S` salva uma cópia do jogo carregado em `player_game.lfgame` na pasta de dados LÖVE (não perde as regras); se uma animação simples estiver carregada, cria `player_demo.lflash`.

## Novo formato LUAFGAME 1

Um pacote `.lfgame` é um arquivo textual com cabeçalho estruturado, comprimento da cena, projeto `.lflash` incorporado e regras. Os tipos de evento e ações são explicitamente permitidos:

| Eventos | Ações |
|---|---|
| `CLICK layer shape` | `SCORE pontos`, `SEEK quadro`, `PAUSE`, `PLAY` |
| `KEY tecla` | As mesmas ações |

O Player valida o conteúdo (versão, título, quantidade de regras, dimensões, alvos, tempo e integridade da cena) antes de instalar a sessão. Não chama `load`, `loadstring`, `dofile` ou `os.execute` nos dados carregados. **Não há execução de scripts externos.** Isso é um interpretador limitado de regras; não é uma sandbox Lua genérica.

Os objetos são identificados temporariamente pela camada e posição na lista de formas. O próximo formato deverá introduzir IDs estáveis para permitir alterações mais sofisticadas.

## Criar seu próprio jogo usando uma animação do Studio

1. Desenhe/anime normalmente no **Studio Lua**, salve um arquivo `.lflash`.
2. Na raiz do repositório, crie um jogo clicável com a ferramenta de publicação:
   
   ```bash
   lua tools/make_game.lua cena.lflash meu-jogo.lfgame 2 1 10 30 smooth
   ```

   Os argumentos finais são: **camada 2, forma 1, meta de 10 pontos, duração 30 segundos**, com interpolação opcional ligada pelo argumento `smooth`. Sem esse último argumento, a reprodução mantém os quadros originais.
3. Arraste `meu-jogo.lfgame` para a janela do Player.

Esta etapa não modifica o Studio. Ela adiciona uma maneira inicial de publicar cenas existentes como jogos simples. Para regras mais complexas, o código-fonte pode construir uma tabela declarativa validada por `src/package.lua`.

## Outros recursos preservados

- Reprodução, pausa, scrub, loop e velocidade de 0,25× a 4×.
- Interpolação visual opcional de formas compatíveis entre quadros-chave.
- Mouse, teclado e toque com conversão correta de coordenadas do palco.
- Reconhecimento de formas, respeito a camadas e captura de ponteiro.
- Tela cheia e abertura de arquivos `.lflash` por arrastar e soltar.
- Modo sem interpolação por padrão para cenas `.lflash` externas.
- Arquivos inválidos não substituem o documento já carregado.

## Gerar pacote executável pelo LÖVE

```bash
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.4.lfgame
```

O primeiro comando cria `dist/Lua-Flash-Player-0.4.love` — **não** um executável Windows nativo. O segundo gera um jogo `.lfgame` separado. GitHub Actions envia ambos como artefatos e executa testes com o LÖVE real, numa tela virtual.

## Testes

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/input_test.lua
lua tests/package_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
```

Status: **experimental**. Ainda faltam jogos com objetos identificados por nomes, scripts com permissões, som, vídeo, controles de gamepad, vários recursos visuais e homologação manual em aparelhos reais.
