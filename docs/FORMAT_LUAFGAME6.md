# LUAFGAME 6 — especificação experimental

Extensão **de dados**, sem scripts executáveis, para o Lua-Flash Player 0.9.

Um jogo v6 encapsula um pacote completo **LUAFGAME 5** (incluindo cena vetorial, mídia PNG/WAV, regras e vínculos de sprite) e adiciona sequências de quadros PNG e áudio associado à timeline.

## Estrutura binária

```text
LUAFGAME 6
BASE_BYTES<TAB>N
<exatamente N bytes de um pacote LUAFGAME 5>
ANIMATION_COUNT<TAB>1
ANIMATION<TAB>1<TAB>7<TAB>2<TAB>estrela,estrela_alt
TIMELINE_SOUND_COUNT<TAB>2
TIMELINE_SOUND<TAB>23<TAB>acerto
TIMELINE_SOUND<TAB>45<TAB>acerto
ENDGAME6
```

Cada linha de cabeçalho termina com LF, e `<TAB>` representa um caractere tab real. Após os bytes da base há um delimitador LF. O leitor usa `N` para extrair exatamente a base binária, sem confundir delimitadores internos com o conteúdo. O pacote precisa terminar em `ENDGAME6\n`, sem dados extras.

## Validação

- Máximo de **64 animações**, cada uma associada a um índice de sprite válido e exclusivo.
- Cada animação contém **2 a 16 recursos PNG** já incorporados; troca de imagem após **1 a 120 quadros**.
- Máximo de **128 eventos de timeline**; cada um contém um quadro no intervalo da cena e um ID de recurso WAV existente.
- Mantém os limites totais de 25 MB, recursos e regras das versões anteriores.
- Só os tipos de registro conhecidos são aceitos. Nenhum campo permite `load`, `eval` ou execução de Lua externo.

## Comportamento temporal

A imagem atual é escolhida de forma determinística por:

```lua
indice = math.floor((quadroAtual - 1) / periodo) % totalDeImagens + 1
```

A troca usa **quadros da timeline**, não tempo de relógio independente. Ao pausar ou buscar um quadro, a imagem representa aquela posição imediatamente.

O áudio toca somente quando o relógio de reprodução cruza um quadro agendado. Um avanço pode cruzar vários quadros, e o sistema considera uma passagem normal ou o retorno de um loop. Pausa, clique na barra de progresso e navegação manual não disparam sozinhos os efeitos.

**Limite atual:** múltiplas voltas completas da timeline em uma única atualização não são contabilizadas individualmente; cada agendamento pode disparar no máximo uma vez por atualização. O sistema também não garante sincronização por amostra, áudio contínuo longo ou mistura polifônica do mesmo WAV (o recurso é reiniciado).

## Compatibilidade

`src/package_v6.lua` delega formatos LUAFGAME 1–5 aos leitores anteriores e preserva sua representação ao regravar. O Studio continua separado; `.lflash` não foi modificado.

Ferramenta de publicação:

```bash
lua tools/animate_media.lua base-v5.lfgame resultado-v6.lfgame 1 7 novo.png som_1 23
```
