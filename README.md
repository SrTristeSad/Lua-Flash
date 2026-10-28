# Lua-Flash

**O Flash renasce em Lua** — Player independente de jogos e animações em formatos próprios. Não executa SWF/FLA/ActionScript antigos.

## Aplicações separadas

| Aplicativo | Pasta | Status |
|---|---|---|
| Player Lua | player-lua/ | **0.24 experimental** |
| Studio Lua | studio-lua/ | 0.1 experimental, preservado |

## Player 0.24 — navegação pelo teclado

A versão 0.24 introduz navegação sem mouse nos **12 controles principais** do Player. Pressione **Tab** para avançar, **Shift+Tab** para voltar e **Enter** para ativar o controle selecionado. Um contorno dourado indica o foco. **Escape** limpa o foco; **F1** abre a janela de atalhos.

O ZIP portátil Windows agora incorpora **VERSIONINFO** no próprio executável, com nome do produto Lua-Flash Player e versão **0.24.0.0**, além do ícone original incorporado na versão anterior. O CI valida ambos os recursos dentro do executável.

O motor continua lendo LUAFGAME 1–9 e animações .lflash. **Nenhum arquivo do Studio foi modificado.**

## Download

Abra [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions) e procure a execução aprovada 0.24. Ela oferece:

- **lua-flash-player-0.24-windows-x64-portable**: pacote portátil com EXE, DLLs do LÖVE oficial e lançador de arquivos. Não precisa instalar LÖVE.
- **lua-flash-player-0.24-love-and-game**: arquivo .love e exemplos, para computadores com LÖVE instalado.

O Windows pode apresentar alerta do SmartScreen porque o executável ainda não é assinado digitalmente. É necessário testar a interface e o desempenho em computadores físicos antes de uma versão 1.0 estável.

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Especificação LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente, não afiliado à Adobe.
