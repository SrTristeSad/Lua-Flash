# LUAFGAME 7 — transformações declarativas de sprites

Formato experimental, **sem código executável importado**, para o Player Lua 0.12.

O novo pacote engloba todos os bytes de um jogo **LUAFGAME 6** (cena, PNG/WAV, regras, sprites e animações) e acrescenta transformações geométricas.

## Estrutura

```text
LUAFGAME 7
BASE_BYTES<TAB>N
<exatamente N bytes de um LUAFGAME 6>
TRANSFORM_COUNT<TAB>1
TRANSFORM<TAB>1<TAB>45<TAB>130<TAB>130<TAB>50<TAB>50
ENDGAME7
```

No arquivo binário, `<TAB>` significa tabulação, cada linha usa LF e há um separador LF após o bloco binário de N bytes. Qualquer dado excedente após `ENDGAME7\n` é rejeitado.

A linha `TRANSFORM` contém:

```text
TRANSFORM spriteIndex angleDeg scaleXPercent scaleYPercent pivotXPercent pivotYPercent
```

- `spriteIndex`: índice válido de sprite PNG (começa em 1); apenas uma transformação por sprite.
- `angleDeg`: inteiro entre -360° e +360°.
- `scaleXPercent` e `scaleYPercent`: inteiros entre 10 e 400.
- `pivotXPercent` e `pivotYPercent`: inteiros entre 0 e 100.
- Até **64 transformações**, preservando os limites globais dos formatos anteriores.

Sem transformação explícita, o sprite mantém o comportamento do formato v6. O modo `FOLLOW` continua centralizando o retângulo original na forma vetorial animada; depois aplica a transformação ao redor do pivô informado.

## Desenho e interação

As coordenadas dos quatro cantos transformados formam uma caixa delimitadora para rejeição rápida. O desenho usa parâmetros nativos de `love.graphics.draw`: origem no pivô, ângulo em radianos e escalas X/Y.

A detecção de clique converte a posição do mouse/toque pela transformação inversa. Somente os pixels com alfa acima do limite do Player recebem clique.

Colisões entre sprites e entre sprite/forma utilizam a caixa transformada e amostras de pixels opacos no espaço do palco. Trata-se de aproximação limitada por orçamento de amostragem: contatos de dimensão extremamente pequena podem passar despercebidos.

## Compatibilidade e ferramenta

O leitor `src/package_v7.lua` aceita LUAFGAME 1–6 sem mudança de arquivo. Os jogos v7 não são reconhecidos por Players antigos.

```bash
lua tools/transform_sprite.lua entrada.lfgame saida.lfgame 1 45 130 130 50 50
```

O Studio não foi modificado. Nesta versão não há tween de ângulo/escala, rotação de formas vetoriais ou componentes 3D.
