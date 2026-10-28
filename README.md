# Lua-Flash

**O Flash renasce em Lua** — Player de animações e jogos próprios, sem compatibilidade com SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicativo | Diretório | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.20 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.20 — executável Windows portátil

A versão 0.20 acrescenta uma **build Windows x64 portátil** que inclui o runtime oficial LÖVE 11.5, sem exigir a instalação separada do LÖVE.

O GitHub Actions disponibiliza dois artefatos:
- **`lua-flash-player-0.20-windows-x64-portable`**: ZIP com `Lua-Flash-Player-0.20-Windows-x64.zip`. Extraia o ZIP interno inteiro e execute `Lua-Flash-Player.exe`. **Mantenha as DLLs na mesma pasta**.
- **`lua-flash-player-0.20-love-and-game`**: formato `.love` tradicional com exemplos `.lfgame`, para quem já possui LÖVE ou quer testar em Linux/macOS.

A distribuição portátil é preparada usando o `love-11.5-win64.zip` oficial com SHA-256 fixo e conferido. O executável Windows é construído pela concatenação do `love.exe` com o arquivo `.love`, preservando as bibliotecas, avisos e licenças do runtime. O pipeline verifica o cabeçalho PE, as DLLs e o conteúdo Lua embutido, e testa a inicialização de linha de comando do executável em um runner Windows.

**Ainda é uma build experimental**, não um instalador MSI e não é assinada digitalmente. O Windows poderá mostrar aviso do SmartScreen. A inicialização gráfica e o desempenho ainda necessitam de testes manuais em PCs e GPUs reais. Não remova as DLLs distribuídas com o aplicativo.

Os projetos continuam compatíveis com LUAFGAME 1–9 e `.lflash`. O Studio não foi modificado; os jogos importados não executam scripts Lua arbitrários.

## Rodar pelo código-fonte

Com [LÖVE](https://love2d.org/) instalado:

```bash
love player-lua
python3 tools/package_player.py
```

## Empacotamento Windows, para desenvolvedores

```bash
python3 tools/package_player.py
python3 tools/package_player_windows.py --love-zip love-11.5-win64.zip --game dist/Lua-Flash-Player-0.20.love --output dist/Lua-Flash-Player-0.20-Windows-x64.zip
```

O segundo comando exige o ZIP oficial exato e verifica seu SHA-256; não aceita uma distribuição modificada. Os scripts de empacotamento usam somente Python padrão.

[GitHub Actions — downloads](https://github.com/SrTristeSad/Lua-Flash/actions) · [Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md).

Projeto independente e não afiliado à Adobe.
