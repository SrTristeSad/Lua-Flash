# Lua-Flash — roteiro do Player

## Objetivo

Entregar um Player para PC com runtime próprio de animações/jogos em Lua e formatos declarativos, sem compatibilidade obrigatória com SWF/FLA/ActionScript. O Player permanece em `player-lua/`, separado do Studio em `studio-lua/`.

## Base 0.1–0.17

- [x] Reprodução vetorial, timeline, keyframes, easing e velocidades.
- [x] Jogos LUAFGAME 1–9 com mídias PNG/WAV, estados e regras.
- [x] Sprites interativos, transformações e colisões amostradas no tempo.
- [x] Editor de poses com histórico Undo/Redo e recuperação por projeto.
- [x] Diagnósticos F3, testes Lua e LÖVE em CI e pacote `.love`.

## Player 0.18 — falhas e cenas maiores

- [x] Proteção para callbacks principais do Player e tentativa de preservar a sessão após falha Lua.
- [x] Log local de erros limitado a 32 KiB e supressão de mensagens repetidas.
- [x] Aviso de falha e tela de emergência para exceções de renderização.
- [x] Busca binária de keyframes vetoriais por camada.
- [x] Teste sintético com 11.520 formas vetoriais e mais de 100 posições amostradas.
- [x] Testes de falhas injetadas, logs locais e comportamento da interface.
- [x] Compatibilidade LUAFGAME 1–9 e Studio preservado.
- [ ] Validação de FPS/VRAM e latência em jogos reais no Windows.
- [ ] Otimizações de alocação de renderização, colisões e recursos grandes.
- [ ] Recuperação diante de erros nativos do LÖVE (não garantida).

## Prioridades rumo ao Player 1.0 no PC

- [ ] Canais independentes e polifonia de áudio, sem interrupção indevida de efeitos.
- [ ] Perfil de CPU, renderização e colisões em hardware real; reduzir desperdícios.
- [ ] Testes mais abrangentes de importação de mídia e arquivos hostis.
- [ ] Melhorias no fluxo de edição e tratamento de erros de filesystem.
- [ ] Aplicativo Windows standalone com runtime LÖVE incorporado.
- [ ] Testar instalação e desempenho real antes de declarar versão estável.

Ainda não há suporte à execução de código Lua fornecido por jogos externos. Android e Web permanecem fora do escopo imediato da versão 1.0 para PC.
