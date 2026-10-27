# Lua-Flash — roteiro do Player

## Objetivo

Construir uma plataforma de animações e jogos usando Lua e formatos próprios. O Player (`player-lua/`) e o Studio (`studio-lua/`) permanecem separados. Não há obrigação de compatibilidade com Adobe SWF/FLA/ActionScript antigos.

## Player 0.1–0.12

- [x] Reprodução de formas, keyframes, interpolação, velocidades e loops.
- [x] Eventos de teclado/mouse/toque, regras declarativas, estados e colisões.
- [x] Formatos LUAFGAME 1–7, incluindo PNG/WAV, sprites, máscaras de alfa e áudio na timeline.
- [x] Transformação estática de sprites: rotação, escala e pivô.
- [x] Verificação temporal amostrada de colisões rápidas.
- [x] CI automatizada Lua e LÖVE gráfico em ambiente virtual.

## Player 0.13 — transformações animadas

- [x] **LUAFGAME 8** com `TWEEN` e `KEY`.
- [x] Deslocamentos por quadro-chave sobre STATIC/FOLLOW.
- [x] Rotação pelo caminho angular curto e escala X/Y interpolada.
- [x] Desenho, hit-testing, alfa e colisão baseados na mesma pose da timeline.
- [x] Ferramenta de autoria `tools/animate_transform.lua`.
- [x] Demonstração original com transformação animada.
- [x] Testes de pacotes inválidos, compatibilidade v1–v7 e colisões móveis.
- [ ] Verificação manual de interface e desempenho em dispositivos reais.

## Próximas etapas

- [ ] Editor visual de keyframes e curvas de easing para sprites.
- [ ] Colisões contínuas mais precisas, composição/hierarquia de objetos.
- [ ] Áudio polifônico, canais e sincronização temporal refinada.
- [ ] IDs persistentes no formato editável e evolução coordenada com Studio.
- [ ] Aplicativo desktop standalone, com LÖVE incorporado, Windows/macOS/Linux.
- [ ] Scripts Lua de terceiros somente com modelo sólido de sandbox, permissões e auditoria.

O Studio não recebe alterações nesta versão.
