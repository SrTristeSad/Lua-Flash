# Lua-Flash — roteiro do Player

## Meta

Entregar um runtime próprio de animações/jogos em Lua para PC, independente de arquivos SWF/FLA/ActionScript históricos. O Player fica em `player-lua/` e o Studio em `studio-lua/`; as alterações atuais são exclusivas do Player.

## Base concluída — 0.1 a 0.15

- [x] Renderização vetorial, timeline, quadros-chave e interpolação.
- [x] Entrada mouse/toque/teclado, eventos, regras e estados.
- [x] LUAFGAME 1–9, com recursos PNG/WAV embutidos, sprites e transformações.
- [x] Detecção de alfa, colisões amostradas no tempo e cache de recursos.
- [x] Editor inicial de chave: adicionar, excluir, mover e arrastar sprites.
- [x] Testes Lua, gráfico LÖVE em display virtual e build `.love`.

## Player 0.16 — segurança para edições

- [x] Histórico limitado a 32 alterações com Undo/Redo.
- [x] Arrasto do sprite agrupado numa única operação.
- [x] Ajuste de rotação e escalas X/Y no editor visual, com validação de limites.
- [x] Snapshot leve com só poses/curvas, sem duplicar grandes recursos binários.
- [x] Verificação da integridade do pacote antes de salvar.
- [x] Cópia automática de recuperação para edições pendentes.
- [x] Testes de desfazer/refazer, mudanças inválidas e recuperação pela interface.
- [x] Formato LUAFGAME 9, sem modificar o Studio.
- [ ] Backup rotativo/atômico por projeto e restauração de histórico entre sessões.
- [ ] Testes de desempenho e UX em computadores reais.

## Foco futuro rumo ao Player 1.0 para PC

- [ ] Melhorar histórico persistente e recuperação de projetos.
- [ ] Manuseio de erros e logs, memória e CPU em jogos grandes.
- [ ] Áudio mais robusto com canais e polifonia.
- [ ] Editor visual de múltiplos objetos com ferramentas de rotação/escala.
- [ ] Build nativo Windows, com LÖVE incorporado e teste de instalação.
- [ ] Homologação manual em hardware Windows/Linux.

Não há execução arbitrária de scripts enviados nos jogos. Android/Web ficam fora do escopo imediato do 1.0 para PC.
