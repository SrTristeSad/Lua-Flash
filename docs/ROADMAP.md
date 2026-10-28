# Lua-Flash — roteiro de desenvolvimento do Player

## Objetivo

Runtime próprio para animações e jogos em Lua/LÖVE com formatos declarativos LUAFGAME 1–9 e `.lflash`. Não executa SWF/FLA/ActionScript. O Studio continua separado e não é modificado durante as etapas do Player.

## Entregas até 0.25

- [x] Timeline vetorial, sprites e edição de quadros-chave, curvas e transformações.
- [x] PNG/WAV, interação, colisões, áudio polifônico e eventos.
- [x] Undo/Redo, salvamento, recuperação, logs e diagnóstico F3.
- [x] Windows x64 portátil com runtime LÖVE, seletor nativo, ícone e metadados.
- [x] Interface adaptável, alto contraste e navegação por teclado até o editor.
- [x] Testes Lua/CI, visualização LÖVE e empacotamento Windows.

## Player 0.26 — legibilidade e resistência

- [x] Três tamanhos de fonte selecionáveis e atalhos Ctrl+mais/menos/zero.
- [x] Preferência de tamanho persistida e validada sem executar código.
- [x] Rótulos de botões, texto do editor e ajuda com largura controlada.
- [x] Testes do ajuste das fontes, persistência e tratamento de UTF-8.
- [x] Simulação de 20 minutos de reprodução, 72.000 atualizações virtuais e testes de memória/cache/loops.
- [x] Metadados Windows atualizados para a versão 0.26.0.0.
- [x] Studio e formatos dos jogos preservados.
- [ ] Testes de longa duração com GPU, áudio e hardware físico.
- [ ] Interface realmente refluida e leitor de tela.

## Para a versão 1.0 de PC

- [ ] Benchmark e perfil de CPU/GPU/VRAM em jogos reais grandes.
- [ ] Reduzir gargalos de renderização, máscaras e memória em cenas grandes.
- [ ] Melhorar UX de projeto, legendas e acessibilidade no Windows.
- [ ] Homologar execução física prolongada em Windows/Linux com testes de áudio.
- [ ] Assinatura digital, instalador opcional e integração de arquivo.
- [ ] Encerrar problemas críticos antes de lançar uma versão estável.

O Player permanece experimental.
