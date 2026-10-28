# Lua-Flash — desenvolvimento do Player

## Direção

Runtime próprio para jogos e animações em Lua e formatos declarativos, sem compatibilidade com SWF/FLA/ActionScript antigos. Player em `player-lua/`; Studio em `studio-lua/`, preservado.

## Base — 0.1 a 0.20

- [x] Timeline, formas, quadros-chave, easing e editor de transformações.
- [x] LUAFGAME 1–9: PNG, WAV, sprites animados, regras de jogo e colisões.
- [x] Undo/redo, recuperação por projeto, diagnóstico de desempenho e logs.
- [x] Áudio polifônico limitado e com canais independentes.
- [x] Player `.love` e Windows x64 portátil com LÖVE 11.5 incorporado.
- [x] Testes Lua, estresse sintético, LÖVE virtual e construção Windows.

## Player 0.21 — abertura e experiência do usuário

- [x] Importador centralizado com validação de arquivo e limites de leitura.
- [x] Ctrl+O e botão ABRIR ARQUIVO para digitar/colar caminhos.
- [x] Suporte a abertura de `.lflash`/`.lfgame` como argumento de inicialização do Player.
- [x] Script `ABRIR-JOGO.cmd` para abrir arquivos arrastados, sem Registro.
- [x] Compatibilidade com drag/drop, validação de mudanças não salvas e relatórios de erros.
- [x] Testes de leitura, argumentos, extensões, tamanhos e GUI.
- [x] Teste com LÖVE real carregando jogo da linha de comando e build Windows portátil.
- [ ] Seletor nativo de arquivos Windows e acesso Unicode integral em todos os sistemas.
- [ ] Teste manual completo de GUI no Windows, com GPUs e drivers diferentes.

## Prioridades rumo ao Player 1.0

- [ ] Ícone e identidade visual originais para executável Windows.
- [ ] Um seletor de arquivos real, sem depender de colagem de caminhos.
- [ ] Testes de estabilidade prolongados com jogos e áudio em PC real.
- [ ] Benchmarks de CPU/GPU/VRAM e otimização para projetos grandes.
- [ ] Publicação assinada digitalmente e instalador opcional.
- [ ] Melhorias de ergonomia, acessibilidade e localização.

O Player permanece experimental, e o Studio não foi alterado.
