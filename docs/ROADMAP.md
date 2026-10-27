# Lua-Flash — roteiro do Player

## Direção

Recriar o conceito de plataforma Flash com formatos e runtime próprios em Lua, sem exigir retrocompatibilidade com SWF/FLA/XFL ou ActionScript antigos.

- [`player-lua/`](../player-lua/) — desenvolvimento do runtime (atual).
- [`studio-lua/`](../studio-lua/) — editor separado, mantido intacto nesta atualização.
- Codec de projetos `.lflash` e renderizador continuam sincronizados sem mudança no formato original.

## Base 0.1–0.5

- [x] Linha do tempo, reprodução, loop, velocidade e interpolação.
- [x] Eventos de teclado/mouse/touch, hit-testing e minijogo.
- [x] LUAFGAME 1 e 2: regras declarativas, pontuação, estados e condições.
- [x] Exportação e reimportação de jogos com formato próprio.
- [x] Testes Lua e inicialização gráfica com LÖVE/Xvfb na CI.

## Player 0.6 — identidade por quadro-chave e colisões

- [x] **LUAFGAME 3**: IDs de objetos mais `BIND` explícito por quadro-chave.
- [x] Permite o mesmo objeto ocupar índices diferentes em quadros-chave distintos.
- [x] **COLLIDE**: eventos de entrada em colisão entre objetos nomeados.
- [x] Ações declarativas existentes acionáveis por colisão e teclado/mouse.
- [x] Interpolação opcional também usada na detecção de colisão.
- [x] Testes de entrada/saída/reentrada em colisão, vínculos e arquivos inválidos.
- [x] Leitura de LUAFGAME 1, 2 e 3 sem conversão obrigatória.
- [x] Pacote `.love` autônomo em relação ao Studio e demo de barreira.
- [ ] IDs gravados no modelo visual `.lflash` e preservados ao editar no Studio.
- [ ] Testes manuais e benchmarks em máquinas reais.

## Próximas versões

- [ ] Audiovisual: áudio e efeitos sincronizados, importação de imagens.
- [ ] Formas e colisões precisas: traços, curvas e hierarquia de objetos.
- [ ] API de objetos e cenas em Lua **com isolamento definido antes de habilitar scripts externos**.
- [ ] Runtime nativo para Windows, Linux, macOS e depois Android/Web.
- [ ] Sistema de permissões, documentação de autoria e publicação estável.

A engenharia reversa de tecnologia Flash serve como referência histórica de comportamento, não para redistribuir binários/código da Adobe.
