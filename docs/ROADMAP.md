# Lua-Flash — desenvolvimento do Player em Lua

## Direção

Criar uma plataforma moderna de animações e jogos com motor próprio em Lua. O antigo Adobe Flash serve como referência de experiência; arquivos SWF, FLA, XFL e ActionScript não são objetivos de compatibilidade.

- **[player-lua/](../player-lua/)** — produto em desenvolvimento.
- **[studio-lua/](../studio-lua/)** — editor visual separado; sem alterações nesta etapa.
- Renderizador e codec `.lflash` continuam compartilhados sem divergência.

## 0.1–0.4

- [x] Reprodução de cenas, camadas e quadros-chave, controle de tempo e interpolação opcional.
- [x] Entrada de mouse, teclado e toque, com hit-testing de formas.
- [x] Formato `LUAFGAME 1` com regras declarativas sem execução de código externo.
- [x] Publicação de jogos simples a partir de cenas do Studio.
- [x] Testes automatizados e inicialização gráfica no LÖVE com Xvfb.

## 0.5 — LUAFGAME 2

- [x] Nomes de objetos (`OBJECT`) usados por gatilhos `CLICKID`.
- [x] Estado local de partida (`STATE`), com ações `SET` e `ADD`.
- [x] Regras condicionais `WHEN` usando comparadores `GE`, `EQ` e `LE`.
- [x] Continuidade de leitura e gravação de jogos `LUAFGAME 1`.
- [x] Demonstração interativa e ferramenta de publicação `make_game.lua` usando v2.
- [x] Validação estrita de pacotes, limites e testes de arquivos inválidos.
- [ ] Identificadores de objetos persistentes no **modelo visual** independentemente da ordem da camada.
- [ ] Testes manuais e benchmarks em dispositivos reais.

## Prioridades de 0.6

- [ ] Objetos persistentes, hierarquia de instâncias e camadas interativas.
- [ ] Melhores regras e tratamento de colisão para jogos mais elaborados.
- [ ] Importação de imagens/áudio com sincronização.
- [ ] Modelo de permissões e sandbox antes de aceitar Lua escrito por terceiros.
- [ ] Otimização, builds desktop nativos e planejamento Android/Web.

O Studio não deve ser modificado apenas para acrescentar recursos específicos do Player, exceto quando houver plano de migração de arquivos compartilhados.
