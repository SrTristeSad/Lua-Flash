# Lua-Flash — roteiro do Player

## Objetivo

Runtime independente de jogos e animações em Lua/LÖVE com formatos próprios LUAFGAME 1–9 e .lflash. Player e Studio são aplicativos separados. Não executa SWF/FLA/ActionScript históricos.

## Entregas até a versão 0.23

- [x] Timeline, formas, sprites PNG/WAV, regras e estados.
- [x] Editor de quadros-chave, easing, undo/redo e recuperação.
- [x] Colisões, clique por máscaras, áudio polifônico.
- [x] Arquivos nativos com seletor Windows Unicode, diagnóstico e logs.
- [x] Windows portátil com ícone original embutido e interface adaptável.
- [x] Testes LÖVE, de estresse, integridade e CI Windows.

## Player 0.24 — navegação e versão do executável

- [x] Tab e Shift+Tab nos doze controles principais.
- [x] Enter executa controle em foco e Escape limpa a seleção.
- [x] Contorno de foco visível.
- [x] Painel F1 com os atalhos mais importantes.
- [x] Recurso nativo VERSIONINFO com nome Lua-Flash Player e versão 0.24.0.0.
- [x] Testes de foco, interação GUI e verificação Win32 de versão no EXE.
- [x] Studio preservado e formatos anteriores compatíveis.
- [ ] Navegação completa no editor e outras áreas.
- [ ] Integração com leitores de tela e testes de acessibilidade reais.

## Prioridades para 1.0 de PC

- [ ] Navegação integral pelo teclado, tradução e configurações de contraste.
- [ ] Benchmarks CPU/GPU e memória em jogos maiores no Windows.
- [ ] Assinatura digital e instalador opcional, sem alterar arquivos do usuário.
- [ ] Testes de estabilidade prolongada e atualização segura.
- [ ] Homologação visual e de desempenho em hardware real.

O Player continua experimental.
