# Lua-Flash

**O Flash renasce em Lua** — runtime independente de animações e jogos, usando formatos próprios. Não executa SWF, FLA, XFL ou ActionScript antigos.

## Aplicativos separados

| Aplicativo | Pasta | Execução | Status |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.18 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.18 — robustez e cenas maiores

Esta versão melhora o comportamento diante de falhas de atualização, interface e desenho. Os principais eventos do LÖVE são tratados com proteção de exceções, registradas **localmente** em um arquivo `player-errors.log`, na pasta de dados do aplicativo. O log possui limite de tamanho e suprime repetição contínua da mesma mensagem. Em uma falha recuperável, o Player pausa a animação e tenta mostrar um aviso, evitando perder a sessão por uma exceção simples.

**F3** ainda abre diagnósticos de memória e FPS; **F4** fecha o aviso de erro, sem excluir o registro.

Também otimizamos a busca dos quadros-chave usados na interpolação vetorial: em vez de percorrer todas as chaves de cada camada, ela usa **busca binária**. A CI agora testa cenas sintéticas com **11.520 formas vetoriais** e mais de cem amostras de timeline, além dos testes dos jogos anteriores.

A nova camada de proteção **não garante recuperação de erros internos do LÖVE, GPU, sistema operacional, falta de memória ou falhas irreversíveis**. Os dados de projetos continuam protegidos pelas rotinas de salvamento e recuperação introduzidas nas versões anteriores.

Formatos LUAFGAME 1–9 e animações `.lflash` continuam compatíveis. Pacotes importados são dados, não código executável; o Studio não foi alterado.

## Executar

Instale [LÖVE](https://love2d.org/) e execute na raiz:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.18.lfgame
```

O pacote `dist/Lua-Flash-Player-0.18.love` precisa do LÖVE instalado; ainda não é um EXE Windows independente. Veja os downloads nos artefatos aprovados do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md).

Projeto independente e não afiliado à Adobe.
