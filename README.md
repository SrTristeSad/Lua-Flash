# Lua-Flash

**O Flash renasce em Lua** — plataforma independente para animações e jogos com formatos próprios. Não reproduz SWF/FLA/ActionScript antigos da Adobe.

## Aplicações separadas

| Aplicação | Diretório | Execução | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.21 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental; não modificado |

## Player 0.21 — abrir projetos no Windows com mais facilidade

Agora o Player permite abrir arquivos nativos de mais formas, inclusive na distribuição portátil Windows sem instalação separada do LÖVE:

- **Arraste e solte** arquivos `.lflash` ou `.lfgame` na janela;
- **Ctrl+O** ou **ABRIR ARQUIVO** mostra um campo onde é possível colar o caminho do arquivo (inclusive **Ctrl+V** com o caminho copiado do Explorador);
- **Abra com…** no Windows e selecione `Lua-Flash-Player.exe` para passar um arquivo como argumento;
- **Arraste o arquivo sobre `ABRIR-JOGO.cmd`**, incluído na pasta portátil Windows, sem alterar as associações de arquivos do sistema.

O importador limita os arquivos a **25 MB**, recusa extensões inválidas, trata erros de leitura e respeita a proteção contra troca de jogo com alterações não salvas. Ele não executa código presente em arquivos recebidos.

Não houve alteração no formato **LUAFGAME 9**, na compatibilidade LUAFGAME 1–9 ou no Studio.

## Baixar e executar

Na execução aprovada de [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions), escolha um dos artefatos:

- **`lua-flash-player-0.21-windows-x64-portable`**: contém o ZIP portátil com `Lua-Flash-Player.exe`, DLLs do LÖVE oficial, `ABRIR-JOGO.cmd` e instruções. Extraia os ZIPs inteiros e execute o EXE. Não precisa instalar LÖVE separadamente.
- **`lua-flash-player-0.21-love-and-game`**: arquivo `.love` e jogos de exemplo para quem já tem [LÖVE](https://love2d.org/) instalado.

A distribuição Windows não é assinada digitalmente; pode apresentar aviso do SmartScreen. Ainda faltam testes de usabilidade e desempenho gráfico em PCs Windows reais.

## Desenvolvimento

```bash
love player-lua
python3 tools/package_player.py
lua tests/file_import_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_package_test.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente, sem vínculo com a Adobe.
