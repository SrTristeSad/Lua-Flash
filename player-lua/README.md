# Lua-Flash Player 0.14 — easing e painel de curvas

Runtime Lua + LÖVE para animações `.lflash` e jogos `.lfgame`, com compatibilidade de leitura LUAFGAME 1–9. O Player não executa ActionScript/SWF nem scripts Lua fornecidos por jogos.

## Curvas disponíveis

Cada trecho entre **duas chaves consecutivas** pode receber uma curva própria. As seis opções são:

| Curva | Comportamento |
|---|---|
| `LINEAR` | Velocidade constante (padrão dos jogos v8). |
| `EASE_IN` | Começa lentamente e acelera. |
| `EASE_OUT` | Começa rapidamente e desacelera. |
| `EASE_IN_OUT` | Acelera e depois desacelera. |
| `SMOOTH` | Transição suave com derivadas nulas nos extremos (*smoothstep*). |
| `STEP` | Mantém a pose inicial até atingir o próximo quadro-chave. |

A curva atua sobre deslocamento X/Y, escala X/Y e avanço de rotação entre chaves. A rotação ainda utiliza o arco angular mais curto. A posição `FOLLOW` e os dados da animação vetorial continuam funcionando.

## Painel visual de curvas

1. Execute `love player-lua`, clique em **PACOTE** ou arraste um jogo LUAFGAME 8/9 com uma trilha de transformação.
2. Pressione **E** para abrir/fechar o painel. A reprodução é pausada para facilitar a inspeção.
3. Use **‹/›** para escolher a trilha (sprite). Clique em um dos trechos da lista para selecioná-lo; o Player vai para o quadro-chave inicial.
4. Clique no botão **CURVA** para alternar entre os seis modos. Também é possível pressionar **C**, usar setas para cima/baixo para escolher trechos, PageUp/PageDown para outras trilhas e a roda do mouse dentro do painel para percorrer uma lista longa.
5. Clique em **SALVAR** ou use **Ctrl+S**. A cópia editada é gravada em `player_game.lfgame`, no diretório de salvamento do LÖVE.

Um jogo v8 aberto continua no formato antigo até a primeira alteração; quando se edita uma curva, ele passa para **LUAFGAME 9**. Os jogos antigos não são regravados automaticamente. O Studio permanece intocado.

Este painel é um **editor inicial de curvas**, não um editor completo de keyframes: você seleciona intervalos e muda o easing, mas a criação, movimentação ou exclusão visual das chaves ainda não está disponível.

## Publicação via linha de comando

A ferramenta `tools/set_easing.lua` pode adicionar ou atualizar uma curva sem abrir o Player:

```bash
lua tools/set_easing.lua jogo-v8.lfgame jogo-v9.lfgame 1 1 EASE_IN_OUT
```

Os parâmetros finais são `spriteIndex`, `quadroInicialDoTrecho` e `modo`. Para restaurar a interpolação padrão, use `LINEAR`. O quadro informado deve existir na trilha e não pode ser o último quadro-chave.

Para ver o exemplo:

```bash
lua tools/export_example.lua dist/Exemplo-0.14.lfgame
love player-lua
```

O botão **PACOTE** abre a demonstração 0.14, com trechos de aceleração, desaceleração e suavização diferentes.

## Testes e limites

```bash
lua tests/package_v9_test.lua
lua tests/package_v8_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI executa a suíte completa de versões anteriores e um smoke test com LÖVE real em display virtual, além de publicar o `.love` e jogos `.lfgame`.

**Pendente para o 1.0:** editor visual completo de poses, estabilidade/performance em PCs reais, áudio avançado, suporte a projetos maiores e uma distribuição nativa Windows sem instalação separada de LÖVE. Colisões continuam aproximadas por amostragem; o formato não oferece Bézier editável ou scripting externo.
