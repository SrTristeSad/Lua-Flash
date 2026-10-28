# Lua-Flash Player 0.24 — ajuda de teclado e identificação Windows

## Acessibilidade inicial

- **Tab** seleciona o próximo botão da barra superior ou inferior.
- **Shift+Tab** retorna ao botão anterior.
- **Enter** executa a ação selecionada.
- **Escape** limpa a seleção.
- **F1** mostra ou oculta a lista visual de atalhos.

O foco aparece com um contorno dourado ao redor do botão. Um clique do mouse encerra o foco de teclado. Com o diálogo de caminho ou o editor de keyframes ativo, a navegação global é suspensa para não interferir na edição.

O suporte cobre os 12 controles principais. Ainda faltam navegação completa no editor, integração com leitores de tela e avaliação formal de acessibilidade.

## Atalhos anteriores preservados

Ctrl+O abre arquivos; Ctrl+Shift+O mostra um campo manual; Ctrl+S salva; Ctrl+Z/Ctrl+Y desfazem/refazem; E abre o editor; F3 exibe diagnósticos; F5–F10 controlam o áudio; F11 alterna tela cheia.

## Detalhes do arquivo Windows

O pacote portátil possui agora os recursos nativos RT_VERSION e VS_VERSION_INFO no executável, além do ícone original. Em **Propriedades → Detalhes**, são esperados:

- Produto: Lua-Flash Player
- Descrição: Lua-Flash Player for Windows
- Versão de arquivo: 0.24.0.0
- Arquivo original: Lua-Flash-Player.exe

O GitHub Actions verifica os metadados e o ícone diretamente no arquivo executável. A build Windows continua portátil, com o LÖVE 11.5 incorporado, e não possui assinatura digital.

## Testes

Executar a partir da raiz do repositório:

    lua tests/focus_nav_test.lua
    lua tests/gui_smoke.lua
    python3 tests/windows_resource_test.py
    python3 tests/windows_package_test.py
    python3 tools/package_player.py

O CI também verifica a renderização real do LÖVE em display virtual, abertura de jogos, compactação do executável e leitura Unicode no Windows. Ainda são necessários testes físicos com teclados e computadores variados.

O Studio não foi alterado. O formato LUAFGAME 9 continua compatível com versões anteriores.
