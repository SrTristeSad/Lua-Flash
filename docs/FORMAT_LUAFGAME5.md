# LUAFGAME 5 — sprites interativos

Formato experimental **de dados** para o Lua-Flash Player 0.8. Este envelope mantém todos os bytes de um jogo **LUAFGAME 4** (cena v3 + PNG/WAV) e acrescenta um mapa de sprites para objetos nomeados. O Player não avalia scripts recebidos.

## Estrutura

```text
LUAFGAME 5
BASE_BYTES<TAB>N
<exatamente N bytes de um pacote LUAFGAME 4>
SPRITE_BIND_COUNT<TAB>1
SPRITE_BIND<TAB>1<TAB>bola<TAB>FOLLOW
ENDGAME5
```

`<TAB>` indica tabulação, e cada linha termina com LF. Há um LF extra após o bloco binário do jogo v4. Não é permitida sobra de bytes depois de `ENDGAME5\n`.

`SPRITE_BIND índice ID modo` associa um sprite v4 existente a um objeto já declarado no jogo. O índice é baseado em 1; cada índice e cada objeto podem ter no máximo um vínculo.

- **STATIC**: mantém `sprite.x` e `sprite.y` originais.
- **FOLLOW**: centraliza a imagem sobre a caixa da forma vetorial correspondente ao ID na posição corrente da timeline, respeitando as associações por quadro-chave e a interpolação visual quando ativada.

## Interação

Os sprites associados são renderizados à frente das formas vetoriais, então a detecção de cliques consulta as caixas dos sprites primeiro (último sprite desenhado tem prioridade). Isso vale para mouse e toque.

O ID associado é encaminhado às regras declarativas `CLICKID`. A colisão `COLLIDE` usa o retângulo do sprite quando existir e, caso contrário, a forma vetorial nativa. O evento de colisão continua sendo disparado apenas quando dois objetos entram em contato após uma separação.

**Limitação geométrica:** o retângulo considera inclusive pixels transparentes. Também não considera rotação ou escala não uniforme dinâmica. Sprites estáticos são detectáveis independentemente de seu vínculo vetorial de origem enquanto o jogo estiver ativo.

## Compatibilidade e validação

Os pacotes anteriores LUAFGAME 1–4 são aceitos e serializados sem alterações. V5 permite até 64 associações de sprite, com IDs pertencentes à definição do jogo, índices existentes e apenas os modos `FOLLOW`/`STATIC`. Todos os limites de tamanho e verificação de PNG/WAV da v4 continuam valendo.

A verificação é estruturada e limitada; os decodificadores reais de imagem/som continuam sendo os do LÖVE. Nenhum formato deste projeto habilita Lua arbitrário recebido de jogos externos.

## Ferramenta de autoria

```bash
lua tools/bind_sprite.lua com-midia.lfgame final.lfgame 1 bola FOLLOW
```

O comando publica um novo jogo v5; não modifica o arquivo original. O Studio permanece separado. A etapa futura prevista é colocar identidades persistentes também no documento de edição e permitir sprites hierárquicos.
