# Lua-Flash — roadmap do Player Lua

## Objetivo

Criar uma plataforma independente de autoria e reprodução em Lua, sem precisar suportar SWF/FLA/XFL ou ActionScript antigos. O Player e o Studio são aplicativos independentes; somente o Player está em desenvolvimento nesta etapa.

## Concluído — 0.1 a 0.7

- [x] Playback vetorial e linha do tempo com controle de velocidade e interpolação.
- [x] Mouse, toque, teclado, detecção de formas e minijogos.
- [x] LUAFGAME 1–3 com objetos, IDs por quadro-chave, estado, regras e colisões.
- [x] LUAFGAME 4 com PNG/WAV embutidos, sprites visuais e efeitos de áudio por evento.
- [x] Publicação de jogos declarativos e testes reais com LÖVE em display virtual.

## Player 0.8 — sprites interativos

- [x] **LUAFGAME 5** com `SPRITE_BIND` associando imagens PNG a objetos nomeados.
- [x] Modos `STATIC` e `FOLLOW`, com o segundo acompanhando objetos animados.
- [x] Detecção de cliques/toques primeiro nos sprites mais à frente.
- [x] Colisão usando o retângulo do sprite associado.
- [x] Controles F8/F9 para volume, F10 para mutar efeitos WAV.
- [x] Ferramenta `tools/bind_sprite.lua` e exemplo jogável exportável.
- [x] Testes de compatibilidade v1–v4, colisões e comportamento de sprite.
- [x] Pacote Player .love gerado no GitHub Actions e teste gráfico com LÖVE.
- [ ] Testes manuais e benchmarks em dispositivos reais.

## Próximas prioridades — 0.9

- [ ] Hit-testing por pixels opacos ou máscaras de colisão precisas.
- [ ] Animação de sprites por atlas e sequência de quadros.
- [ ] Linha do tempo de áudio, canais independentes e volume por trilha.
- [ ] Melhorias de desempenho e redução de processamento por frame.
- [ ] IDs persistentes no modelo de autoria e integração planejada com o Studio.
- [ ] Publicação nativa Windows/macOS/Linux e arquiteturas Android/Web.

O Player ainda não executa scripts fornecidos por terceiros; isso dependerá da definição e auditoria de um isolamento robusto.
