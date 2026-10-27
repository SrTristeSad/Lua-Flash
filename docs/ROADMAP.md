# Lua-Flash — Player Lua e Studio Lua

## Escopo

Uma plataforma moderna de autoria e execução de jogos/animações usando Lua e formatos independentes. Não há obrigação de executar SWF/FLA/XFL ou ActionScript antigos. O Flash Player original é uma referência histórica de comportamento, não uma fonte de código fechado para redistribuição.

- [`player-lua/`](../player-lua/) — runtime (projeto atual).
- [`studio-lua/`](../studio-lua/) — editor visual separado, mantido sem alterações nesta etapa.
- `src/model.lua` e `src/runtime.lua` continuam iguais nos dois aplicativos, com teste de sincronização.

## 0.1–0.3: etapas anteriores

- [x] Editor e Player separados, com formato nativo `.lflash`.
- [x] Reprodução, interpolação opcional, scrub, velocidade e loop.
- [x] Mouse, toque, teclado e hit-testing por forma/camada.
- [x] Minijogo de exemplo integrado ao Player.
- [x] CI com verificação de código, testes de callbacks e renderização real via LÖVE/Xvfb.

## 0.4: jogos independentes do código do Player

- [x] **LUAFGAME 1** — primeiro formato próprio `.lfgame` contendo cena `.lflash` e regras.
- [x] Interpretador restrito de ações de pontuação, busca de quadro, pausa e reprodução.
- [x] Clique/toque em formas e eventos de teclado como gatilhos das regras.
- [x] Vitória por meta, cronômetro, encerramento e placar sobre o palco.
- [x] Carregamento de arquivos externos sem executar código Lua deles.
- [x] Ferramentas `tools/export_example.lua` e `tools/make_game.lua`.
- [x] Testes para arquivos truncados/ilegais e interoperabilidade do formato.
- [x] Pacote Player 0.4 em `.love` e exemplos exportáveis.
- [ ] Avaliação manual com usuários e verificação de desempenho em dispositivos reais.

## 0.5 — próximos fundamentos

- [ ] IDs estáveis para objetos e instâncias, sem depender do índice da forma.
- [ ] API de eventos e hierarquia de cenas.
- [ ] Ações declarativas mais abrangentes com estados locais, colisões e transições.
- [ ] Importar e gerenciar imagens, fontes e áudio.
- [ ] Definir um mecanismo de permissões e isolamento antes de introduzir scripts de jogos fornecidos por terceiros.
- [ ] Publicação e distribuição multiplataforma além do `.love`.

## Filosofia

Compatibilidade entre nossos formatos próprios e nenhuma regressão voluntária das ferramentas já estáveis. **Formato declarativo não equivale a execução arbitrária de Lua**: a segurança é reforçada mantendo essa separação clara.
