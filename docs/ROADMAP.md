# Lua-Flash — roadmap do Player

## Princípios

Nova plataforma de jogos/animações baseada em Lua e formatos próprios. Não oferecer retrocompatibilidade obrigatória com SWF/FLA/ActionScript históricos. Os aplicativos `player-lua/` e `studio-lua/` são separados; a etapa 0.9 modifica apenas o Player e suas ferramentas/testes.

## Player 0.1–0.8 — consolidado

- [x] Reprodução de cenas vetoriais `.lflash`, timeline, controle de velocidade e loop.
- [x] Eventos de mouse, teclado, toque, hit-testing e minijogo.
- [x] LUAFGAME 1–3: dados interativos, estados, regras, objetos e colisões.
- [x] LUAFGAME 4: PNG/WAV embutidos e efeitos por evento.
- [x] LUAFGAME 5: sprites interativos com `STATIC`/`FOLLOW` e colisões retangulares.
- [x] Testes automatizados em Lua e renderização real em LÖVE/Xvfb.

## Player 0.9 — animação e timeline sonora

- [x] **LUAFGAME 6**: sequências PNG para sprites existentes.
- [x] Seleção determinística da imagem por quadro e período em frames.
- [x] Sons WAV agendados para quadros, respeitando pausa e passagem de loop.
- [x] Ferramenta `tools/animate_media.lua` para publicação de jogos v6.
- [x] Exemplo com duas imagens originais e eventos WAV na timeline.
- [x] Compatibilidade declarativa com LUAFGAME 1–5.
- [ ] Hit-testing por pixels alfa opacos e colisões precisas entre sprites.
- [ ] Benchmarks e testes manuais em computadores/dispositivos reais.

## Próximos passos

- [ ] Máscaras alfa e otimização de colisão/hit-testing.
- [ ] Múltiplas trilhas de áudio e gerenciamento de fontes/sincronismo.
- [ ] Editor de vínculos e IDs persistentes no documento `.lflash`.
- [ ] Cache de recursos/renderização, performance e builds desktop nativos.
- [ ] API Lua segura com permissões, antes de permitir scripts de terceiros.
- [ ] Android e web com backends específicos.

Nada aqui usa binários da Adobe nem executa código Lua recebido de pacotes externos.
