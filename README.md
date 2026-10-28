# Lua-Flash

**O Flash renasce em Lua** — uma plataforma independente de animações e jogos, com formatos próprios. Não abre SWF/FLA/ActionScript antigos.

## Projetos independentes

| Aplicação | Pasta | Executar | Estado |
|---|---|---|---|
| **[Player Lua](player-lua/)** | `player-lua/` | `love player-lua` | **0.17 experimental — foco atual** |
| **[Studio Lua](studio-lua/)** | `studio-lua/` | `love studio-lua` | 0.1 experimental, preservado |

### Player 0.17 — recuperação por projeto e diagnósticos

O Player passa a conservar **duas cópias de recuperação alternadas por jogo**, isoladas por uma identidade derivada do nome e dos bytes do arquivo original. Cada recuperação recebe um contador de versão e verificação de integridade dos dados. Uma cópia parcial ou danificada pode ser ignorada em favor da outra.

- **Ctrl+R:** abre a última recuperação válida **do jogo atualmente aberto**, desde que não haja mudanças pendentes. É necessário abrir primeiro o jogo original para identificar sua recuperação.
- **Ctrl+S:** salva o trabalho e descarta as cópias automáticas daquele jogo.
- **F3:** mostra/oculta painel com FPS aproximado, memória Lua, recursos, máscaras de alfa e pares de colisão.
- Uma tentativa de abrir outro jogo enquanto existem edições não salvas é bloqueada para evitar perda acidental.

**Atenção:** o sistema usa alternância e leitura de verificação, não gravação atômica garantida pelo sistema operacional. Não substitui backups externos. As recuperações são específicas de cada arquivo: renomear ou alterar o arquivo original muda sua identidade.

Formatos `LUAFGAME 1–9` e arquivos `.lflash` permanecem compatíveis, sem executar código Lua de terceiros. Não houve alteração no Studio.

## Executar / empacotar

Instale [LÖVE](https://love2d.org/) e, na raiz do projeto:

```bash
love player-lua
python3 tools/package_player.py
lua tools/export_example.lua dist/Exemplo-0.17.lfgame
```

O pacote `dist/Lua-Flash-Player-0.17.love` necessita do LÖVE instalado; ainda não é um EXE autônomo para Windows. Builds disponíveis nos artefatos de [GitHub Actions](https://github.com/SrTristeSad/Lua-Flash/actions).

[Manual do Player](player-lua/README.md) · [Roadmap](docs/ROADMAP.md) · [Formato LUAFGAME 9](docs/FORMAT_LUAFGAME9.md).

Projeto independente, sem vínculo com a Adobe.
