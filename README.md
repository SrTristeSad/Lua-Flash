# Lua-Flash

**O Flash renasce em Lua** — Player independente para jogos e animações em formatos próprios, sem execução de SWF/FLA/ActionScript da Adobe.

## Projetos independentes

| Aplicativo | Pasta | Estado |
|---|---|---|
| [Player Lua](player-lua/) | `player-lua/` | **0.28 experimental** |
| [Studio Lua](studio-lua/) | `studio-lua/` | 0.1 experimental, preservado |

## Player 0.28 — recorte de formas e interpolação mais eficiente

O Player agora tem um **renderizador vetorial exclusivo**, em `player-lua/src/viewport_renderer.lua`, que descarta formas totalmente fora dos limites do palco antes de solicitar seu desenho ao LÖVE. A detecção considera os limites geométricos e uma margem conservadora para os traços: linhas e pinceladas que ainda alcançam a borda permanecem visíveis. A ordem das camadas, o fundo e as formas presentes no palco não mudam.

O renderizador funciona tanto na reprodução exata como na interpolação suave. Os limites de cada forma são reutilizados por cache fraco (*weak keys*), sem manter indefinidamente formas interpoladas que não são mais usadas. A alteração é **somente do Player**: o renderizador compartilhado do Studio não foi modificado.

A interpolação agora valida a compatibilidade das formas **uma vez para cada par de quadros-chave**, na abertura de um projeto; não repete essa verificação inteira a cada amostra. Quando há formas incompatíveis, o comportamento original de manter o quadro anterior é preservado. Há um método `reindex` para reconstruir as verificações depois de uma alteração autoral.

No painel **F3**, também aparecem os contadores de formas desenhadas e descartadas no quadro, além das medidas de CPU introduzidas na 0.27. Os testes incluem casos de bordas, pinceladas, elipses, pequenas janelas e um cenário com **11.520 formas vetoriais**. Os números do teste de renderização representam chamadas de desenho evitadas, **não FPS medido em hardware real**.

O formato permanece **LUAFGAME 9**; jogos LUAFGAME 1–9 e animações `.lflash` continuam compatíveis. **O Studio não foi alterado.**

## Downloads

Nas execuções aprovadas do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions), baixe:

- **`lua-flash-player-0.28-windows-x64-portable`**: ZIP Windows com `Lua-Flash-Player.exe` e as DLLs do LÖVE 11.5 incluídas. Extraia tudo antes de executar; não é preciso instalar LÖVE.
- **`lua-flash-player-0.28-love-and-game`**: `.love` e jogos de exemplo, para computadores com [LÖVE](https://love2d.org/) instalado.

O executável Windows exibe a versão **0.28.0.0** e permanece sem assinatura digital; o SmartScreen pode apresentar alertas. A plataforma continua experimental até testes e homologação com GPUs físicas.

## Testes

```bash
love player-lua
lua tests/viewport_renderer_test.lua
lua tests/interpolation_segments_test.lua
lua tests/culling_stress_test.lua
lua tests/stress_player_test.lua
lua tests/gui_smoke.lua
python3 tools/package_player.py
```

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md)

Projeto independente e não afiliado à Adobe.
