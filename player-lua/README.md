# Lua-Flash Player 0.21 — abrir projetos nativos no PC

Reprodutor em Lua/LÖVE para animações `.lflash` e jogos declarativos `.lfgame` (LUAFGAME 1–9). O Studio permanece independente e não foi modificado.

## Formas de abrir arquivos

**1. Arrastar e soltar.** Arraste um arquivo `.lflash` ou `.lfgame` para a janela do Player. O jogo é validado antes de substituir o projeto aberto.

**2. Ctrl+O — ABRIR ARQUIVO.** Digite ou cole o caminho completo do arquivo. No Windows, no Explorador de Arquivos, use **Copiar como caminho**, pressione **Ctrl+O**, cole com **Ctrl+V** e pressione **Enter**. O Player aceita o caminho entre aspas duplas fornecido pelo Explorador. **Escape** cancela. Esse campo não é um seletor de arquivos nativo do Windows.

**3. Menu Abrir com...** No Explorador do Windows, clique com o botão direito no `.lflash` ou `.lfgame`, escolha **Abrir com...** e selecione `Lua-Flash-Player.exe`. O Player agora processa o caminho passado na inicialização, desde que o Windows entregue o caminho como argumento do programa. A build portátil não altera automaticamente associações do Windows.

**4. Lançador portátil `ABRIR-JOGO.cmd`.** Arraste um arquivo `.lflash` ou `.lfgame` sobre o arquivo `ABRIR-JOGO.cmd`, que fica na mesma pasta do `Lua-Flash-Player.exe`. O script abre o EXE passando o caminho do jogo, sem modificar o Registro do Windows e sem instalar componentes.

## Tratamento de arquivos e proteção

O módulo `src/file_import.lua` centraliza a leitura dos arquivos por caminho ou arrastar/soltar. Usa o limite de **25 MiB**, verifica a extensão, recusa arquivos vazios e interrompe importações com erro. O carregamento de jogos usa os validadores LUAFGAME existentes; scripts Lua enviados dentro de arquivos não são executados.

Se o editor tiver modificações ainda não salvas, o Player avisa e impede que outro projeto as substitua. **Ctrl+S** salva uma cópia e **Ctrl+R** abre a recuperação verificada do projeto ativo.

**Limitações:** o diálogo Ctrl+O recebe um caminho, em vez de exibir uma janela nativa de navegação. O acesso a caminhos com certos caracteres Unicode depende do suporte da biblioteca Lua/JIT e do sistema Windows. A distribuição continua sem assinatura digital ou instalador MSI.

## Executar no Windows

Baixe `lua-flash-player-0.21-windows-x64-portable` em [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions). Extraia o ZIP externo e o ZIP interno, entre na pasta `Lua-Flash-Player-0.21-Windows-x64`, execute `Lua-Flash-Player.exe` e mantenha todas as DLLs juntas.

A build inclui o runtime LÖVE 11.5 oficial, previamente validado por SHA-256; não é necessário instalar o LÖVE no PC. O executável não é assinado; o Windows pode solicitar confirmação de segurança.

## Testes e build

```bash
lua tests/file_import_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_package_test.py
python3 tools/package_player.py
```

A CI executa os demais testes de regressão, abre o Player graficamente com o LÖVE em display virtual, verifica o carregamento de um `.lfgame` recebido pela linha de comando e constrói o ZIP portátil em Windows x64. A build é validada por estrutura PE, DLLs, conteúdo `.love` e inicialização do executável.

A execução gráfica no Windows com diferentes GPUs e drivers ainda precisa de testes físicos. O formato permanece LUAFGAME 9; nenhum arquivo do Studio foi modificado.
