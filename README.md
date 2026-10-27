# Lua-Flash

O **Flash renasce em Lua**: uma nova plataforma independente para criar e executar animações e jogos, **sem compatibilidade obrigatória com SWF/FLA/XFL ou ActionScript** antigos.

## Aplicações

| Aplicação | Diretório | Comando | Versão |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.6 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Novidades do Player 0.6

O **LUAFGAME 3** permite **IDs nomeados para um mesmo objeto em quadros-chave diferentes**. O nome `bola` pode ser associado a índices de forma distintos em cada quadro-chave. Também introduz **colisões entre objetos nomeados**, com regras `COLLIDE` disparadas apenas ao iniciar o contato.

Os pacotes `LUAFGAME 1` e `LUAFGAME 2` continuam abrindo, sem converter os arquivos antigos. O Player executa apenas **regras declarativas previamente autorizadas**, nunca scripts Lua trazidos por `.lfgame`.

A demonstração **PACOTE** exibe uma bola azul e uma barreira vermelha, contando contatos e toques. O botão **JOGAR** preserva o minijogo tradicional.

## Executar e distribuir

Instale [LÖVE 11.5](https://love2d.org/). Na raiz do repositório:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.6.lfgame
```

A distribuição `dist/Lua-Flash-Player-0.6.love` exige LÖVE instalado. Builds e jogos de exemplo estão nos artefatos das execuções do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

Consulte o [manual do Player](player-lua/README.md), a [especificação LUAFGAME 3](docs/FORMAT_LUAFGAME3.md) e o [roteiro de desenvolvimento](docs/ROADMAP.md).

Projeto independente, sem vínculo com a Adobe.
