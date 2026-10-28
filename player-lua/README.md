# Lua-Flash Player 0.16 — desfazer, rotação e escala

Runtime experimental para jogos `.lfgame` LUAFGAME 1–9 e animações `.lflash`, escrito em Lua/LÖVE. O Studio permanece um aplicativo independente.

## Editor visual de quadros-chave

Abra um jogo com trilha de transformação (v8/v9), pressione **E** e selecione uma chave. Além de inserir/excluir, deslocar um quadro, ajustar X/Y e arrastar o sprite, a versão 0.16 possui:

| Controle | Ação |
|---|---|
| **G - / G +** | Reduz/aumenta em 5° a rotação da chave. |
| **SX - / SX +** | Diminui/aumenta a escala horizontal em 10%. |
| **SY - / SY +** | Diminui/aumenta a escala vertical em 10%. |
| **R / T** | Aumenta/diminui a rotação em 5°. |
| **X / V** | Aumenta/diminui a escala horizontal em 10%. |
| **B / N** | Aumenta/diminui a escala vertical em 10%. |
| **DESFAZER / Ctrl+Z** | Reverte a operação editável mais recente. |
| **Ctrl+Y ou Ctrl+Shift+Z** | Refaz a operação desfeita. |
| **Ctrl+S** | Salva `player_game.lfgame` na pasta de dados do Player. |
| **Ctrl+R** | Abre `player_recovery.lfgame`, desde que o jogo aberto não tenha mudanças pendentes. |

O histórico guarda as últimas **32 operações concluídas**; um arrasto inteiro conta como uma única operação. Um novo ajuste depois de desfazer descarta a sequência de refazer. Os dados originais de PNG/WAV não são duplicados dentro de cada snapshot.

As mudanças de ângulo respeitam -360° a +360° e as escalas permanecem entre 10% e 400%. Alterações inválidas são rejeitadas sem modificar a pose existente.

## Recuperação automática de edições

Quando há modificações não salvas, a cada **12 segundos** o Player tenta validar e gravar o jogo atual em `player_recovery.lfgame`. É uma cópia separada: **não substitui o arquivo aberto nem o arquivo salvo por Ctrl+S**. O diretório de dados pode ser consultado pela mensagem após salvar o projeto.

Se uma sessão anterior foi interrompida, abra o Player, pressione **Ctrl+R** e, após revisar a recuperação, use **Ctrl+S** para guardar uma cópia. Para evitar perda das edições já abertas, o Player recusa carregar essa recuperação enquanto a sessão atual estiver modificada e não salva.

**Limitações:** a recuperação automática não é uma garantia contra falhas de disco, falta de energia, bloqueio do sistema ou uma gravação incompleta. Existe um único nome de cópia automática, portanto editar outro jogo pode substituir uma recuperação anterior; exporte cópias manuais importantes. O histórico de 32 passos é temporário e não é salvo no `.lfgame`.

## Sem mudança de formato

O formato permanece **LUAFGAME 9**. O Player continua executando animação de sprites, easing, eventos de áudio WAV, clique por alfa, colisões e timeline. Projetos antigos continuam válidos.

O editor ainda é inicial: não tem seleção múltipla nem manipuladores de giro/escala diretamente no palco; rotação/escala são ajustadas por botões e atalhos. O Studio não foi alterado.

## Testes

```bash
lua tests/edit_history_test.lua
lua tests/keyframe_editor_test.lua
lua tests/gui_smoke.lua
lua tests/package_v9_test.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI verifica histórico, integridade de formato, alterações de poses e recuperação, além de iniciar o Player no LÖVE real com uma tela virtual. O pacote `.love` ainda precisa de LÖVE instalado.
