# Lua-Flash Player 0.1

**Aplicacao independente** para executar as animacoes criadas no nosso formato nativo `.lflash`. Nao executa projetos Flash antigos (SWF/ActionScript).

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e, na raiz do repositorio:

```bash
love player-lua
```

Abre uma animacao de demonstracao automaticamente. Para abrir outra, arraste um arquivo `.lflash` sobre a janela. Use **PROJETO SALVO** para abrir o ultimo `projeto.lflash` criado no Studio, caso use a mesma pasta de armazenamento LÖVE.

## Controles

- `Espaco`: reproduzir ou pausar.
- `Seta esquerda/direita`: retroceder/avancar um quadro.
- `Home/End`: inicio/fim da linha do tempo.
- `F11`: tela cheia. `Esc`: sair da tela cheia ou encerrar o programa.
- `D`: demo interna; `O`: ultimo projeto salvo; `L`: alternar loop.
- `Ctrl+S`: gravar a cena atual como `player_demo.lflash` para teste de interoperabilidade.
- Clique na barra de progresso para pular para um quadro.

A linha do tempo, o renderizador e a decodificacao sao Lua. Graficos e entrada usam LÖVE, sem codigo proprietario da Adobe. O Player nao executa codigo Lua encontrado nos arquivos `.lflash`: o conteudo atual e somente dados de animacao.

### Estado real

Esta e uma base experimental: executa camadas e formas vetoriais simples e quadros-chave, mas nao possui ainda audio, input em jogos, interpolacao de movimento, motor de scripts isolado ou pacote publicavel. Interfaces graficas e controles precisam de testes manuais em instalacoes do LÖVE.
