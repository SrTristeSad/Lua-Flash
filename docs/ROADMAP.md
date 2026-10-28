# Lua-Flash — roteiro do Player

## Objetivo

Player independente de animações e jogos em Lua/LÖVE, com formatos declarativos LUAFGAME 1–9 e `.lflash`; não executa Adobe SWF/FLA/ActionScript. O Studio fica em `studio-lua/` e não recebe modificações nas etapas do Player.

## Entregas até 0.27

- [x] Timeline, quadros-chave, easing, sprites e renderização vetorial.
- [x] Jogos com PNG/WAV, áudio polifônico, regras, colisões e eventos.
- [x] Editor, Undo/Redo, backups verificados, logs e diagnósticos F3.
- [x] Windows x64 portátil com runtime oficial LÖVE, ícone e versão nativa.
- [x] Interface adaptável, teclado, alto contraste e tamanho de fonte.
- [x] Cache vetorial indexado e medição limitada de CPU no Player.
- [x] Testes Lua/LÖVE/Windows, estresse sintético e simulação de 20 minutos.

## Player 0.28 — culling e interpolação

- [x] Renderizador exclusivo do Player que ignora formas fora do palco.
- [x] Margens conservadoras de traço para preservar formas nas bordas.
- [x] Cache fraco de limites de formas com invalidação explícita.
- [x] Recorte do palco coerente com escala responsiva 640 × 400.
- [x] Compatibilidade de segmentos de interpolação pré-calculada e reindexável.
- [x] Contadores F3 de formas desenhadas e descartadas.
- [x] Testes de geometria, bordas, interpolação e cenário com 11.520 formas.
- [x] Pacotes LÖVE e Windows 0.28.0.0; Studio preservado.
- [ ] Comparações de FPS, CPU e GPU em máquinas físicas.
- [ ] Culling/otimização específica de sprites PNG e máscaras.

## Prioridades para o Player 1.0 de PC

- [ ] Testes de stress com sprites/mídia e jogos de verdade, não apenas formas vetoriais sintéticas.
- [ ] Melhorias de uso de GPU, CPU, memória e latência em hardware real.
- [ ] Otimizações de máscaras e desenho de sprites.
- [ ] Resolver falhas críticas, aperfeiçoar acessibilidade e documentação.
- [ ] Assinatura digital e distribuição opcional com instalador.
- [ ] Homologação prolongada com Windows e Linux reais.

O Player continua experimental.


## Direção de desenvolvimento após 0.28

**Prioridade: 80% Studio / 20% Player.** O Studio será a ferramenta principal de autoria; o Player continuará um programa gráfico independente, sem regressão para terminal obrigatório. Comandos de terminal serão opcionais para automação, CI, empacotamento e diagnóstico. Ambos compartilham o formato `.lflash`, não uma interface monolítica.

### Studio (prioridade imediata)

- [x] Base de desenho, timeline, camadas e prévia integrada.
- [x] Projeto novo, mostrar/ocultar e bloquear/desbloquear camada por teclado.
- [x] Pacote independente `.love` e teste de regressão da edição.
- [ ] Fluxo de projetos com nomes, Salvar como, confirmação de substituição e arquivos recentes.
- [ ] Gerenciamento visual de camadas (visibilidade, bloqueio, ordem e renomeação).
- [ ] Timeline com zoom, rolagem, seleção múltipla e operações entre quadros.
- [ ] Importar mídias e editar objetos, sprites, áudio e eventos com prévia no Player.
- [ ] Exportação de jogo pelo Studio com validação LUAFGAME e testes de ida e volta.
- [ ] Testes visuais e de usabilidade, inclusive janelas menores e projetos grandes.
- [ ] Builds Windows independentes e homologação antes de qualquer rótulo 1.0.

### Player (manutenção e CLI opcional)

- [x] Interface gráfica, reprodução vetorial, mídia e LUAFGAME 1–9.
- [x] Opção de abrir arquivo como argumento de linha de comando.
- [ ] Preservar a GUI como fluxo padrão e documentar interface CLI sem duplicar o runtime.
- [ ] Corrigir regressões achadas pelo Studio e priorizar estabilidade, não novas features.
- [ ] Medição em hardware físico e testes prolongados para homologação.

**Critério de 1.0:** criar e salvar projeto no Studio, abrir e reproduzir no Player, exportar, reabrir sem perder dados e executar builds Windows estáveis com testes de regressão. A CI automatizada não substitui testes físicos.
