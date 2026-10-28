# Lua-Flash Player 0.26 — tamanho do texto e resistência

Player experimental de animações `.lflash` e jogos LUAFGAME 1–9 (`.lfgame`) em Lua/LÖVE. O Studio permanece separado e não foi modificado.

## Ajustar o texto

| Atalho | Ação |
|---|---|
| **Ctrl + +** (em muitos teclados: Ctrl + =) | Aumentar tamanho do texto |
| **Ctrl + -** | Diminuir tamanho do texto |
| **Ctrl + 0** | Restaurar tamanho normal |
| **F2** | Alternar alto contraste |
| **F1** | Mostrar ajuda de atalhos |

Há três níveis, limitados para evitar fontes grandes demais: **normal** (13 px para texto comum, 12 px para texto pequeno), **grande** (15/14 px) e **extra** (17/16 px). Os títulos acompanham essas mudanças. Os ajustes ocorrem imediatamente, inclusive com o editor de quadros-chave aberto.

Os botões mantêm sua área de clique; o texto é dimensionado para caber no botão. Para rótulos muito longos, há truncamento em limite de largura, preservando a estrutura dos caracteres UTF-8. A interface continua sendo escalonada para janelas pequenas, e textos enormes podem ficar abreviados em vez de deslocar os controles.

A escolha é gravada no arquivo `player-font-size.txt`, dentro da pasta de dados do LÖVE, como `font=normal`, `font=large` ou `font=extra`. Arquivos inválidos são ignorados e o tamanho normal é aplicado. Nenhum texto dessa preferência é interpretado como código. A configuração de alto contraste fica em arquivo separado e continua funcionando.

## Teste prolongado automatizado

O teste `tests/endurance_player_test.lua` simula **72.000 atualizações**, correspondentes a **20 minutos de relógio da timeline a 60 atualizações por segundo**, sem aguardar o tempo real. Verifica loops fracionários, interpolação e cache, metadados, memória Lua retida e que a reprodução não modifica o jogo importado. Também verifica o comportamento ao alcançar o final sem repetição.

É um **teste de lógica e retenção de memória Lua**, não um teste de 20 minutos em GPU ou driver físico. Não valida a temperatura do hardware, latência de áudio real ou VRAM. Esses testes ainda precisam acontecer em Windows/Linux reais para a versão 1.0.

## Funções existentes

Ctrl+O abre o seletor de arquivos; Ctrl+Shift+O abre o campo manual; E abre o editor de poses; Tab e Shift+Tab percorrem controles; Ctrl+S salva; Ctrl+Z/Y desfaz/refaz; F3 mostra diagnósticos; F5–F10 controlam áudio; F11 alterna tela cheia.

O pacote Windows x64 incorpora o LÖVE 11.5 oficial, seu ícone próprio, VERSIONINFO **0.26.0.0** e as DLLs, mas não é assinado digitalmente. O formato de jogo continua **LUAFGAME 9** sem alterações.

## Desenvolvimento e validação

```bash
lua tests/text_scale_test.lua
lua tests/endurance_player_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_resource_test.py
python3 tools/package_player.py
```

A CI também executa o LÖVE real com display virtual e compila o ZIP Windows portátil. Os testes de usabilidade, desempenho e acessibilidade em hardware real continuam pendentes.
