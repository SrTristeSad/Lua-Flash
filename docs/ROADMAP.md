# Lua-Flash — roadmap do Player

## Meta

Runtime independente de animações/jogos em Lua/LÖVE para PC, sem dependência de SWF, FLA ou ActionScript antigos. O Player (`player-lua/`) permanece separado do Studio (`studio-lua/`).

## Base implementada até 0.16

- [x] Reprodução vetorial, timeline, interpolação e velocidades.
- [x] Jogos declarativos LUAFGAME 1–9, mídias PNG/WAV e sprites animados.
- [x] Mouse, teclado, toque, máscaras alfa e colisão temporal.
- [x] Editor visual de quadros-chave, rotação, escala e easing.
- [x] Undo/redo de 32 alterações e recuperação básica.
- [x] Testes em Lua e LÖVE, empacotamento `.love`.

## Player 0.17 — recuperação e diagnóstico

- [x] Cópias de recuperação isoladas por jogo original, sem utilizar um nome global compartilhado.
- [x] Rotação de dois slots com sequência e verificação de integridade.
- [x] Rejeição de recuperação corrompida ou pertencente a outro jogo.
- [x] Recuperação apenas quando não há edições pendentes no projeto atual.
- [x] Proteção contra abertura acidental de outro projeto com alterações não salvas.
- [x] F3 com FPS, duração de atualização, memória Lua e contagem de elementos.
- [x] Testes de corrupção, falha de escrita, isolamento, reset e indicadores.
- [x] Compatibilidade com LUAFGAME 1–9, sem alterar Studio.
- [ ] Gravação atômica no nível do sistema operacional e histórico persistente.
- [ ] Perfil de GPU/CPU e testes reais com projetos grandes.

## Prioridades até a versão 1.0 de PC

- [ ] Robustez de carga, logs de erro e relatórios de crash.
- [ ] Testes de estresse em cenas reais maiores e melhorias de memória/CPU.
- [ ] Áudio polifônico e canais independentes.
- [ ] Melhorias ergonômicas no editor e importação de mídia.
- [ ] Windows standalone com LÖVE incorporado, além de empacotamentos Linux/macOS.
- [ ] Validação de instalação, experiência de uso e estabilidade em máquinas reais.

O Studio ainda não foi modificado e os jogos importados não executam código Lua fornecido por terceiros.
