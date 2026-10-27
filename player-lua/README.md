# Lua-Flash Player 0.6 — IDs de objetos e colisões

Player independente em Lua, com renderização LÖVE 11.5. Abre projetos autorais `.lflash` e jogos `.lfgame`, **sem execução de SWF nem scripts Lua externos**.

## Executar

```bash
love player-lua
```

Na demonstração **PACOTE**, a bola azul passa por uma barreira vermelha. O motor conta um evento de colisão **na entrada em contato**, não em cada frame sobreposto. Cliques na bola incrementam `toques`; depois do segundo clique, a bola passa a valer pontos. A pontuação e os estados ficam no painel do palco.

Os botões **JOGAR** e **DEMO** mantêm as demonstrações anteriores. É possível arrastar `.lfgame` (jogo) e `.lflash` (animação). `Ctrl+S` salva a cópia do conteúdo aberto.

## LUAFGAME 3

O pacote possui uma cena `.lflash`, uma lista de objetos com IDs legíveis e uma tabela **BIND** que associa cada ID a uma forma para um quadro-chave específico. Assim, `bola` pode referenciar a forma 1 num quadro-chave e a forma 2 em outro sem perder a identidade no jogo exportado.

A regra `COLLIDE bola barreira` detecta a entrada de um contato. Regras condicionais, contadores `STATE` e ações `ADD`, `SET`, `SCORE`, `SEEK`, `PLAY`, `PAUSE` continuam disponíveis.

**Limite importante:** os IDs persistem no próprio pacote `.lfgame` ao longo dos quadros-chave mapeados, não nos arquivos `.lflash` do Studio. Ao alterar o índice de uma forma **dentro do mesmo quadro-chave** ou republicar um arquivo editado, o autor deve atualizar seus vínculos BIND. A integração de IDs diretamente no modelo de autoria é uma etapa futura.

As colisões usam formas geométricas em coordenadas do palco: retângulo-retângulo, elipse-retângulo e elipse-elipse têm testes geométricos; linhas e pincéis ainda usam caixas delimitadoras (aproximação). Há tratamento de camadas e quadros, incluindo interpolação opcional.

Pacotes v1 (0.4) e v2 (0.5) abrem normalmente; o formato antigo não precisa ser refeito. A documentação técnica está em [LUAFGAME 3](../docs/FORMAT_LUAFGAME3.md).

## Criar jogos

Converter uma animação simples do Studio:

```bash
lua tools/make_game.lua cena.lflash meu-jogo.lfgame 2 1 8 30 smooth
```

A ferramenta gera um jogo LUAFGAME 3 com ID `alvo`, criando vínculos para a forma indicada em cada quadro-chave onde ela exista. Se o objeto trocar de índice em quadros diferentes, edite os vínculos por meio de um gerador próprio usando `src/package_v3.lua`. Regras complexas podem ser elaboradas em um script **local de autoria**, mas o arquivo exportado contém apenas dados.

Exportar a demonstração com colisões:

```bash
lua tools/export_example.lua dist/Exemplo-0.6.lfgame
```

## Recursos anteriores preservados

- Player/Studio em pastas independentes.
- Reprodução, pausa, velocidade de 0,25× a 4×, loop, scrub e tela cheia.
- Formas vetoriais, camadas, quadros-chave e interpolação visual opcional.
- Mouse, teclado e touch com hit-testing do palco.
- Sessões com placar, limite de tempo, vitória e regras condicionais.
- Carregamento de conteúdo sem execução arbitrária de scripts.

## Build e testes

```bash
lua tests/package_v3_test.lua
lua tests/package_v2_test.lua
lua tests/package_test.lua
lua tests/input_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O GitHub Actions também inicia o Player com **LÖVE real em um display virtual** e anexa uma distribuição `.love`.

Versão experimental: faltam colisões geométricas precisas para linhas/curvas, IDs dentro do editor, áudio sincronizado, recursos importados, motor de scripts isolados e builds nativos desktop/Android/Web. Testes visuais manuais e benchmarks em dispositivos reais ainda são necessários.
