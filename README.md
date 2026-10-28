# Lua-Flash

**O Flash renasce em Lua** — Player original de jogos e animações, sem suporte a SWF/FLA/ActionScript antigos.

## Aplicações independentes

| Aplicação | Pasta | Executar | Situação |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.23 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.23 — interface adaptável e ícone integrado ao executável

O Player agora ajusta proporcionalmente o palco e os controles em **janelas menores**, incluindo 600 × 380 e 640 × 400. A escala mantém as proporções do layout; faixas laterais podem aparecer para preservar a geometria. O cálculo inverso do mouse e do toque mantém os cliques alinhados aos botões e ao palco, inclusive com recortes corretos de sprites e formas.

A janela Windows opera com suporte `highdpi` do LÖVE. A interface usa as coordenadas lógicas reportadas pelo LÖVE e não presume que um pixel de janela equivale a um pixel físico em monitores com DPI diferente.

O ícone original Lua-Flash (raio e arco) foi **incorporado ao recurso de ícone do próprio `.exe`**, além de continuar sendo aplicado à janela e disponibilizado como `.ico` para atalhos. O empacotador altera os recursos do executável oficial LÖVE 11.5 **antes** de acrescentar o pacote do jogo, preservando o conteúdo `.love`. O GitHub Actions verifica os bytes do ícone dentro do executável Windows.

Os jogos LUAFGAME 1–9 e as animações `.lflash` continuam compatíveis. O **Studio não foi modificado**. Arquivos externos permanecem dados validados, não scripts executados.

## Downloads

Na execução aprovada do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions), baixe:

- **`lua-flash-player-0.23-windows-x64-portable`** — ZIP Windows com `Lua-Flash-Player.exe`, DLLs do LÖVE oficial e `ABRIR-JOGO.cmd`. Extraia todo o conteúdo para uma pasta e abra o EXE, sem instalar LÖVE.
- **`lua-flash-player-0.23-love-and-game`** — arquivo `.love` e exemplos para computadores com [LÖVE](https://love2d.org/) instalado.

A distribuição continua **sem assinatura digital** e pode exibir avisos do Windows SmartScreen. Embora o executável seja iniciado no CI Windows, o uso com diferentes monitores DPI/GPU ainda exige testes em PCs reais.

## Desenvolvimento e testes

```bash
love player-lua
lua tests/responsive_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_resource_test.py
python3 tests/windows_package_test.py
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente da Adobe.
