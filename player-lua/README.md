# Lua-Flash Player 0.25 — edição sem mouse e contraste

Player experimental Lua/LÖVE para `.lflash` e `.lfgame` (LUAFGAME 1–9). O Studio é um aplicativo separado e não foi modificado nesta atualização.

## Editor de quadros-chave: teclado

1. Abra um jogo LUAFGAME 8/9 com trilhas de transformação e pressione **E** para abrir o editor.
2. Pressione **Tab** para percorrer controles: trocar sprite, escolher uma das quatro chaves visíveis, inserir/excluir, alterar posição ou quadro, ângulo/escala, desfazer, trocar curva e salvar.
3. Pressione **Shift+Tab** para voltar e **Enter** para executar o controle selecionado.
4. **Setas cima/baixo** continuam selecionando chaves e **PageUp/PageDown** trocam de sprite. O destaque de teclado é um contorno em torno do controle.
5. **Escape** fecha o editor; **Ctrl+Z/Ctrl+Y** desfaz/refaz as edições e **Ctrl+S** salva uma cópia validada do jogo.

O foco ignora linhas de quadros-chave não visíveis. Se uma linha desaparecer após exclusão ou Undo, a navegação retorna a uma ação visível. Mouse e teclado utilizam as mesmas operações do editor, mantendo os limites de tempo/posição, a validação do formato e as proteções existentes.

**Limites atuais:** a lista do editor mostra até quatro chaves simultaneamente. As demais podem ser acessadas pelas setas; Tab percorre apenas as linhas atualmente visíveis. Ainda não há suporte completo a leitores de tela ou a descrição de elementos para tecnologias assistivas.

## Alto contraste e preferência persistente

**F2** alterna o tema de alto contraste durante a execução. O modo usa fundos escuros, texto claro, contornos visíveis e cor de foco destacada. A preferência é gravada no arquivo `player-settings.txt` no diretório de dados do aplicativo.

O arquivo só aceita exatamente `contrast=high` ou `contrast=normal` conforme o formato da implementação. Ele é lido como **texto**, não como código Lua, e um arquivo inválido não executa comandos. Em caso de impossibilidade de gravação, o Player informa que a preferência não pôde ser salva; a sessão atual ainda muda de tema.

O F2 não altera os dados do jogo, seus sprites nem o formato `.lfgame`. O F1 exibe a ajuda dos atalhos.

O tema melhora o contraste dos controles principais, mas partes das cenas e cores autorais dos jogos permanecem como foram criadas. Isso não constitui certificação WCAG nem garante compatibilidade com leitores de tela.

## Outros recursos

Ctrl+O abre o seletor de arquivos (nativo no Windows); Ctrl+Shift+O abre campo manual; F3 mostra diagnósticos; F5–F10 controlam áudio; F11 alterna tela cheia. O Windows portátil continua incorporando o LÖVE 11.5, ícone original e informações de versão **0.25.0.0**.

## Testes

```bash
lua tests/editor_nav_test.lua
lua tests/visual_settings_test.lua
lua tests/focus_nav_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_resource_test.py
python3 tools/package_player.py
```

A CI verifica esses testes e compila a distribuição Windows. Ainda são necessários testes físicos e homologação de acessibilidade antes de declarar uma versão estável.
