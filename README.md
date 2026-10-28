# Lua-Flash

**O Flash renasce em Lua** — Player independente para animações e jogos em formatos próprios. Não reproduz SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicativo | Pasta | Estado |
|---|---|---|
| [Player Lua](player-lua/) | `player-lua/` | **0.25 experimental** |
| [Studio Lua](studio-lua/) | `studio-lua/` | 0.1 experimental; preservado |

## Player 0.25 — editor por teclado e alto contraste

O Player agora amplia a navegação por **Tab/Shift+Tab** e **Enter** aos controles visíveis do editor de quadros-chave: troca de sprite, seleção de chaves, inserção/remoção, movimento temporal, posição X/Y, ângulo, escala, desfazer, curva e salvar. O destaque de foco acompanha os mesmos alvos usados pelo mouse.

**F2** alterna um **tema de alto contraste**, que aumenta o contraste dos painéis e dos controles principais e realça o foco. A preferência é salva como texto simples em `player-settings.txt` dentro da pasta de dados do LÖVE, e restaurada na próxima abertura. **F1** inclui o novo atalho na ajuda.

O formato continua **LUAFGAME 9**, e os jogos LUAFGAME 1–9 e animações `.lflash` permanecem compatíveis. **Não houve alterações no Studio** nem inclusão de scripts executáveis fornecidos por jogos.

## Download

As builds aprovadas estão no [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions):

- `lua-flash-player-0.25-windows-x64-portable`: Windows 64 bits portátil; extrair o ZIP inteiro para uma pasta e iniciar `Lua-Flash-Player.exe` com as DLLs. Não exige instalar LÖVE separadamente.
- `lua-flash-player-0.25-love-and-game`: `.love` com jogos de exemplo para sistemas com [LÖVE](https://love2d.org/) instalado.

A distribuição Windows ainda não é assinada digitalmente e pode exibir aviso do SmartScreen. Acessibilidade via leitor de tela e testes manuais em hardware real ainda estão pendentes.

## Testes e documentação

```bash
love player-lua
lua tests/editor_nav_test.lua
lua tests/visual_settings_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_resource_test.py
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente da Adobe.
