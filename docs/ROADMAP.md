# Lua-Flash: Player Lua + Studio Lua

## Escopo

Criar um novo ecossistema de autoria e execucao visual usando Lua e um formato proprio `.lflash`. **Nao oferecer compatibilidade com SWF, FLA, XFL ou ActionScript da Adobe.** A engenharia reversa do Flash original serve para estudar conceitos e comportamento, nao para reutilizar executaveis ou codigo fechado.

## Estrutura (a partir de 0.1)

- `player-lua/`: aplicativo independente de reproducao (foco atual).
- `studio-lua/`: aplicativo independente para criar e editar animacoes.
- `tools/sync_core.py`: mantem o modelo e o renderizador identicos nos dois apps.
- `tests/`: testes de interoperabilidade e logica (sem precisar de GPU).

Os aplicativos sao independentes no LÖVE. Os modulos `src/model.lua` e `src/runtime.lua` existem em ambos para empacotamento autonomo, com verificacao automatizada de igualdade de conteudo. **Nao editar copias divergentes.**

## 0.1 — separacao e reproducao basica

- [x] Player e Studio em pastas separadas, ambos com `main.lua` e `conf.lua`.
- [x] Player com animacao propria de demonstracao, play/pause, barra de navegacao, loop e tela cheia.
- [x] Player carrega `.lflash` por arrastar e soltar ou ultimo projeto salvo no Studio.
- [x] Studio preserva ferramentas de desenho e quadros-chave.
- [x] Compartilham modelo de documento, formato nativo e renderizador.
- [x] Testes de codec e frame-clock em CI.
- [ ] Testes graficos manuais completos no LÖVE desktop.

## 0.2 — Player Lua

- [ ] Interpolacao, mascaras, instancias e transformacoes.
- [ ] Video/audio e sincronizacao robusta de timeline.
- [ ] Eventos de mouse, teclado e touch e interface para jogos.
- [ ] Formato de publicacao proprio, diferente do projeto de edicao.
- [ ] Sandbox para scripts Lua que forem embutidos por autores.

## 0.3 — Studio Lua

- [ ] Biblioteca e simbolos reutilizaveis, interpolacao editavel, curvas e layers.
- [ ] Publicacao para o runtime comum e validacao cruzada com Player.

## 1.0

- [ ] Desktop validado: Windows/Linux/macOS.
- [ ] Android e web por backends dedicados testados.
- [ ] Empacotamento e performance de producao.
