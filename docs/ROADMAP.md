# Lua-Flash — roadmap do Player

## Objetivo

Construir um runtime para jogos/animações em Lua e formatos próprios, sem executar SWF/FLA/ActionScript. O Player (`player-lua/`) permanece separado do Studio (`studio-lua/`).

## Base implementada — 0.1 a 0.18

- [x] Timeline vetorial, interpolação de poses, easing e edição de quadros-chave.
- [x] LUAFGAME 1–9: recursos PNG/WAV, sprites, regras e colisões.
- [x] Mouse, toque, teclado, máscaras alfa, transformações e colisões temporais.
- [x] Undo/redo, recuperação verificada por projeto e logging local de falhas Lua.
- [x] Teste de estresse com 11.520 formas vetoriais e validação LÖVE com display virtual.

## Player 0.19 — áudio robusto

- [x] Sons WAV simultâneos com pool de fontes `Source`.
- [x] Limites de 16 vozes totais e 4 por WAV, com reutilização de vozes mais antigas.
- [x] Volume por categoria de efeitos/timeline e volume mestre.
- [x] Controles F5/F6/F7, mantendo F8/F9/F10.
- [x] Cues temporais repetidos corretamente em múltiplas voltas, com limite de 64 disparos por atualização.
- [x] Diagnóstico de vozes e categorias no painel F3.
- [x] Testes de reprodução simulada, limites, eventos e smoke com áudio real do LÖVE.
- [x] Compatibilidade LUAFGAME 1–9 e Studio preservado.
- [ ] Testes de latência e mixagem com dispositivo de áudio real, especialmente Windows.

## Próximos passos rumo ao Player 1.0 para PC

- [ ] Melhorar reprodução de faixas longas, música de fundo e transições suaves de áudio.
- [ ] Instrumentação de CPU/GPU e otimização dos recursos em projetos reais grandes.
- [ ] Melhorar importação, mensagens de erro e recuperação em cenários reais.
- [ ] Construir e testar uma distribuição **Windows standalone com LÖVE incorporado**.
- [ ] Testes manuais de instalação, estabilidade e usabilidade em Windows/Linux.

O formato continuará declarativo até haver um projeto separado de sandbox para scripts Lua externos.
