# Lua-Flash Player 0.28 — culling vetorial e interpolação otimizada

Player experimental em Lua/LÖVE para animações `.lflash` e jogos `.lfgame` LUAFGAME 1–9. O Studio permanece separado e não foi modificado.

## Ignorar formas totalmente fora da tela

O novo módulo `src/viewport_renderer.lua` é um renderizador exclusivo do Player. Antes de enviar as formas vetoriais ao LÖVE, ele calcula seus limites geométricos em **coordenadas do documento** e não desenha formas completamente fora de `[0, doc.width] × [0, doc.height]`.

Por segurança, pinceladas e linhas incluem a metade da espessura do traço mais uma pequena margem. Isso evita descartar uma linha cujo centro está fora do palco, mas cujo traço alcança a borda. Retângulos, elipses, linhas e pincéis continuam usando as mesmas primitivas gráficas do renderizador anterior; a ordem de desenho e a visibilidade das camadas são preservadas.

As dimensões do palco não mudam. O recorte gráfico usa coordenadas da janela convertidas para a escala responsiva, evitando recortes desalinhados em janelas compactas como 640 × 400.

Um cache de limites com chaves fracas reutiliza cálculos para formas originais sem segurar na memória todas as formas interpoladas descartadas. Esse cache pressupõe uma cena autoral estável; ao modificar formas vetoriais em memória, é necessário chamar `renderer:invalidate()`. Abrir outro projeto no Player cria um novo renderizador e limpa esses dados automaticamente.

**Limitações:** as formas são examinadas individualmente; descartar uma forma evita sua chamada de desenho, mas o algoritmo ainda tem custo linear pelo número de formas visíveis ou potencialmente externas. Não é um *spatial index* e não realiza culling de sprites PNG neste estágio. Também não promete aumento de FPS em todos os jogos.

## Compatibilidade de quadros-chave calculada uma vez

O `src/interpolation.lua` agora calcula no `I.new` a compatibilidade de cada par de chaves adjacentes, com `reindex()` explícito para mudanças no documento. Durante a reprodução, a busca binária identifica o segmento e consulta o resultado da compatibilidade já calculada.

Formas com mesmo tipo e mesmo número de pontos continuam sendo interpoladas. Listas ou formas incompatíveis **seguram a forma do quadro anterior**, exatamente como antes. Quadros exatos continuam referenciando as formas autorais, sem cópias desnecessárias.

## F3 e testes

O painel F3 apresenta quantas formas foram desenhadas e quantas foram ignoradas por estarem fora da tela no quadro atual. Mantém também CPU média/máxima de desenho e atualização, memória Lua, diagnóstico de recursos e áudio.

Testes adicionados:
- `tests/viewport_renderer_test.lua` — bordas, pinceladas, linhas grossas, retângulos, elipses, cache e janela 640 × 400.
- `tests/interpolation_segments_test.lua` — compatibilidade pré-calculada, formas incompatíveis e invalidação da lista de segmentos.
- `tests/culling_stress_test.lua` — 18 camadas, 32 chaves por camada e 20 formas por chave (**11.520 formas**). Compara o número de primitivas desenhadas pelo renderizador antigo e pelo novo e verifica amostras interpoladas.

Esses testes não equivalem a medições físicas de GPU/VRAM. Ainda é necessário comparar desempenho e qualidade visual em PCs Windows reais e jogos com mídias PNG grandes.

## Distribuição

O ZIP Windows x64 inclui o motor LÖVE 11.5 oficial, seu ícone original, DLLs e metadados de arquivo **0.28.0.0**. Não exige instalar LÖVE, mas continua sem assinatura digital. O pacote `.love` permanece disponível para outros sistemas.

Os comandos anteriores continuam: F1 ajuda; F2 alto contraste; F3 diagnósticos; Ctrl+O abrir; Ctrl+S salvar; Ctrl+Z/Y desfazer/refazer; E editor; Ctrl+mais/menos/zero alterar tamanho de fonte.

## Executar verificações

```bash
lua tests/viewport_renderer_test.lua
lua tests/interpolation_segments_test.lua
lua tests/culling_stress_test.lua
lua tests/gui_smoke.lua
python3 tools/package_player.py
```

O Studio não foi alterado, e o formato LUAFGAME 9 continua compatível.
