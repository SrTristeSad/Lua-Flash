# Lua-Flash — roadmap do Player

## Direção

Runtime independente em Lua, sem executar SWF/FLA/ActionScript antigos. **Player** em `player-lua/`; **Studio** em `studio-lua/`, preservado.

## Base 0.1–0.11

- [x] Timeline vetorial, quadros-chave, velocidade, loop e interpolação.
- [x] Mouse, toque, teclado, minijogos e hit-testing.
- [x] LUAFGAME 1–6 com regras declarativas, estados, colisões, mídia e animação de PNG.
- [x] Máscaras de alfa, cache de imagens e colisão temporal amostrada.
- [x] Build `.love`, CI Lua e inicialização gráfica com LÖVE real.

## Player 0.12 — transformações

- [x] **LUAFGAME 7**: rotação, escala X/Y e pivô de sprites PNG.
- [x] Renderização por transformação nativa do LÖVE.
- [x] Inversão de coordenadas para cliques e testes de transparência.
- [x] Colisões entre sprites transformados e formas vetoriais com máscara amostrada.
- [x] Ferramenta `tools/transform_sprite.lua` e demo transformada.
- [x] Leitura e regravação dos formatos anteriores sem conversão.
- [x] Testes de transformação, leitura de pacotes inválidos e integração gráfica.
- [ ] Validação manual de desempenho em máquinas físicas.

## Próximas etapas

- [ ] Keyframes e interpolação de rotação, escala e posição dos sprites.
- [ ] Colisão contínua geometricamente mais robusta e tratamento de contatos muito pequenos.
- [ ] Áudio com canais independentes e gerenciamento de fontes.
- [ ] IDs persistentes dentro do modelo de autoria e possível integração com Studio.
- [ ] Builds Windows/macOS/Linux executáveis sem instalação separada do LÖVE.
- [ ] Ambiente seguro de scripts externos com isolamento e permissões antes de habilitar Lua de terceiros.

O Editor Studio não recebeu mudanças nesta versão.
