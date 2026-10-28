# Lua-Flash Player 0.23 — interface responsiva e ícone Windows

Reprodutor experimental Lua/LÖVE de jogos LUAFGAME 1–9 e animações `.lflash`. Não reproduz Adobe Flash SWF ou ActionScript.

## Layout adaptável

Quando a janela tem menos do que **1040 × 690**, o Player usa o layout completo de 1040 × 690 unidades lógicas e o reduz uniformemente até caber. Assim, a barra de reprodução, botões, timeline, painel de edição e área do jogo permanecem acessíveis. A aplicação pode exibir margens escuras nas laterais/superior para evitar esticar a imagem.

Com janelas maiores, o Player aproveita o espaço adicional mantendo escala 1:1. Os eventos de mouse/toque são transformados de volta às coordenadas da interface antes do hit-testing, e o recorte (*scissor*) é mapeado para coordenadas reais da janela.

LÖVE `highdpi=true` está habilitado na janela. Os valores de tamanho e posição são trabalhados em coordenadas lógicas da plataforma; isto dá suporte inicial a diferentes escalas de DPI sem introduzir um fator físico artificial.

**Limitação:** em 600 × 380, o conteúdo ficará menor; ainda é necessária uma interface móvel ou realmente refluida para telas muito pequenas. Há testes de layout em 600 × 380, 640 × 400, 780 × 450 e resoluções maiores, além de inicialização gráfica LÖVE em janela compacta.

## Ícone diretamente no EXE

O desenho original do raio foi criado em Lua no módulo `src/window_icon.lua`. A versão anterior incluía um `.ico` separado e mudava o ícone da janela após iniciar. Agora a compilação Windows também usa `tools/windows_resources.py` para gravar os recursos **RT_ICON** e **RT_GROUP_ICON** no executável Windows, antes de anexar o jogo `.love`.

O pipeline verifica por Win32 que o executável distribuído contém os mesmos dados PNG do `.ico`. O ícone é incorporado ao PE; **o executável ainda não possui assinatura digital nem instalador**.

O pacote portátil mantém o runtime LÖVE 11.5 de hash fixo, suas DLLs e licenças. Não é necessária a instalação separada do LÖVE no Windows.

## Recursos anteriores preservados

- **Ctrl+O**: diálogo nativo de arquivos no Windows; em outros sistemas, campo de caminho.
- **Ctrl+Shift+O**: campo manual de caminho.
- **Arrastar e soltar**: importar arquivos `.lflash` ou `.lfgame`.
- **E**: editar quadros-chave e curvas.
- **Ctrl+Z / Ctrl+Y**: desfazer/refazer.
- **Ctrl+S / Ctrl+R**: salvar ou recuperar projeto.
- **F3**: diagnósticos; **F5–F10**: áudio; **F11**: tela cheia.

O formato permanece LUAFGAME 9, e o Studio não foi alterado.

## Verificação

```bash
lua tests/responsive_test.lua
lua tests/gui_smoke.lua
python3 tests/windows_resource_test.py
python3 tests/windows_package_test.py
python3 tools/package_player.py
```

No GitHub Actions, a suíte também testa a renderização com LÖVE real em display virtual, a leitura Windows Unicode e verifica o ícone embutido no arquivo `.exe`.

O desempenho real em vários monitores Windows, DPI misto e GPUs continua pendente para a versão 1.0.
