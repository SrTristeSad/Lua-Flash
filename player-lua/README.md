# Lua-Flash Player 0.22 — Windows nativo

Player experimental feito em Lua e LÖVE para `.lflash` e `.lfgame` (LUAFGAME 1–9). Não abre SWF nem executa ActionScript.

## Abrir arquivos

**No Windows:** pressione **Ctrl+O** ou clique em **ABRIR ARQUIVO**. O seletor padrão do Windows permite navegar por pastas e escolher um arquivo `.lflash` ou `.lfgame`. Depois de escolher, o Player lê o arquivo e valida o conteúdo. Cancelar o diálogo não altera o projeto aberto.

O seletor usa o diálogo Win32 `GetOpenFileNameW` via LuaJIT FFI. O leitor associa a ele APIs `CreateFileW` / `ReadFile`, sem executar PowerShell ou outros comandos; isso permite abrir caminhos Unicode, inclusive nomes acentuados, diretamente no Windows.

**Em outros sistemas:** Ctrl+O abre o campo de caminho introduzido na versão 0.21. No Windows, **Ctrl+Shift+O** abre esse campo manual também. Cole o caminho do Explorador e pressione Enter.

**Em qualquer plataforma:** é possível arrastar/soltar um arquivo diretamente na janela do Player. No Windows portátil há ainda `ABRIR-JOGO.cmd`, sobre o qual se pode arrastar um jogo para abrir o executável, ou selecionar o Player pelo menu **Abrir com...**.

Só são aceitas extensões `.lflash` e `.lfgame`, limitadas a 25 MB. Os arquivos são validados pelos formatos existentes antes da instalação da cena. Nenhum arquivo importado executa código Lua arbitrário. Se existirem alterações não salvas, o carregamento de outro arquivo é bloqueado.

## Ícone do Player

Foi criado um ícone original em azul escuro, ciano e dourado, com um raio e um arco, a partir de código em `src/window_icon.lua`. Ele é aplicado à janela do LÖVE durante a execução. O empacotador Windows inclui um `.ico` independente com o mesmo desenho, para atalhos personalizados.

**Importante:** isso ainda não substitui o ícone do recurso PE do próprio `Lua-Flash-Player.exe`, que continua herdado do runtime LÖVE. A incorporação do ícone no PE, metadados de versão e assinatura de código estão previstos para outra etapa.

## Distribuição e verificação

A build Windows segue usando o runtime oficial LÖVE 11.5 com checksum SHA-256 fixo e verificado. O GitHub Actions constrói o executável portátil, valida ZIP/PE/DLLs, seu conteúdo `.love`, a existência do ícone e do lançador, e verifica a inicialização da aplicação. Há também um teste automatizado para importação de um arquivo com nome Unicode no Windows, e testes de fallback quando o seletor nativo não está disponível.

O diálogo real é interativo e precisa ser testado manualmente em um PC Windows para homologação da experiência. O ícone do Windows é aplicado apenas à janela em execução.

Para preparar os arquivos:

```bash
python3 tools/package_player.py
python3 tools/package_player_windows.py --love-zip love-11.5-win64.zip
```

Para verificar:

```bash
lua tests/native_dialog_test.lua
lua tests/file_import_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_package_test.py
```

Não alteramos o Studio. O formato permanece LUAFGAME 9, e todos os jogos antigos seguem compatíveis. A distribuição Windows ainda não possui assinatura digital nem instalador MSI.
