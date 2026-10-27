# Lua-Flash — roteiro do Player

## Contexto

Estamos construindo uma plataforma de execução própria em Lua, sem retrocompatibilidade obrigatória com SWF/FLA/ActionScript históricos. O projeto possui aplicativos independentes: `player-lua/` (em desenvolvimento) e `studio-lua/` (preservado).

## Implementado — 0.1 a 0.10

- [x] Animações vetoriais `.lflash`, timeline, interpolação, velocidade e loop.
- [x] Entrada de teclado, mouse e toque; hit-testing de formas.
- [x] Jogos de dados LUAFGAME 1–6: objetos, eventos, estados, regras, mídia PNG/WAV, sprites animados e áudio por quadro.
- [x] Máscaras de transparência PNG, colisões de sprites e caches de máscara/interpolação.
- [x] Testes automatizados e inicialização gráfica via LÖVE em CI.

## Player 0.11 — movimento rápido

- [x] Amostragem temporal intermediária de colisões na reprodução automática.
- [x] Detecção de múltiplos contatos separados em uma única atualização.
- [x] Evitar falsos contatos durante navegação manual por quadros.
- [x] Registro correto de múltiplas voltas completas da timeline, mesmo quando termina no mesmo quadro.
- [x] Agenda WAV funcionando em ciclos de animação curtos.
- [x] Orçamento limitado de verificações (80 subamostras por atualização).
- [x] Deduplicação e preparação de pares de colisão por sessão.
- [x] Testes de barreiras atravessadas rapidamente, loops e retrocompatibilidade.
- [ ] Homologação visual e benchmarks Windows/Linux em máquinas físicas.

## Próximas etapas

- [ ] Transformações de sprites (rotação, escala, origem/pivô), incluindo click e colisão.
- [ ] Colisão contínua geométrica para casos onde amostragem temporal é insuficiente.
- [ ] Melhorias de áudio: canais independentes, mistura e sincronização fina.
- [ ] IDs persistentes no formato editável `.lflash` e integração com Studio.
- [ ] Build nativo Windows/macOS/Linux e planejamento Android/Web.
- [ ] Scripts externos isolados somente após projeto de sandbox e permissões.

O Studio não foi modificado na 0.11, e o formato de jogo segue LUAFGAME 6.
