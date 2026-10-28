# Lua-Flash Studio 0.2 — editor experimental

Editor visual do ecossistema Lua-Flash para projetos nativos `.lflash`. O Studio é um aplicativo separado do Player e **ainda não está homologado como versão 1.0**.

## Executar

Com LÖVE 11.5 instalado, na raiz do repositório:

```bash
love studio-lua
```

A CI também produz o artefato `lua-flash-studio-0.2-love`, que contém `Lua-Flash-Studio-0.2.love`. Abra-o com LÖVE 11.5.

## Recursos

- Palco, pincel, linhas, retângulos, elipses, borracha e seleção.
- Camadas, timeline, quadros-chave e prévia.
- Salvar / abrir projeto `.lflash` e exportar o quadro atual para SVG.
- Histórico de desfazer/refazer (até 40 instantâneos).
- **Ctrl+N**: criar projeto novo, com possibilidade de desfazer imediatamente via Ctrl+Z.
- **F7**: ocultar/mostrar camada atual.
- **F8**: bloquear/desbloquear camada atual.
- **F6**: inserir quadro-chave; **Shift+F6**: remover.
- **Ctrl+C / Ctrl+V**: copiar formas do quadro atual e colar como quadro-chave na posição atual (na camada selecionada). A cópia é independente e pode ser desfeita.
- **PageUp / PageDown**: ir para o quadro-chave anterior / seguinte da camada atual.
- **Home / End**: ir ao primeiro / último quadro da timeline.
- **Roda do mouse sobre a timeline**: deslocar a janela de quadros; **Ctrl+roda**: ampliar/reduzir o tamanho das células (12–38 px).
- **Arrastar quadro-chave na timeline**: mover para quadro vazio da camada atual. **Ctrl+arrastar**: duplicar mantendo a origem. Destinos ocupados não são sobrescritos. O primeiro quadro-chave (quadro 1) não pode ser movido, mas pode ser duplicado.
- **Ctrl+S**: salvar o projeto com o nome atual na pasta de dados LÖVE.
- **Ctrl+Shift+S**: Salvar como, com nome personalizado (letras, números, `_` e `-`), recusando sobrescrever arquivo com outro nome já existente.
- **Camadas**: botões `O/-` e `L/X` ao lado do nome permitem mostrar/ocultar e bloquear/desbloquear cada camada com o mouse.
- **Ctrl+O**: reabrir o último `projeto.lflash` salvo.
- **Ctrl+E**: exportar quadro como `quadro.svg`.
- **Tab**: alternar Studio / prévia Player.

**Ctrl+S substitui o arquivo atualmente associado ao projeto**. Para criar um arquivo separado, use Ctrl+Shift+S. Faça cópias de segurança dos projetos importantes antes de editar. O Studio não oferece execução de scripts de jogo nem empacotamento de jogos LUAFGAME; essas funções permanecem no fluxo de ferramentas/Player.

## Validação

```bash
lua tests/studio_edit_test.lua
lua tests/gui_smoke.lua
python3 tools/package_studio.py
```

Os testes automatizados não substituem uma validação manual da interface, de janelas compactas, do fluxo completo de edição nem das builds nativas Windows. O Player 0.28 permanece independente em `../player-lua/`.

Para testar no Player, salve com Ctrl+S e abra o projeto pelo Player. Ambos usam a mesma identidade de armazenamento do LÖVE (`lua-flash`), ou você pode arrastar um `.lflash` para o Player.
