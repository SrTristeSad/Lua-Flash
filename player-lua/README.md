# Lua-Flash Player 0.3 — eventos e minijogo

Runtime independente do **Lua-Flash**, criado em Lua com [LÖVE 11.5](https://love2d.org/). Esta versão **não** executa SWF/ActionScript nem código Lua fornecido por arquivos de terceiros: abre exclusivamente documentos nativos `.lflash`.

## Iniciar

Na raiz do repositório:

```bash
love player-lua
```

Ou execute o pacote `.love` gerado no GitHub Actions com LÖVE 11.5 instalado.

## Novidade 0.3 — Interatividade real dentro do palco

- **Mouse:** clique, movimentação, soltura e detecção do objeto sob o ponteiro.
- **Toque:** suporte aos callbacks `love.touchpressed`, `love.touchmoved` e `love.touchreleased`, com coordenadas em pixels, de acordo com o LÖVE 11.5.
- **Teclado:** estados de teclas pressionadas/soltas e tratamento de eventos no Player.
- **Transformação de coordenadas:** reconhece a área real do palco com centralização e letterboxing, inclusive após redimensionar a janela.
- **Hit-testing:** respeita as camadas visíveis, a ordem de desenho e a geometria de retângulos, elipses, linhas e traços. Pode usar as formas interpoladas quando o modo suave está ativo.
- **Captura de ponteiro:** cliques só são reconhecidos se a pressão e a soltura atingirem o mesmo objeto sem ultrapassar o limiar de movimento. Identificadores de toque são tratados separadamente.

Esse sistema é usado por uma demonstração jogável local. **Ainda não é uma API pública de scripts para jogos produzidos por usuários.** A etapa seguinte inclui publicar a API de eventos, definir um modelo seguro de projetos interativos e uma forma de exportação.

## Minijogo: Acerte a Bola

Clique **JOGAR** ou pressione `G` para iniciar uma sessão de 30 segundos. Acerte a bola azul em movimento clicando ou tocando nela. Também é possível mover a mira com **WASD** e disparar com **Enter**. A pontuação e os erros aparecem sobre o palco. Clique novamente em JOGAR para reiniciar.

O jogo é código interno confiável (`src/target_game.lua`), criado somente como teste do runtime. Nenhum script recebido de arquivos `.lflash` é executado.

## Controles normais

| Comando | Ação |
|---|---|
| `Espaço` | Reproduzir / pausar |
| `← / →` | Quadro anterior / próximo |
| `Home / End` | Primeiro / último quadro |
| `+ / -` | Velocidade entre 0,25× e 4× |
| `I` | Interpolação visual ligada / desligada |
| `L` | Repetição ligada / desligada |
| `D` | Reiniciar demonstração de animação (fora do minijogo) |
| `G` | Abrir ou reiniciar minijogo |
| `O` | Abrir o último projeto salvo pelo Studio |
| `Ctrl+S` | Salvar uma cópia como `player_demo.lflash` |
| `F11` | Tela cheia |
| `Esc` | Sair da tela cheia ou fechar aplicativo |
| Arrastar arquivo `.lflash` | Abrir o projeto no Player |
| Barra de progresso | Ir a um quadro |
| Roda do mouse | Avançar / retroceder um quadro |

**Quando o minijogo estiver ativo**, as teclas `WASD` movimentam a mira, inclusive `D` (não reinicia a demonstração), e `Enter` dispara.

## Arquitetura

- `src/model.lua`: modelo e codec nativo compartilhados com Studio.
- `src/runtime.lua`: desenho e geometria de palco, compartilhados com Studio.
- `src/transport.lua`: ritmo, quadros, velocidade e loop.
- `src/interpolation.lua`: interpolação visual opcional.
- `src/input.lua`: mapeamento de coordenadas, hit-testing e eventos de entrada.
- `src/target_game.lua`: minijogo de demonstração, sem dependência do Studio.
- `main.lua`: janela e ligação entre os módulos.

Somente a pasta `player-lua/` foi modificada na evolução do runtime; o código do Studio foi preservado.

## Testar e gerar pacote

A partir da raiz do repositório:

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/input_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O pacote resultante é `dist/Lua-Flash-Player-0.3.love` e precisa do LÖVE instalado. Testes de código e simulações de callbacks executam na CI; ainda faltam testes gráficos manuais e medições de desempenho reais.

## Limites

Sem suporte a SWF, FLA, XFL e ActionScript antigos. Sem importação de mídia, áudio sincronizado, objetos hierárquicos, API de jogos externos, sandbox de scripts ou empacotamento nativo autossuficiente. A interface pode precisar de ajustes para tamanhos de tela reduzidos.
