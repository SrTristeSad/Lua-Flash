# Lua-Flash — Player + Studio próprios, em Lua

## Missão

Ressuscitar a **ideia do Flash Player e do Flash Professional**: plataforma simples de criação, publicação e execução de experiências interativas. Não existe exigência de suporte a projetos antigos da Adobe.

**Fora do escopo, por decisão do projeto:** SWF, FLA, XFL, ActionScript, AVM1/AVM2 e compatibilidade retroativa com o Flash Player original.

## Produtos

- **Player:** motor próprio de exibição/interação para conteúdos desenvolvidos em Lua-Flash.
- **Studio:** editor visual familiar a quem utilizou Flash, com palco, ferramentas, timeline, camadas e recursos de autoria.
- **Núcleo:** modelo de cena, animação e arquivos `.lflash` compartilhados. A publicação final terá formato próprio, separado do documento de edição.

## Implementação inicial

- Lua como linguagem do núcleo.
- LÖVE 11.5 como biblioteca gráfica/entrada para a versão desktop inicial.
- Projeto .lflash textual experimental; ainda sujeito a evolução.
- Modelos e cenas criadas no Studio são desenhados pela **mesma implementação** no Player.
- Scripts de terceiros deverão ter sandbox/permissões antes de qualquer suporte público.

## Marcos

### 0.1 — Primeira base
- [x] Modelo de projeto, camadas e quadros-chave (`src/model.lua`).
- [x] Codec de arquivo próprio .lflash.
- [x] Renderizador compartilhado de formas e controle de quadros (`src/runtime.lua`).
- [x] Código inicial de interface de Studio e Player (`main.lua`).
- [x] Testes automatizados de modelo, codec e tempo de quadro.
- [ ] Verificação gráfica da interface com LÖVE instalado.
- [ ] Verificação manual da experiência de desenho e salvamento.

### 0.2 — Studio usável
- [ ] Ferramentas vetoriais completas, símbolos e biblioteca.
- [ ] Interpolação de movimento/forma, camadas de máscara, som e sprites.
- [ ] Sistema confiável de estados e projetos recuperáveis.
- [ ] Exportação de projeto para um formato de publicação específico.

### 0.3 — Player de jogos e aplicações
- [ ] API Lua para cenas, eventos de teclado/mouse/toque, animação e áudio.
- [ ] Scripts de terceiros em ambiente isolado, com permissões explícitas.
- [ ] Recursos de distribuição de projetos e gestão de assets.
- [ ] Otimização de memória, carga e FPS.

### 1.0 — Multiplataforma
- [ ] Windows, Linux e macOS testados e empacotados.
- [ ] Android com runtime/pacote próprio.
- [ ] Web via backend adequado e comprovado.

## Política de compatibilidade

Não oferecer compatibilidade legada; **preservar compatibilidade entre versões do próprio Lua-Flash** e escrever migrações quando o formato próprio evoluir. A pesquisa de engenharia reversa é para aprender com a experiência de criação/uso do Flash, não reaproveitar arquivos ou código fechado da Adobe.
