# Lua-Flash Player 0.17 — recuperação rotativa e diagnósticos

Player experimental de animações `.lflash` e jogos declarativos `.lfgame` (LUAFGAME 1–9), em Lua com LÖVE 11.5. O Studio é independente e não foi alterado nesta versão.

## Recuperação segura por jogo

Na versão anterior existia apenas `player_recovery.lfgame`, que podia ser substituído durante a edição de outro jogo. A 0.17 substitui essa estratégia por um **identificador por arquivo original** e duas cópias alternadas:

```text
recovery/<id-do-projeto>-a.rec
recovery/<id-do-projeto>-b.rec
```

O identificador é um hash não criptográfico calculado a partir do nome e dos bytes do jogo original. É usado para **separação operacional**, não como autenticação ou proteção contra alterações maliciosas. Arquivos com nomes diferentes têm identidades diferentes; renomear, alterar ou substituir o original pode impedir a localização automática das cópias anteriores.

Cada `.rec` guarda o pacote `.lfgame` completo, o número da sequência, o tamanho e uma soma de verificação. Ao recuperar, o Player valida o envelope, o checksum e o formato do jogo. Se o último slot estiver corrompido, tenta o outro.

**Uso:**

1. Abra o jogo original usando **PACOTE** ou arraste seu `.lfgame`.
2. Edite no painel **E**. Após cerca de 12 segundos com alterações não salvas, o Player tenta salvar uma cópia.
3. Após reiniciar, abra novamente **o mesmo arquivo original**. Pressione **Ctrl+R** para restaurar o slot válido mais recente.
4. Verifique o resultado e use **Ctrl+S** para salvar `player_game.lfgame`; as duas cópias automáticas daquele projeto são apagadas depois de um salvamento bem-sucedido.

O Player não substitui automaticamente projetos abertos: se houver edições pendentes, recusa carregar um jogo diferente ou recuperar outro estado. Primeiro salve com Ctrl+S.

**Limitações reais:** a alternância entre dois slots mantém uma cópia anterior durante uma nova gravação, mas a escrita de cada slot não é atômica nem uma garantia contra falha de disco, sistema, permissão ou energia. O primeiro salvamento de recuperação tem apenas um slot. Recuperações geradas pela 0.16 no nome global `player_recovery.lfgame` não são importadas automaticamente, para evitar misturar dados de jogos diferentes. Copie manualmente seus arquivos importantes antes de atualizar.

## Diagnóstico de desempenho — F3

Pressione **F3** para mostrar/ocultar um painel que apresenta FPS médio da amostragem recente, pior duração de atualização desde a abertura, memória Lua aproximada em MB, número de trilhas/chaves/recursos, máscaras alfa geradas e pares de colisões. É útil para comparar cenas e identificar crescimento de memória durante testes.

As estatísticas são aproximadas: `collectgarbage("count")` mede memória gerenciada por Lua e **não** toda a memória de GPU, texturas e decodificadores do LÖVE. F3 não executa benchmarks nem mede latência de renderização por GPU.

## Ferramentas preservadas

- **E**: editor visual de quadros-chave, incluindo posição, rotação e escala.
- **Ctrl+Z / Ctrl+Y**: histórico de até 32 alterações.
- **Ctrl+S**: salvar jogo válido.
- **Ctrl+R**: recuperação do jogo aberto.
- **F8/F9/F10**: volume e silêncio de efeitos WAV.
- **F11**: tela cheia.

O formato de jogo continua **LUAFGAME 9**; jogos antigos permanecem aceitos. Nenhum arquivo importado executa scripts Lua arbitrários.

## Testes

```bash
lua tests/recovery_test.lua
lua tests/edit_history_test.lua
lua tests/gui_smoke.lua
lua tests/package_v9_test.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI também executa o Player em LÖVE real com display virtual e publica `Lua-Flash-Player-0.17.love`.

A homologação em equipamentos Windows reais e a distribuição sem a instalação separada do LÖVE continuam pendentes.
