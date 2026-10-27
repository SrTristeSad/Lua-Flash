# LUAFGAME 8 — quadros-chave para transformações de sprites

Especificação experimental do Player Lua 0.13. **Somente dados**, sem importação nem execução de scripts Lua de terceiros.

## Envelope binário

Um jogo `.lfgame` versão 8 incorpora integralmente um jogo LUAFGAME 7 (que contém a cena, regras, PNG/WAV, sprites e transformação estática) e adiciona trilhas temporais:

```text
LUAFGAME 8
BASE_BYTES<TAB>N
<exatamente N bytes de um LUAFGAME 7>
TWEEN_COUNT<TAB>1
TWEEN<TAB>1<TAB>3
KEY<TAB>1<TAB>0<TAB>0<TAB>0<TAB>100<TAB>100
KEY<TAB>23<TAB>30<TAB>-45<TAB>90<TAB>150<TAB>85
KEY<TAB>90<TAB>0<TAB>0<TAB>360<TAB>100<TAB>100
ENDGAME8
```

`<TAB>` equivale ao caractere tab real, e todas as linhas terminam em LF. Há um delimitador LF após os N bytes binários do pacote anterior. Bytes extras no final são recusados.

### Dados

- `TWEEN spriteIndex keyCount`: identifica uma trilha de sprite (índice 1-based).
- `KEY frame offsetX offsetY angleDegrees scaleXPercent scaleYPercent`: define uma pose da animação.
- Os keyframes devem estar em ordem estritamente crescente, começando no quadro 1, com 2 a 128 chaves por trilha.
- Posições aceitas: de -4.096 a +4.096 unidades de deslocamento X/Y.
- Rotação: de -360° a +360°. Escalas X/Y: de 10% a 400%.
- Máximo de 64 trilhas e 2.048 keys no pacote.

## Comportamento

A posição base continua vindo de `STATIC` ou `FOLLOW`. A animação adiciona seus deslocamentos `x`/`y` à base. **O ângulo e a escala das chaves substituem os valores estáticos v7**, enquanto o pivô v7 é preservado. Sem transformação v7, o pivô padrão é (50%, 50%).

Entre duas chaves, deslocamentos e escalas usam interpolação linear. Para o ângulo, escolhe-se a menor variação circular, evitando um giro quase completo ao passar de 170° a -170°. Fora da faixa de keys, vale a pose da key mais próxima.

Toda consulta à posição usa esse estado de transformação: renderização, clique com máscara de alfa, colisão e amostragem temporal. O pacote original, sem trilha, mantém o comportamento anterior. A serialização dos formatos LUAFGAME 1–7 não muda.

A interpolação de sprites é independente da opção de interpolação visual das formas vetoriais.

## Autoria

```bash
lua tools/animate_transform.lua base-v7.lfgame jogo-v8.lfgame 1 1,0,0,0,100,100 23,30,-45,90,150,85 90,0,0,360,100,100
```

O comando nunca altera o arquivo de entrada. O Studio continua separado; a integração de edição visual dessas trilhas pertence a uma versão futura.
