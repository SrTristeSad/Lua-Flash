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
- **Ctrl+F8**: criar símbolo `Graphic` copiando o desenho do quadro ativo; **Ctrl+Shift+F8**: `MovieClip`; **Ctrl+Alt+F8**: `Button`.
- **Biblioteca de símbolos**: lista até cinco símbolos na lateral; clique no nome e depois no palco para criar uma instância reutilizável. **Ctrl+F10** adiciona uma pose usando os desenhos do quadro atual do palco; as poses são normalizadas individualmente para a origem superior esquerda do símbolo (edição de pivô e tween ainda não disponíveis).
- **Prévia temporal experimental**: `Graphic` percorre seus quadros internos conforme a timeline principal (reinicia numa nova chave da trilha), enquanto `MovieClip` usa relógio próprio por instância durante a reprodução e pausa com o projeto. `Button` exibe **Up, Over, Down** nos quadros 1–3, e o quadro 4, quando presente, define a área de clique (Hit, não desenhado); o mouse interage com o Button no modo **PLAYER/TAB** do Studio. Não executa scripts ou eventos de clique de ActionScript.
- **Salvamento de símbolos**: o Studio grava um arquivo auxiliar `nome.lflash.lflib` além de `nome.lflash`. Mantenha **os dois arquivos juntos**. O Player Lua 0.28 não lê a biblioteca auxiliar e, por enquanto, não reproduz essas instâncias; somente o Studio as desenha em prévia. Abrir apenas o `.lflash` ou importá-lo por arrastar não recupera a biblioteca auxiliar.
- **Histórico**: desfazer/refazer inclui a biblioteca e as instâncias criadas, além do documento principal.

- **Ctrl+C / Ctrl+V**: copiar desenhos **e instâncias de símbolos** do quadro atual, colando ambos em um novo quadro-chave na camada ativa. A cópia atribui novos IDs às instâncias, limpa exposições antigas no destino e pode ser desfeita. Símbolos referenciados precisam existir na biblioteca do projeto.
- **PageUp / PageDown**: ir para o quadro-chave anterior / seguinte da camada atual.
- **Home / End**: ir ao primeiro / último quadro da timeline.
- **Timeline multicamadas**: exibe até três trilhas simultaneamente, começando pela camada ativa; clicar noutra trilha seleciona aquela camada.
- **Roda do mouse sobre a timeline**: deslocar a janela de quadros; **Ctrl+roda**: ampliar/reduzir o tamanho das células (12–38 px).
- **Shift+clique nos quadros-chave**: selecionar ou retirar vários quadros da seleção (destacados em roxo). Arraste um dos selecionados para mover todos juntos; Ctrl+arrastar duplica o grupo. A operação é atômica: se qualquer destino estiver ocupado ou fora dos limites, nada é alterado.
- **Arrastar quadro-chave na timeline**: mover para quadro vazio da camada atual. **Ctrl+arrastar**: duplicar mantendo a origem. Destinos ocupados não são sobrescritos. O primeiro quadro-chave (quadro 1) não pode ser movido, mas pode ser duplicado.
- **Sincronização de instâncias na timeline**: mover ou duplicar um ou vários quadros-chave transfere também as instâncias associadas às posições de origem, de forma atômica. Duplicações recebem IDs novos. Uma colisão em qualquer trilha de instâncias impede todo o movimento. Instâncias não são movidas entre camadas distintas nesta versão.
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
lua tests/studio_symbols_test.lua
lua tests/studio_timeline_ops_test.lua
lua tests/studio_symbol_motion_test.lua
lua tests/gui_smoke.lua
python3 tools/package_studio.py
```

Os testes automatizados não substituem uma validação manual da interface, de janelas compactas, do fluxo completo de edição nem das builds nativas Windows. O Player 0.28 permanece independente em `../player-lua/`.

Para testar no Player, salve com Ctrl+S e abra o projeto pelo Player. Ambos usam a mesma identidade de armazenamento do LÖVE (`lua-flash`), ou você pode arrastar um `.lflash` para o Player.
