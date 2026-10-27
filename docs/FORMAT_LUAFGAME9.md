# LUAFGAME 9 — easing por segmento

Especificação experimental do Lua-Flash Player 0.14. O pacote é um envelope de **dados validados** ao redor de um LUAFGAME 8 completo (mídia, regras, trilhas de transformação); nenhum código Lua é executado a partir do arquivo.

## Registros do envelope

```text
LUAFGAME 9
BASE_BYTES<TAB>N
<exatamente N bytes de um pacote LUAFGAME 8>
EASING_COUNT<TAB>2
EASING<TAB>1<TAB>1<TAB>EASE_IN_OUT
EASING<TAB>1<TAB>23<TAB>SMOOTH
ENDGAME9
```

`<TAB>` representa um caractere de tabulação; cada linha termina em LF, incluindo a separação logo após os N bytes da base. Não pode existir conteúdo extra depois de `ENDGAME9\n`.

`EASING spriteIndex startFrame mode` atribui uma curva ao **trecho iniciado por uma chave real** da trilha de transformação identificada por `spriteIndex`. A última chave de uma trilha não inicia um trecho e não pode receber uma curva. Segmentos sem `EASING` utilizam `LINEAR`.

## Modos matemáticos

Dado o progresso local `t` entre 0 e 1:

- `LINEAR`: `t`.
- `EASE_IN`: `t*t`.
- `EASE_OUT`: `1-(1-t)^2`.
- `EASE_IN_OUT`: `2*t^2` antes da metade, `1-2*(1-t)^2` depois.
- `SMOOTH`: `t*t*(3-2*t)`.
- `STEP`: `0` durante o trecho, com a pose da próxima chave aplicada na própria chave.

O valor interpolado da propriedade é calculado por `a + (b-a)*ease(t)`. O ângulo usa a menor diferença circular entre os valores inicial e final; as demais propriedades continuam interpoladas no sistema de coordenadas do palco.

## Restrições

- Até **2.048 curvas** explícitas, no máximo uma por par `spriteIndex/startFrame`.
- Cada referência deve corresponder a uma trilha e chave inicial de segmento existente.
- Aceita exclusivamente os seis modos declarados acima.
- Continua sujeito ao limite total de 25 MB e aos limites de mídia, sprites e trilhas anteriores.
- LUAFGAME 1–8 são lidos sem conversão e preservam seus bytes ao regravar.

O Player oferece um painel básico de seleção de segmentos com botão de mudança de curva. Alternativamente, use:

```bash
lua tools/set_easing.lua entrada-v8.lfgame saida-v9.lfgame 1 23 SMOOTH
```

A edição ainda não permite criar ou deslocar keyframes pela interface. O Studio permanece separado.
