# Lua-Flash

**O Flash renasce em Lua** — Player independente para animações e jogos em formatos próprios; não executa SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicação | Pasta | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.22 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.22 — seletor nativo Windows e identidade visual

A versão 0.22 acrescenta uma janela **Abrir Arquivo** do próprio Windows, integrada diretamente por APIs Win32 Unicode. Ao clicar em **ABRIR ARQUIVO** ou pressionar **Ctrl+O**, o Player mostra o seletor padrão para arquivos `.lflash` ou `.lfgame`.

A versão 0.21 já aceitava arrastar/soltar, caminho digitado e argumentos de inicialização; todos permanecem. **Ctrl+Shift+O** abre o campo manual, útil em plataformas sem seletor nativo ou se o usuário preferir colar caminhos. O leitor Windows utiliza `CreateFileW`, `GetFileSizeEx` e `ReadFile` para oferecer suporte UTF-16 a nomes com acentos, dentro do limite de 25 MB.

O novo **ícone original de raio** é desenhado por código Lua e aplicado à janela em execução. O ZIP Windows também contém `Lua-Flash-Player.ico`, utilizável em atalhos personalizados. **O recurso de ícone embutido no próprio `.exe` permanece o do LÖVE oficial**, enquanto a versão de arquivo e a assinatura digital ainda estão pendentes.

O Windows portátil continua incluindo `Lua-Flash-Player.exe`, as DLLs do LÖVE 11.5, `ABRIR-JOGO.cmd` e documentação, sem instalar LÖVE separadamente.

## Baixar

Na página de execução aprovada de [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions), procure:

- `lua-flash-player-0.22-windows-x64-portable`: ZIP Windows com executável, DLLs, ícone e lançador portátil;
- `lua-flash-player-0.22-love-and-game`: Player `.love` e exemplos, para sistemas com [LÖVE](https://love2d.org/) instalado.

Extraia o conteúdo integral dos ZIPs antes de abrir o executável. A distribuição é experimental, não assinada, e ainda precisa de homologação gráfica em computadores Windows físicos. Ela não modifica associações do Registro e não possui instalador MSI.

## Desenvolvimento

```bash
love player-lua
lua tests/native_dialog_test.lua
lua tests/file_import_test.lua
python3 tests/windows_package_test.py
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

O Studio não foi modificado. Arquivos externos são dados validados, nunca código Lua executado.
