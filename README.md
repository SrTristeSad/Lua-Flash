# Lua-Flash

**O Flash renasce em Lua** — uma plataforma independente de jogos e animações, com formatos próprios. Este projeto **não executa SWF, FLA, XFL ou ActionScript antigos**.

## Aplicativos separados

| Aplicativo | Pasta | Iniciar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.10 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Player 0.10 — transparência e desempenho

- **PNG com transparência:** cliques sobre pixels transparentes deixam de ativar o sprite nem a forma vetorial que ele substitui. Outros objetos atrás dele podem ser alcançados normalmente.
- **Colisões refinadas:** além da caixa delimitadora, o motor verifica pixels opacos na interseção de sprites e de sprites com retângulos/elipses. Em áreas grandes, a análise usa amostragem limitada para manter o custo controlado.
- **Cache de máscaras:** cada PNG é decodificado para sua máscara alfa compacta somente quando necessário; a máscara é reutilizada entre os quadros.
- **Cache de interpolação:** consultas repetidas à mesma posição de timeline reutilizam a cena calculada, sem alterar documentos editáveis.
- **Compatibilidade:** os jogos LUAFGAME 1–6 e animações `.lflash` continuam funcionando.

Nenhum script Lua enviado em pacotes externos é executado. A arquitetura de Player e Studio continua separada.

## Executar / empacotar

Instale [LÖVE 11.5](https://love2d.org/) e execute na raiz do repositório:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.10.lfgame
```

O pacote `dist/Lua-Flash-Player-0.10.love` necessita do LÖVE instalado; não é um EXE Windows nativo. Consulte os artefatos nas execuções aprovadas do [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 6](docs/FORMAT_LUAFGAME6.md).

Projeto independente, sem vínculo com a Adobe.
