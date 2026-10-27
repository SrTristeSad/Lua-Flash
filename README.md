# Lua-Flash

**O Flash renasce em Lua: novo Player + novo Studio.**

O projeto recupera a proposta que tornou o Flash popular: uma ferramenta simples e poderosa para **criar, publicar e executar** jogos, animações e experiências interativas.

Este é um software **independente**, escrito principalmente em Lua. **Não é um emulador do Adobe Flash Player**, nem pretende abrir os antigos arquivos `.swf`, `.fla` ou `.xfl`, tampouco executar ActionScript.

## A arquitetura

| Componente | Papel |
|---|---|
| **Lua-Flash Player** | Executar obras produzidas na nossa plataforma, com gráficos, animações, eventos e interação |
| **Lua-Flash Studio** | Criar essas obras visualmente: palco, timeline, ferramentas, camadas, símbolos e Lua |
| **Núcleo comum** | Compartilhar formato de projeto, modelo de cena e renderização |

A referência histórica é a **experiência de criação e distribuição de Flash**, não a retrocompatibilidade.

## Situação da implementação

**0.1 experimental, em desenvolvimento.** O modelo de documentos `.lflash` já está no repositório. O Player/Studio gráfico será construído sobre LÖVE, ainda sem garantia de funcionamento em todas as plataformas.

Não confundir o protótipo com um Flash Player completo: ainda faltam recursos de autoria, scripting, sincronização multimídia e empacotamento final.

## Como será usado

1. Criar um projeto no **Lua-Flash Studio**, com palco, camadas, desenhos e código Lua.
2. Testar com o **Lua-Flash Player**, que executa o próprio projeto.
3. Publicar num formato de distribuição próprio para os sistemas suportados.

Veja [o roteiro de desenvolvimento](docs/ROADMAP.md).

## Licenciamento e marcas

A plataforma será desenvolvida de forma independente, sem redistribuir arquivos do software Adobe. "Flash" é usado aqui como referência histórica; não existe vínculo com a Adobe.
