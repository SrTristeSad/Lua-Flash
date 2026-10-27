# Lua-Flash

**O Flash renasce em Lua** — plataforma independente para animações e jogos criados em formatos próprios. Não executa SWF, FLA, XFL nem ActionScript antigos da Adobe.

## Aplicações separadas

| Aplicação | Diretório | Executar | Versão |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.11 experimental** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

## Player 0.11 — colisão de movimento rápido

O Player verifica posições **intermediárias** da animação durante reprodução automática. Isso permite detectar alguns contatos rápidos que antes eram perdidos ao examinar somente o quadro final.

- Verificação com até **80 subamostras temporais por atualização** (além dos pontos de passagem por loop).
- Eventos `COLLIDE` no momento de entrada em contato, inclusive após separação e novo encontro.
- Respeito a máscaras alfa PNG e formas vetoriais.
- O contador de loops agora reconhece voltas completas que terminam na mesma posição ou em posição maior que a inicial.
- Saltos manuais da timeline não simulam percurso físico.
- Efeitos WAV agendados na timeline também reconhecem loops completos.
- Pares de colisão são pré-organizados por sessão para evitar procurar todas as regras repetidamente.

A versão mantém **LUAFGAME 1–6** e `.lflash`, sem mudança de formato nem execução de scripts Lua externos. O Studio continua intocado.

## Executar

Instale [LÖVE 11.5](https://love2d.org/) e, na raiz do projeto:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.11.lfgame
```

O pacote `dist/Lua-Flash-Player-0.11.love` requer LÖVE instalado (não é um EXE independente). Builds e jogos de teste ficam disponíveis em [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 6](docs/FORMAT_LUAFGAME6.md).

Projeto não afiliado à Adobe.
