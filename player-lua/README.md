# Lua-Flash Player 0.2 (experimental)

O **Player Lua** é a aplicação de execução do nosso novo ecossistema Flash, independente do editor em `../studio-lua/`. Não é um emulador do Flash da Adobe: aceita somente projetos próprios `.lflash` e não executa SWF, FLA ou ActionScript.

## Iniciar

Instale [LÖVE 11.5](https://love2d.org/) e execute a partir da raiz do repositório:

```bash
love player-lua
```

Ele inicia com uma demonstração nativa que possui apenas **cinco quadros-chave** e utiliza interpolação opcional para movimentar a bola suavemente.

Você pode arrastar um arquivo `.lflash` criado no Studio para a janela, ou clicar em **PROJETO SALVO** para abrir o último `projeto.lflash` gravado pelo Studio na pasta de dados do LÖVE. Os dois apps usam `lua-flash` como identidade de armazenamento local.

## Controles

| Controle | Ação |
|---|---|
| `Espaço` | Pausar/reproduzir |
| `←` e `→` | Avançar/retroceder um quadro e pausar |
| `Home` e `End` | Ir ao primeiro/último quadro |
| `-` e `+` | Reduzir/aumentar a velocidade (0,25× a 4×) |
| `I` | Ativar/desativar interpolação visual |
| `L` | Alternar reprodução em loop |
| `D` | Reabrir a animação de demonstração |
| `O` | Abrir o último projeto salvo pelo Studio |
| `Ctrl+S` | Salvar cópia da cena atual como `player_demo.lflash` |
| `F11` | Tela cheia |
| `Esc` | Sair da tela cheia ou encerrar o programa |
| Barra de progresso | Buscar um quadro específico |
| Roda do mouse | Navegação quadro a quadro |

**Interpolação visual:** a opção `SUAVE` mistura posições, cores e dimensões de formas compatíveis entre quadros-chave da mesma camada. Se a lista de formas diferir em quantidade/tipo/número de pontos, o trecho é mantido sem interpolação. Não altera o arquivo `.lflash` e não é uma implementação completa de motion-tween (sem easing/curvas). O modo começa ligado apenas na demonstração interna; projetos externos são abertos em modo exato para preservar o comportamento criado no Studio.

**Transporte e estabilidade:** o relógio suporta velocidades configuráveis, repetição, modo sem loop e pausa no final. O delta de tempo por atualização é limitado a 0,25 s para evitar saltos grandes após minimizar a janela.

## Arquivos e segurança

- Máximo de **25 MB** por projeto importado via Player.
- Arquivos inválidos são recusados e o Player mantém o projeto atual.
- Os projetos atuais contêm apenas dados de animação; scripts Lua externos **não são executados**.
- Para formatos de publicação e scripts futuros, será necessário um sistema de isolamento e permissões.

## Limites atuais

Renderização de quatro formas vetoriais (pincel, linha, retângulo, elipse), cores e camadas. Ainda não existe motor de áudio/vídeo, script de jogos, sprites hierárquicos, máscaras, gráficos acelerados avançados nem empacotamento de projetos finalizados. Interface e desempenho ainda precisam de testes em máquinas reais com LÖVE.

## Testes

Na raiz do repositório:

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/gui_smoke.lua
```

O GitHub Actions também executa verificação de sintaxe de todos os arquivos Lua.
