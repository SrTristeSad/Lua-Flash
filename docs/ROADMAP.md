# Lua-Flash — roteiro de desenvolvimento do Player

## Objetivo

Construir um runtime Lua/LÖVE independente para animações e jogos. O Player fica em `player-lua/`; o Studio, em `studio-lua/`, permanece separado. Não há compromisso de executar SWF/FLA/ActionScript antigos.

## Base implementada — 0.1 até 0.14

- [x] Animações vetoriais, timeline, reprodução, velocidade e interpolação.
- [x] Mouse, toque, teclado e regras declarativas de jogos.
- [x] LUAFGAME 1–9: sprites, áudio, animações, keyframes e curvas de easing.
- [x] Colisões, máscaras alfa e cache de dados visuais.
- [x] Painel inicial de seleção de sprites/trechos com curvas.
- [x] Testes Lua, teste LÖVE com display virtual e build `.love`.

## Player 0.15 — edição de keyframes

- [x] Inserção visual de quadro-chave com pose interpolada.
- [x] Remoção protegida de chaves, com saneamento de referências de easing.
- [x] Deslocamento temporal da chave sem cruzar outras chaves.
- [x] Ajuste X/Y por botões e arrastar o sprite no palco.
- [x] Destaque visual do sprite selecionado.
- [x] Atualização imediata do runtime após edição e salvamento em `.lfgame`.
- [x] Testes automatizados de rejeição de operações inválidas e integração GUI.
- [x] Formato LUAFGAME 9 e Studio preservados.
- [ ] Undo/redo e edição visual de escala e rotação.
- [ ] Homologação de usabilidade e desempenho em PC real.

## Prioridades para 1.0 (PC)

- [ ] Histórico de desfazer/refazer, edição completa de transformações e atalhos acessíveis.
- [ ] Estabilidade, logs e recuperação segura de erros em arquivos/projetos.
- [ ] Áudio com canais independentes, polifonia e ajustes de volume por categoria.
- [ ] Benchmarks, redução de memória e otimização com grandes cenas.
- [ ] Aplicativo Windows independente com LÖVE incorporado, seguido por Linux/macOS.
- [ ] Testes reais de instalação e uso antes da versão estável.

A API de scripts externos e as plataformas Android/Web ficam fora do escopo imediato do Player 1.0. Jogos importados continuam sem execução arbitrária de Lua.
