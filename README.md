# Lua-Flash

**O Flash renasce em Lua: novo Player + novo Studio.**

O projeto recupera a proposta que tornou o Flash popular: uma ferramenta para **criar, publicar e executar** jogos, animações e experiências interativas com ferramentas visuais e linguagem Lua.

Este é um software **independente**. **Não é um emulador do Adobe Flash Player** e **não pretende abrir SWF, FLA ou XFL**, nem executar ActionScript. O formato e as APIs são novos e pertencem ao Lua-Flash.

## Produtos e arquitetura

| Componente | Papel |
|---|---|
| **Lua-Flash Player** | Executar cenas do nosso formato, com a linha do tempo e o renderizador compartilhado |
| **Lua-Flash Studio** | Criar essas cenas visualmente com palco, timeline, camadas e ferramentas |
| **Núcleo comum** | Documento `.lflash`, modelo de quadros e renderização |

Na arquitetura inicial, Lua e [LÖVE 11.5](https://love2d.org/) implementam a aplicação desktop. Outras plataformas exigem desenvolvimento e testes próprios.

## Estado — versão 0.1 experimental

O repositório contém **uma base de código para executar**, ainda não validada graficamente em uma instalação real do LÖVE:

- Alternância **Studio/Player** pelo botão da interface ou `Tab`.
- Palco 2D, desenho com pincel, linhas, retângulos e elipses; seleção, movimento e borracha.
- Camadas, visibilidade no modelo, quadros-chave e linha do tempo.
- Reprodução em FPS configurável (modelo) e preview dentro do Player.
- Salvar e reabrir projetos no formato próprio `.lflash`, exportar um quadro para SVG.
- Testes automatizados para o formato, quadros-chave e relógio do Player.

**Ainda não há:** scripting de projetos, sistema de eventos, áudio, interpolação avançada, formato de publicação final, importação de assets e distribuição Android/Web. Não rode projetos Lua arbitrários baixados da internet — não existe sandbox de scripts de terceiros.

## Rodar (desktop)

Instale [LÖVE 11.5](https://love2d.org/), clone o repositório e execute na pasta raiz:

```bash
love .
```

O botão **STUDIO** abre a edição e **PLAYER** a visualização. Os comandos de arquivo utilizam a pasta de dados privada do LÖVE (exibida na barra de status após salvar). É possível arrastar um `.lflash` para a janela.

### Atalhos

- `Tab`: alternar Studio/Player. `Espaço`: reproduzir/pausar. `← / →`: navegar quadros.
- `V` seleção, `B` pincel, `L` linha, `R` retângulo, `O` elipse, `E` borracha.
- `F6`: adicionar quadro-chave. `Shift+F6`: retirar quadro-chave.
- `Ctrl+S`: salvar. `Ctrl+O`: abrir último salvo. `Ctrl+E`: exportar SVG.
- `Ctrl+Z / Ctrl+Y`: desfazer/refazer. `+/-`: espessura do traço.

## Testes

```bash
lua tests/model_test.lua
```

O teste é independente do LÖVE. O pipeline no GitHub Actions verifica sintaxe e testa o modelo em Lua 5.4. A interface ainda precisa de validação em dispositivos reais.

## Evolução

Veja o [roadmap do Player + Studio](docs/ROADMAP.md).

Lua-Flash não é afiliado nem endossado pela Adobe e não redistribui programas, marcas gráficas ou arquivos proprietários dela.
