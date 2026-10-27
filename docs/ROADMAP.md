# Lua-Flash — Player e Studio independentes

## Objetivo

Criar uma plataforma nova de criação e execução de jogos e animações em Lua, sem obrigação de compatibilidade com SWF/FLA/XFL e ActionScript do Adobe Flash. Estudamos comportamentos e ideias do Flash original, mas não reutilizamos seu código proprietário.

## Projetos

- **[player-lua/](../player-lua/)**: foco de desenvolvimento atual, runtime em Lua + LÖVE.
- **[studio-lua/](../studio-lua/)**: editor visual, preservado em pasta separada.
- O modelo e a renderização compartilhados são verificados por `tools/sync_core.py`.

## Player 0.1–0.2 — fundação e reprodução

- [x] Abre documentos nativos `.lflash` com formas e camadas.
- [x] Player e Studio independentes.
- [x] Controle de quadros, velocidade, loop, tela cheia e timeline.
- [x] Interpolação visual opcional de formas compatíveis.
- [x] Testes automatizados e pacote `.love` independente.

## Player 0.3 — entrada e interação

- [x] Mapeamento de coordenadas de palco com redimensionamento e letterboxing.
- [x] Hit-testing de formas, camadas e quadros interpolados.
- [x] Eventos de mouse, toque e teclado; captura e cancelamento de ponteiros.
- [x] Minijogo de acerto ao alvo, com pontuação, cronômetro, clique, toque e mira pelo teclado.
- [x] Testes unitários de interatividade e smoke test na CI.
- [x] Empacotamento da versão 0.3 em `.love`.
- [ ] Testes gráficos reais e benchmarks com LÖVE.

## Próximas prioridades — Player 0.4

- [ ] Especificar APIs de eventos para **conteúdos criados por terceiros**, com modelo de segurança e permissões.
- [ ] Publicação de jogos em formato próprio, separado do documento do Studio.
- [ ] Objetos e instâncias com nomes/IDs estáveis para interações.
- [ ] Controles de gamepad e suporte móvel melhorado.
- [ ] Áudio, sincronização da timeline e otimização de desenho.

## Mais adiante

- [ ] SDK/runtime para projetos Lua com sandbox.
- [ ] Arte vetorial avançada, símbolos, sprites, máscaras e hierarquias.
- [ ] Builds Windows/Linux/macOS testados; Android e web exigem trabalhos específicos.

**O Player 0.3 é experimental.** Testes automatizados não garantem usabilidade ou estabilidade gráfica em todos os dispositivos.
