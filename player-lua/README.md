# Lua-Flash Player 0.18 — diagnósticos de falhas e desempenho

Reprodutor experimental de jogos LUAFGAME 1–9 (`.lfgame`) e projetos de animação `.lflash` em Lua/LÖVE. O Studio permanece separado.

## Tratamento de erros

Eventos do aplicativo — desenho, atualização, clique, teclado, toque e importação — agora são executados com proteção de erros. Se alguma dessas rotinas falhar, o Player tenta:

- Pausar a reprodução, preservando o jogo/projeto aberto em memória;
- Registrar mensagem e rastreamento local no arquivo `player-errors.log`;
- Mostrar um aviso na interface, ou uma tela de erro simples se o desenho normal falhar;
- Continuar respondendo aos demais eventos para permitir inspecionar ou abrir novamente um projeto.

O registro fica na pasta de dados do LÖVE, identificada como `lua-flash` em `player-lua/conf.lua`. Há um limite de 32 KiB para o log, e mensagens repetidas de forma consecutiva não são gravadas continuamente.

**F4** dispensa o banner do último erro na interface, mantendo o log no disco. **F3** apresenta FPS, memória Lua, número de recursos, máscaras e pares de colisão.

**Limitação:** essas proteções atuam sobre erros Lua nos callbacks monitorados. Não impedem crashes de driver de vídeo, falhas nativas do LÖVE, indisponibilidade grave de memória ou encerramento do sistema operacional. Nem todo erro de renderização pode ser recuperado: a tela de fallback também depende do sistema gráfico.

## Melhorias de desempenho

A busca do par de keyframes de cada camada usa agora pesquisa binária em uma lista de quadros ordenada na abertura da animação. Isso reduz a busca de **O(K) para O(log K)** por camada e posição, onde K é o número de keys daquela camada.

A interpolação continua mantendo cache de uma cena por posição e não altera o documento-fonte. As colisões com máscaras PNG e amostragem temporal continuam funcionando como antes.

## Testes de estresse

A CI executa `tests/stress_player_test.lua`, que gera uma cena sintética de **18 camadas, 32 keyframes por camada e 20 formas por keyframe** (11.520 formas no total). Ela verifica renderização de amostras interpoladas, cache, integridade dos keyframes, serialização e limite de memória retida, apresentando dados aproximados de tempo e uso de memória.

O teste é reprodutível, mas não constitui um benchmark definitivo em hardware Windows e não estabelece um valor mínimo de FPS. Ainda precisamos validar cenas reais maiores em computadores físicos.

## Recuperação e edição existentes

Continuam disponíveis **E** (editor de quadros-chave), **Ctrl+Z/Y** (desfazer/refazer), **Ctrl+S** (salvar), **Ctrl+R** (recuperação verificada por projeto), **F8/F9/F10** (volume e mudo), **F11** (tela cheia). Não houve alteração do formato LUAFGAME 9.

## Testar e empacotar

```bash
lua tests/error_report_test.lua
lua tests/stress_player_test.lua
lua tests/recovery_test.lua
lua tests/gui_smoke.lua
lua tests/package_v9_test.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

Além desses testes, o GitHub Actions executa o Player no LÖVE real, com display virtual, e publica a versão 0.18.

O arquivo `.love` ainda exige LÖVE instalado e não é um aplicativo Windows autônomo.
