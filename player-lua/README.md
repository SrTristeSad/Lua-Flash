# Lua-Flash Player 0.10 — transparência PNG e otimização

O Player Lua é nosso runtime independente, desenvolvido em Lua com LÖVE 11.5. Executa animações `.lflash` e jogos declarativos `.lfgame` de versões 1 a 6, sem executar código Lua externo.

## Novidades da versão 0.10

**Detecção de pixels opacos.** O Player agora consulta o canal alfa de cada PNG antes de aceitar cliques e toques sobre sprites interativos. Pixels com alfa inferior a 10% não contam como alvo. Uma forma vetorial que possua um sprite interativo associado não permite contornar essa transparência: cliques transparentes podem chegar aos outros objetos realmente posicionados atrás dela.

**Colisões mais precisas.** A caixa delimitadora é usada apenas para rejeitar pares distantes. Havendo interseção, o motor examina pixels opacos projetados no palco antes de acionar as regras `COLLIDE`. Sprites versus retângulos e elipses usam os testes geométricos dessas formas; linhas e pincéis ainda são aproximados por caixa delimitadora.

**Controle de custo.** As máscaras alfa são montadas de forma **preguiçosa (lazy)** a partir de `love.image.newImageData` e guardadas como linhas compactas de bytes 0/1, uma máscara por PNG utilizado. Uma colisão muito grande possui limite de **65.536 amostras por par**; portanto, detalhes transparentes extremamente finos podem produzir falsos negativos em casos extremos. Esta versão não promete colisões exatas por pixel em todas as escalas possíveis.

**Cache da timeline.** O cálculo de uma cena interpolada é reutilizado quando renderização, colisões e entrada consultam a mesma posição fracionária. A troca de posição invalida automaticamente a cena anterior. Nada é alterado no arquivo de edição do Studio.

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e execute, na raiz do repositório:

```bash
love player-lua
```

O botão **PACOTE** abre a demonstração com sprite animado, PNG transparente e áudio por quadro. Comandos preservados: espaço para play/pause, setas para navegar por quadros, I para interpolação, F8/F9 para volume, F10 para silenciar e F11 para tela cheia. Jogos podem ser arrastados para a janela.

Para publicar jogos, continue utilizando `tools/make_game.lua`, `tools/attach_media.lua`, `tools/bind_sprite.lua` e `tools/animate_media.lua`. **Não houve alteração de formato** nesta versão: o formato mais recente continua sendo `LUAFGAME 6`.

## Testes

```bash
lua tests/pixel_mask_test.lua
lua tests/package_v6_test.lua
lua tests/package_v5_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI inclui testes de transparência, colisão, cache, compatibilidade com formatos anteriores e inicialização gráfica com LÖVE em display virtual.

**Limitações conhecidas:** sem alpha máscaras rotacionadas, colisão contínua contra objetos muito rápidos, áudio sincronizado por amostra, scripts externos isolados ou EXE Windows autônomo. O desempenho em dispositivos reais continua pendente de testes manuais.
