# Lua-Flash — roteiro do Player

## Direção

Criar um runtime próprio para jogos e animações em Lua/LÖVE, sem compatibilidade obrigatória com SWF/FLA/ActionScript. O Player (`player-lua/`) continua sendo desenvolvido separadamente do Studio (`studio-lua/`).

## Implementado — versões 0.1–0.13

- [x] Reprodução vetorial, quadros-chave, controle de reprodução e interpolação.
- [x] Mouse, toque, teclado, regras declarativas e estados de jogo.
- [x] LUAFGAME 1–8: nomes de objetos, colisões, PNG/WAV, sprites animados, transformações e animação de poses.
- [x] Máscaras de transparência, cache e colisão temporal amostrada.
- [x] Testes Lua e LÖVE em monitor virtual, empacotamento .love.

## Player 0.14 — curvas e edição inicial

- [x] **LUAFGAME 9**: easing por segmento de transformação.
- [x] Linear, ease-in, ease-out, ease-in-out, smoothstep e STEP.
- [x] Mesma pose interpolada aplicada a desenho, mouse e colisões.
- [x] Painel dentro do Player para selecionar sprites/trechos e alternar curvas.
- [x] Gravação em `.lfgame` e conversão editável de v8 para v9.
- [x] Ferramenta `tools/set_easing.lua`.
- [x] Demonstração e testes de compatibilidade, integridade, interação.
- [ ] Interface para adicionar/excluir/mover keyframes e ajustar poses visualmente.
- [ ] Testes de usabilidade e desempenho em hardware real.

## Prioridades rumo à versão 1.0 para PC

- [ ] Edição visual mais completa de poses e quadros-chave.
- [ ] Otimização de CPU, memória e renderização para projetos maiores.
- [ ] Mistura de áudio e canais independentes.
- [ ] Tratamento de erros e recuperação segura de projetos.
- [ ] Pacote executável para Windows com runtime embutido e validação de instalação.
- [ ] Testes manuais e de estabilidade em Windows e Linux reais.

Depois da versão 1.0, o plano pode incluir Android/Web e um modelo de scripts externos com isolamento e permissões rigorosas. O Studio continua sem mudanças nesta versão.
