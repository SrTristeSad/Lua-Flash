# Lua-Flash — roteiro do Player

## Objetivo

Player original de animações/jogos em Lua/LÖVE com formatos declarativos LUAFGAME 1–9 e `.lflash`, não Adobe SWF/FLA/ActionScript. O Studio permanece separado e intocado nas atualizações do Player.

## Entregas 0.1–0.24

- [x] Timeline, keyframes, easing, formas vetoriais e transformações.
- [x] Sprites PNG, áudio WAV polifônico, eventos, colisões e interação.
- [x] Editor visual, Undo/Redo, recuperação por projeto e logs.
- [x] Windows x64 portátil com LÖVE, ícone e VERSIONINFO; importação Unicode.
- [x] Interface escalável, foco por teclado na barra principal e ajuda F1.
- [x] Testes Lua, CI Windows e smoke gráfico com LÖVE.

## Player 0.25 — acessibilidade incremental

- [x] Tab/Shift+Tab e Enter nas ações do editor de quadros-chave.
- [x] Foco desenhado sobre o controle selecionado dentro do editor.
- [x] Recuperação do foco ao desaparecer uma linha de chave.
- [x] F2 para tema de alto contraste.
- [x] Preferência salva e restaurada em arquivo de dados estrito.
- [x] Testes de navegação, configurações, interface e compatibilidade.
- [x] Metadados Windows atualizados para 0.25.0.0; Studio não alterado.
- [ ] Integração completa com leitores de tela e tecnologias assistivas.
- [ ] Layout com listagem completa de chaves e opções de escala da fonte.
- [ ] Verificação manual de contraste e usabilidade em hardware real.

## Rumo ao Player 1.0

- [ ] Homologação Windows/Linux, incluindo áudio, GPU, DPI e carga prolongada.
- [ ] Perfil de CPU/GPU/VRAM em jogos grandes.
- [ ] Aprimorar acessibilidade, localização e mensagens de erro.
- [ ] Assinatura de código, instalador opcional e atualizações seguras.
- [ ] Decidir critérios de release e encerrar bugs críticos antes do 1.0.

O Player permanece experimental.
