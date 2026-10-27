# Lua-Flash — roteiro do Player

## Objetivo

Desenvolver uma plataforma de animação/jogos em Lua com formatos próprios, sem precisar emular SWF/FLA/ActionScript históricos. O Player é trabalhado em `player-lua/`, preservando o Studio em `studio-lua/`.

## Versões 0.1–0.6

- [x] Reprodução vetorial, timeline, interpolação visual e controles de velocidade/loop.
- [x] Mouse, toque, teclado, hit-testing e minijogo interno.
- [x] Jogos `LUAFGAME 1/2/3`: objetos nomeados, estados, condições, identidades por quadro-chave.
- [x] Eventos de entrada em colisão com regras declarativas.
- [x] Exportação de jogos próprios e testes automatizados (Lua/LÖVE).

## Player 0.7 — imagens e efeitos

- [x] **LUAFGAME 4**: mídia embutida em um pacote binário seguro.
- [x] Carregamento e renderização de imagens PNG em posições do palco.
- [x] Reprodução de WAV PCM curto em cliques, colisões e vitória.
- [x] Volume ligado/silenciado com F10 e limpeza de fontes de áudio ao abrir outro jogo.
- [x] Ferramenta `tools/attach_media.lua` para publicar um jogo com imagem/som.
- [x] Gerador de PNG e WAV originais para testes e exemplo interativo.
- [x] Compatibilidade de leitura com LUAFGAME 1, 2 e 3.
- [x] Testes de arquivos inválidos e inicialização gráfica real com mídia.
- [ ] Audio sincronizado com timeline, trilhas longas, sprites interativos e colisões.
- [ ] Validação de desempenho em dispositivos reais.

## Próximas prioridades (0.8)

- [ ] Hit-testing e colisões em sprites com IDs próprios.
- [ ] Sistema de áudio com múltiplos canais, reprodução agendada e volume por jogo.
- [ ] Objetos com IDs diretamente no formato de autoria e integração planejada com Studio.
- [ ] Otimizar desenho, cache de frames e carga de recursos.
- [ ] Projetar runtime Lua para jogos com sandbox antes de aceitar scripts externos.
- [ ] Distribuição Windows/Linux/macOS, Android e Web.

O Studio **não foi alterado** nesta versão.
