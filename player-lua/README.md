# Lua-Flash Player 0.20 — portátil para Windows

Player em Lua e LÖVE para animações `.lflash` e jogos `.lfgame` (LUAFGAME 1–9). O Studio segue como aplicativo separado.

## O que mudou

Pela primeira vez, além do pacote `.love` universal, o Player tem um **executável Windows 64 bits** com o LÖVE incorporado. Não é necessário instalar o motor LÖVE na máquina do usuário.

### Executar no Windows

1. Acesse o [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) e abra a execução verde da versão 0.20.
2. Em **Artifacts**, baixe `lua-flash-player-0.20-windows-x64-portable`.
3. Extraia o ZIP baixado. Ele contém um segundo ZIP, `Lua-Flash-Player-0.20-Windows-x64.zip`, que também deve ser extraído.
4. Entre na pasta `Lua-Flash-Player-0.20-Windows-x64` e execute **`Lua-Flash-Player.exe`**.
5. Não remova nem separe as DLLs da pasta do executável.

Os controles de animação, importação de jogos, editor de quadros-chave, áudio WAV polifônico, Ctrl+S, Ctrl+Z/Ctrl+Y, Ctrl+R e F3 continuam disponíveis. Para importar, arraste um `.lflash` ou `.lfgame` para a janela.

### O que esta distribuição é (e o que não é)

- **Portátil:** ZIP, sem instalador, sem a instalação adicional de LÖVE.
- **Windows x64:** não foi produzida uma distribuição Windows 32 bits.
- **Sem assinatura digital:** o Windows SmartScreen pode sinalizar o executável como desconhecido. Nunca ignore alertas de segurança sem verificar a origem do pacote.
- **Runtime incluído:** versão oficial LÖVE 11.5 e DLLs locais. O programa não precisa baixar seu motor pela internet para abrir.
- **Experimental:** estrutura e startup são verificados no CI Windows; o uso gráfico em máquinas físicas ainda precisa de homologação. Não afirmamos compatibilidade com todas as GPUs.

Não se trata de um instalador MSI/EXE de setup, nem de uma reconstrução de Flash Player Adobe. Os arquivos aceitos são apenas os formatos nativos de Lua-Flash.

## Como a build é feita

A suíte Linux empacota todos os módulos de `player-lua/` em `Lua-Flash-Player-0.20.love` e executa os testes de regressão. Um segundo job `windows-latest` obtém o arquivo oficial `love-11.5-win64.zip`, confere seu **SHA-256 fixo**, combina `love.exe` com `.love` e inclui os binários auxiliares e textos de licença da distribuição LÖVE.

O packager `tools/package_player_windows.py` valida também o ZIP de entrada, previne caminhos de arquivo maliciosos e verifica que o executável gerado contém o jogo correto. O job Windows confere o cabeçalho executável PE, a presença das DLLs e a saída do processo `--version`.

Para testar localmente:

```bash
python3 tools/package_player.py
python3 tests/windows_package_test.py
python3 tools/package_player_windows.py --love-zip /caminho/love-11.5-win64.zip
```

O último comando recusa arquivos do LÖVE alterados. Consulte a distribuição oficial e as licenças originais em [LÖVE 11.5](https://github.com/love2d/love/releases/tag/11.5).

## Próximas prioridades

Ainda faltam testes visuais no Windows real, experiência de instalação, perfis de CPU/GPU, suporte aprimorado a projetos grandes e validação de aplicações de longo prazo. O formato LUAFGAME 9 permanece sem alteração. O Studio não foi modificado.
