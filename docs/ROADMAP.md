# Lua-Flash — roteiro do Player

## Objetivo

Motor independente para animações e jogos em Lua/LÖVE. Player em `player-lua/`, Studio em `studio-lua/` sem alterações. Formatos próprios LUAFGAME 1–9 e `.lflash`, não SWF/FLA/ActionScript.

## Base implementada — 0.1 até 0.22

- [x] Timeline, formas, keyframes, easing, sprites, PNG/WAV.
- [x] Regras, estados, colisões e clique/toque por máscaras.
- [x] Editor visual, histórico, recuperação, áudio polifônico e diagnósticos.
- [x] Windows x64 portátil com LÖVE 11.5 e arquivos nativos abertos pelo Windows.
- [x] Ícone de janela, seletor Win32 Unicode, testes LÖVE e GitHub Actions.

## Player 0.23 — compatibilidade visual Windows

- [x] Área de trabalho virtual proporcional para janelas pequenas e grandes.
- [x] Inversão de coordenadas mouse/toque e recorte do palco coerente com escala.
- [x] Suporte `highdpi` da janela e layout em unidades lógicas.
- [x] Ícone original no recurso PE do `.exe`, com Win32 RT_ICON/RT_GROUP_ICON.
- [x] Testes de desenho em 640 × 400 e outras resoluções.
- [x] Testes de integridade e leitura do ícone no PE Windows.
- [x] Compatibilidade com formatos anteriores e Studio preservado.
- [ ] Testes manuais com monitores de diferentes escalas DPI e GPUs reais.
- [ ] Layout verdadeiramente refluido para telas ultrapequenas.

## Prioridades rumo à versão 1.0

- [ ] Polir navegação, textos, acessibilidade e menus em resoluções variadas.
- [ ] Perfil de renderização, CPU e GPU com jogos grandes em hardware real.
- [ ] Metadados de versão no executável, assinatura digital e atualizações.
- [ ] Instalador opcional e associação de arquivos com permissão do usuário.
- [ ] Testes de longa duração e importação de arquivos hostis.
- [ ] Homologação de uso real no Windows/Linux antes da versão estável.

O Player é experimental até que a usabilidade, estabilidade e distribuição sejam validadas.
