# Lua-Flash — roteiro do Player

## Objetivo

Reprodutor independente de jogos/animações em Lua e formatos próprios; não executa SWF/FLA/ActionScript. O Player fica em `player-lua/` e o Studio em `studio-lua/`, sem mudanças nas etapas de Player.

## Base implementada — 0.1 a 0.21

- [x] Timeline vetorial, keyframes, easing e edição de sprites.
- [x] Mídia PNG/WAV, estados, eventos, áudio polifônico e colisões.
- [x] Undo/redo, recuperação por projeto, diagnósticos e logs locais.
- [x] Pacotes LUAFGAME 1–9 e `.lflash`, sem execução de scripts externos.
- [x] Player `.love` e Windows x64 portátil com o LÖVE incorporado.
- [x] Drag/drop, Ctrl+O para caminho, abertura por argumento e lançador portátil.
- [x] Testes Lua, integração LÖVE, empacotamento Windows e estresse sintético.

## Player 0.22 — abertura e identidade original

- [x] Seletor nativo Windows com filtros de formatos.
- [x] Leitura de caminhos Unicode por API Win32, com limites de tamanho.
- [x] Cancelamento do diálogo preserva o jogo aberto.
- [x] Ctrl+Shift+O conserva o campo manual de caminhos.
- [x] Ícone original de raio aplicado à janela e incluído como arquivo `.ico` no pacote portátil.
- [x] Testes de fallback e de integridade do ícone/empacotamento.
- [x] Compatibilidade LUAFGAME 1–9 e Studio preservado.
- [ ] Teste manual do diálogo interativo e de UTF-16 em vários Windows reais.
- [ ] Ícone incorporado no recurso PE e informações de versão do executável.

## Rumo ao Player 1.0

- [ ] Homologar a interface e os controles em máquinas Windows reais.
- [ ] Incorporar ícone, metadados de versão e assinatura digital no executável.
- [ ] Ajustar interface para escalonamento DPI, janelas pequenas e acessibilidade.
- [ ] Perfis de desempenho com GPU/CPU e jogos reais grandes.
- [ ] Instalação opcional e integração de arquivos (com consentimento do usuário).
- [ ] Testes de resistência, erros e recuperação em hardware real.

O Player permanece experimental. O Studio não recebeu alterações.
