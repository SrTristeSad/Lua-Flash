# Lua-Flash — roadmap do Player

## Estrutura

A plataforma é composta por um reprodutor em `player-lua/` e um editor independente em `studio-lua/`. O formato de animações `.lflash` e o código do Studio permanecem intactos durante as alterações exclusivas do Player.

## Concluído — versões 0.1–0.9

- [x] Reprodução vetorial, timeline, interpolação e controle de velocidade.
- [x] Jogos de dados LUAFGAME 1–3: objetos, IDs por quadro-chave, estados, eventos e colisões.
- [x] LUAFGAME 4: PNG e WAV incorporados com reprodução por evento.
- [x] LUAFGAME 5: sprites interativos com modos FOLLOW/STATIC.
- [x] LUAFGAME 6: animação de sprite em sequências PNG e efeitos WAV por quadro.
- [x] Compatibilidade, testes unitários, testes de integração e execução gráfica virtual em LÖVE.

## Player 0.10 — transparência e eficiência

- [x] Teste de canal alfa para cliques e toques em sprites.
- [x] Evitar eventos indevidos da forma vetorial coberta por um PNG transparente.
- [x] Colisão sprite/sprite e sprite/forma com máscara alfa e broad phase.
- [x] Máscaras alfa compactas por recurso, montadas e reutilizadas sob demanda.
- [x] Amostragem de interseção com limite de custo por par.
- [x] Cache de cena interpolada para consultas repetidas à mesma posição.
- [x] Testes de transparência, colisão e compatibilidade com jogos anteriores.
- [ ] Benchmark e validação manual em aparelhos reais.

## Etapas seguintes

- [ ] Colisões contínuas e máscaras ajustadas a rotação/transformações.
- [ ] Suporte a hierarquia de sprites, atlas e múltiplas camadas dinâmicas.
- [ ] Mistura de áudio, canais independentes e sincronismo por amostra.
- [ ] IDs persistentes diretamente em documentos editáveis.
- [ ] API de scripting Lua com isolamento/permissões antes de habilitar código externo.
- [ ] Distribuições Windows/Linux/macOS, seguidas de Android/Web.

Sem modificação do Studio, sem binários da Adobe e sem execução arbitrária de scripts contidos em arquivos de jogos.
