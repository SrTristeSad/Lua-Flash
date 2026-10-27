# Lua-Flash — desenvolvimento por projetos

## Objetivo

Criar um novo ecossistema Flash em Lua, com projeto autoral próprio (`.lflash`), **sem retrocompatibilidade obrigatória com o Adobe Flash Player, SWF, FLA, XFL ou ActionScript**. Engenharia reversa de programas antigos serve como estudo de comportamento, não reprodução de código proprietário.

## Organização

- [`player-lua/`](../player-lua/) — **foco atual**. Executa projetos de animação Lua-Flash.
- [`studio-lua/`](../studio-lua/) — editor visual preservado em pasta independente.
- Modelo `model.lua` e renderizador `runtime.lua` espelhados, com igualdade validada pelo `tools/sync_core.py`.

## Player 0.2 — núcleo e controles

- [x] Aplicativos Player e Studio separados.
- [x] Player com demo animada própria, arrastar/soltar `.lflash`, timeline e tela cheia.
- [x] Transporte independente para play/pause, speed 0,25×–4×, scrub, loop e encerramento.
- [x] Interpolação visual opcional por camada entre keyframes com shapes compatíveis.
- [x] Exibição exata por padrão de projetos externos, para evitar mudanças não solicitadas.
- [x] Testes automatizados do modelo, transporte, visualização simulada e interoperabilidade.
- [ ] Validação visual real e benchmarks em Windows/Linux/macOS.

## Player 0.3 — funções prioritárias

- [ ] Suporte a símbolos e instâncias independentes de objetos.
- [ ] Interpolação controlada por metadados do projeto (com easing e propriedades por objeto).
- [ ] Mouse, teclado e touch dentro do palco, com APIs estáveis para jogos.
- [ ] Áudio e sincronização com a timeline.
- [ ] Formato próprio de publicação separando dados editáveis e conteúdo distribuído.
- [ ] Sistema de permissões/sandbox antes de permitir scripts de terceiros.

## Futuro

- [ ] Manter editor e Player compatíveis **com nossos próprios projetos**.
- [ ] Empacotar Player Windows/Linux/macOS.
- [ ] Backends Android e Web, com testes específicos.
- [ ] Otimização de CPU/GPU e recuperação de arquivos.

A versão 0.2 é experimental, e testes unitários não substituem homologação gráfica.
