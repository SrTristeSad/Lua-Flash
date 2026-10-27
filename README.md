# Lua-Flash

**O Flash renasce em Lua.** Plataforma independente para criar e reproduzir experiências interativas. Não é emulador SWF e não oferece compatibilidade com arquivos ou ActionScript antigos da Adobe.

## Aplicativos separados

| Aplicação | Diretório | Executar | Versão |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.3 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

O Player já executa animações nativas `.lflash`, tem controle de quadros, velocidades ajustáveis, interpolação opcional, **entrada de mouse, toque e teclado**, detecção de objetos e um minijogo integrado.

O Studio permanece separado com sua base de desenho, camadas e quadros-chave. O Player não executa scripts Lua externos nos projetos; uma API segura para jogos de terceiros será desenvolvida posteriormente.

## Testar Player e gerar pacote

Instale [LÖVE 11.5](https://love2d.org/) para executar o programa:

```bash
love player-lua
```

Para criar a distribuição `.love`:

```bash
python3 tools/package_player.py
```

Saída: `dist/Lua-Flash-Player-0.3.love`. O pacote necessita do LÖVE instalado e não é um executável Windows completo. As execuções aprovadas do **[GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions)** publicam a mesma distribuição como artefato.

## Verificação

```bash
lua tests/model_test.lua
lua tests/player_test.lua
lua tests/input_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
```

Testes automatizados cobrem o modelo, reprodução, eventos, minijogo e simulação de callbacks. Testes visuais reais e desempenho ainda precisam de validação.

Leia o [manual do Player](player-lua/README.md), o [roadmap](docs/ROADMAP.md) e os [estudos de engenharia reversa](docs/ANALISE_FLASH_PLAYER_32.md).

Lua-Flash é um projeto independente, sem vínculo com a Adobe.
