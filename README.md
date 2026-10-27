# Lua-Flash

Editor de animação 2D independente, inspirado no fluxo de trabalho de **Adobe Animate 2024 (24.0.15)** e no legado do Flash Professional.

**Objetivo:** continuar a experiência de autoria clássica (palco, linha do tempo, camadas, símbolos, desenho e exportação) com um projeto livre de dependências proprietárias da Adobe e **Lua como linguagem principal**.

## Estado

**0.1.0 — Fundação experimental.** A primeira entrega é um editor vetorial 2D básico usando [LÖVE 11.5](https://love2d.org/) (não é cópia, atualização ou distribuição do programa Adobe). O escopo é deliberadamente menor que o produto de referência.

## Executar

```bash
love .
```

Para Windows, Linux ou macOS, abra a pasta do projeto com o executável do LÖVE. Android é um objetivo da arquitetura, ainda não uma distribuição testada.

## Funcionalidades iniciais

- Interface com **palco**, ferramentas, propriedades e **linha do tempo**.
- **Pincel vetorial**, linha, retângulo, elipse, seleção/movimento e borracha.
- **Camadas** independentes, visibilidade, bloqueio e quadros-chave.
- Reprodução da linha do tempo com FPS configurado no documento.
- Desfazer/refazer básico e salvamento/abertura de arquivos **.lflash** (formato próprio em texto, *não* FLA).
- Exportar o quadro atual para SVG.
- Abrir projeto externo arrastando um .lflash para a janela.

## Atalhos

`V` seleção · `B` pincel · `L` linha · `R` retângulo · `O` elipse · `E` borracha · `F6` quadro-chave · `Shift+F6` remover quadro-chave · `Espaço` play/pausa · `Ctrl+Z` desfazer · `Ctrl+Y` refazer · `Ctrl+S` salvar · `Ctrl+O` abrir último salvo · `Ctrl+E` exportar SVG.

Os arquivos ficam na pasta de dados do LÖVE, exibida no rodapé do editor. Também há suporte a arrastar arquivos .lflash para abrir projetos externos.

## Compatibilidade e engenharia reversa

A referência de comportamento é Adobe Animate 2024 24.0.15; a compatibilidade com Flash Professional anterior é meta futura. **Não há suporte a FLA, XFL, SWF, ActionScript, AVM1 ou AVM2 nesta versão.** Não inventamos compatibilidade onde ainda não existe.

Abordagem: documentação pública dos formatos, testes de equivalência com projetos de teste autorizados, implementação independente. Não distribuímos executáveis, bibliotecas, interface gráfica integral, arquivos de instalação, marcas gráficas ou código proprietário da Adobe.

Visão e prioridades em [docs/ROADMAP.md](docs/ROADMAP.md).

## Testar

```bash
lua tests/model_test.lua
```

O teste valida o modelo e o codec sem LÖVE. A interface precisa ser verificada manualmente em uma instalação do LÖVE.

## Referências

- [Adobe Animate — release notes](https://helpx.adobe.com/animate/desktop/release-notes.html)
- [LÖVE](https://love2d.org)
- [Ruffle](https://ruffle.rs) (referência para compatibilidade SWF futura)
