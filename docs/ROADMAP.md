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
