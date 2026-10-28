# Lua-Flash — roteiro de desenvolvimento do Player

## Objetivo

Motor de animação/jogos Lua/LÖVE, com formatos próprios LUAFGAME 1–9 e `.lflash`, sem compatibilidade com SWF/FLA/ActionScript. O Player fica em `player-lua/`, enquanto o Studio permanece em `studio-lua/` sem alterações nas etapas do Player.

## Entregas até 0.26

- [x] Timeline, keyframes, interpolação, easing e sprites com transformação.
- [x] PNG/WAV, áudio polifônico, regras de jogo, colisões e controles.
- [x] Editor, undo/redo, recuperação de projeto, diagnóstico e logs.
- [x] Windows x64 portátil com runtime LÖVE, seletor Unicode, ícone e VERSIONINFO.
- [x] Interface adaptável, navegação por teclado, alto contraste e tamanho de fonte.
- [x] Testes de compatibilidade, cenário com 11.520 formas e simulação virtual de longa duração.

## Player 0.27 — gargalos e medição

- [x] Índice por camada com busca binária para reprodução vetorial exata.
- [x] Reutilização limitada a uma cena por documento/quadro.
- [x] Sem mutação de dados ou alterações no renderizador compartilhado com Studio.
- [x] Contadores de cache no F3.
- [x] Monitoramento de CPU de `update`/`draw` com histórico circular de 120 amostras.
- [x] Teste de regressão do cache com 18 camadas e 11.520 formas.
- [x] Teste de 40.000 amostras de medição sem crescimento indefinido.
- [x] Versão Windows 0.27.0.0 e compatibilidade LUAFGAME preservada.
- [ ] Medir ganho real de FPS/CPU com GPU e hardware físico.
- [ ] Perfil de renderização interpolada, sprites/mídias e colisões em jogos grandes reais.

## Até o Player 1.0 para PC

- [ ] Otimização de interpolação e recorte de formas fora da tela.
- [ ] Benchmarks Windows/Linux com diferentes GPUs, CPUs e DPI.
- [ ] Testes prolongados em hardware físico, incluindo áudio.
- [ ] Resolver bugs críticos e expandir navegação/acessibilidade.
- [ ] Assinatura digital e instalador opcional.

O Player permanece experimental até a homologação de estabilidade.
