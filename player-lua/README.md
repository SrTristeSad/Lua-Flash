# Lua-Flash Player 0.15 — editor visual de quadros-chave

Player experimental em Lua com LÖVE 11.5. Abre `.lflash` e jogos declarativos `.lfgame` (LUAFGAME 1–9), sem executar SWF nem código externo de jogos.

## Editar animações pela interface

1. Abra um jogo que tenha uma trilha de sprite LUAFGAME 8/9, usando o botão **PACOTE** ou arrastando o `.lfgame` para a janela.
2. Pressione **E** para abrir o **EDITOR DE KEYFRAMES**. A animação será pausada.
3. Clique numa chave da lista para selecioná-la e posicionar o cursor da timeline naquele quadro.
4. Use os botões abaixo para alterar os dados, ou arraste o sprite destacado diretamente no palco para modificar seu deslocamento X/Y.
5. Clique em **SALVAR** ou use **Ctrl+S** para gravar `player_game.lfgame` na pasta de dados do LÖVE.

### Botões e atalhos

| Controle | Efeito |
|---|---|
| **+CHAVE** / **Insert** | Insere um quadro-chave na posição atual da timeline; se já houver uma chave, tenta o ponto intermediário até a próxima chave. |
| **-CHAVE** / **Delete** | Remove a chave selecionada. O quadro inicial não pode ser excluído. |
| **Q -** / **Q +** | Move a chave um quadro para trás/frente, sem cruzar as vizinhas. |
| **X - / X + / Y - / Y +** | Ajusta em 5 unidades o deslocamento da chave selecionada. |
| **Arrastar sprite no palco** | Modifica a posição X/Y da chave usando o mouse. |
| **CURVA** / **C** | Alterna os seis modos de easing da 0.14 no trecho selecionado. |
| **Setas ↑/↓** | Navega entre chaves, inclusive a última. |
| **PageUp/PageDown** | Troca de sprite/trilha. |
| **E** / **Escape** | Abre/fecha o editor. |
| **Ctrl+S** | Salva uma cópia do jogo modificado. |

O **quadro 1 é protegido contra exclusão ou mudança de tempo**, mas sua posição pode ser alterada. Cada trilha precisa conservar pelo menos duas chaves. A inserção amostra a pose interpolada para não criar uma mudança brusca de posição inesperada; o easing correspondente também é preservado quando um intervalo é dividido. Ao excluir uma chave, referências de easing que deixam de corresponder a um trecho são removidas.

O painel é um editor inicial de poses: nesta versão, o mouse altera **posição X/Y**; ângulos e escalas animados continuam editáveis na definição do jogo ou por `tools/animate_transform.lua`. O editor não possui desfazer/refazer, seleção múltipla ou curvas Bézier desenháveis. Essas funcionalidades ficam para versões posteriores.

## Integridade e compatibilidade

A implementação das operações está em `player-lua/src/keyframe_editor.lua`, separada da interface. Ela rejeita índices, posições, quadros e valores inválidos antes de modificar o arquivo em memória.

O formato segue LUAFGAME 9 e mantém compatibilidade com os jogos 1–8 sem conversão obrigatória. Uma edição visual não altera arquivos originais: **Ctrl+S cria uma cópia na pasta de salvamento do Player**.

O Studio `studio-lua/` permanece inalterado.

## Testes

```bash
lua tests/keyframe_editor_test.lua
lua tests/gui_smoke.lua
lua tests/package_v9_test.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

O GitHub Actions também inicializa o Player no LÖVE real em display virtual, executa os testes anteriores e gera o arquivo `.love`.

O desempenho e a usabilidade precisam de validação em PCs reais. Ainda não há EXE Windows autônomo nem recuperação avançada de edições.
