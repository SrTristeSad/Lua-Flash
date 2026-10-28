# Lua-Flash — roteiro do Player

## Direção

Motor próprio de animações e jogos em Lua/LÖVE, com formatos declarativos LUAFGAME 1–9 e `.lflash`; não executa SWF/FLA/ActionScript antigos. Player em `player-lua/`, Studio preservado em `studio-lua/`.

## Entregas 0.1–0.19

- [x] Timeline, formas vetoriais, keyframes, easing e edição.
- [x] Recursos PNG/WAV, sprites, transformações, eventos e regras.
- [x] Colisões temporalmente amostradas e click por máscara alfa.
- [x] Undo/redo, backup verificado por projeto, diagnósticos e logging de falhas.
- [x] Áudio WAV polifônico com duas categorias e orçamento de vozes.
- [x] Testes Lua/LÖVE, cenários grandes e pacote `.love`.

## Player 0.20 — Windows portátil sem instalar LÖVE

- [x] Ferramenta de fusão `love.exe + Lua-Flash-Player-0.20.love`.
- [x] Dependências Windows x64 do pacote oficial LÖVE 11.5 preservadas.
- [x] Download do runtime oficial validado por SHA-256 fixo.
- [x] ZIP portátil e instruções, textos de licença originais incluídos.
- [x] Teste offline da ferramenta de empacotamento, incluindo adulteração e travessia de caminhos.
- [x] Build separada em runner Windows x64 com inspeção PE, DLLs e jogo embutido.
- [x] Smoke de inicialização do binário nativo (modo `--version`).
- [x] Distinctos artefatos `.love` e Windows portátil.
- [x] Sem alterações no Studio nem no formato LUAFGAME.
- [ ] Testes completos de GUI/mídia nativa em PCs Windows com diferentes GPUs e drivers.
- [ ] Assinatura de código, ícone próprio, versão de arquivo, instalador e atualizações.

## Prioridades rumo ao Player 1.0

- [ ] Testes de UX e desempenho em Windows com cenas e mídias reais.
- [ ] Melhorar menus, erros, arrastar/soltar e apresentação de arquivos.
- [ ] Reduzir latência/uso de memória em projetos grandes, otimizar colisões.
- [ ] Distribuição assinada, configuração de versão e eventual instalador.
- [ ] Testes multiplataforma e fluxo de publicação de versões estáveis.

O Player é experimental; a presença de um executável portátil não significa que a versão 1.0 esteja pronta.
