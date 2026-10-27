# Lua-Flash — a plataforma Flash renascida em Lua

## Missão

Ressuscitar a **ideia do Flash Player** como plataforma moderna para criar, distribuir e executar experiências interativas (jogos, animações e aplicações), acompanhada de um ambiente de criação visual familiar.

**Não queremos compatibilidade com os projetos antigos da Adobe.** Não é emulador, descompilador ou conversor de Flash legado. Não há objetivo de importar, rodar ou exportar SWF, FLA, XFL, nem executar ActionScript/AVM1/AVM2.

## Dois produtos, um núcleo

- **Lua-Flash Player**: runtime Lua para executar publicações feitas no Lua-Flash, incluindo animação, áudio, eventos, interação e scripts.
- **Lua-Flash Studio**: editor de palco, camadas, linha do tempo, quadros-chave, vetores, símbolos, biblioteca de recursos e código Lua.

Os dois usam **o mesmo modelo de cena, quadros e renderização**, para evitar diferenças entre o que é visto no editor e o que o jogador vê.

## Fundamentos técnicos

1. **Lua** governa cenas, lógica, animação, eventos e APIs.
2. **LÖVE** é backend de renderização/entrada desktop na fase inicial; pode ser trocado por backends futuros.
3. **.lflash** é projeto próprio editável (atualmente formato textual experimental). Uma futura publicação empacotada terá formato próprio, com separação entre projeto e distribuição.
4. Projetos só poderão executar scripts arbitrários **no Player e mediante modelo de permissões e isolamento definido**, especialmente para conteúdo baixado da internet. Não usar carregamento irrestrito de Lua de terceiros como funcionalidade pública.
5. Priorizar desempenho, arquivos pequenos, estabilidade e experiência de trabalho familiar aos artistas que usavam Flash.

## Etapas

### 0.1 — Base jogável/editor mínimo
- [x] Modelo de documento, camadas e quadros-chave em Lua.
- [x] Formato próprio .lflash para cenas simples.
- [ ] Runtime gráfico rodando no LÖVE, compartilhado por Studio/Player.
- [ ] Editor mínimo: ferramentas vetoriais, timeline, seleção e prévia.
- [ ] Testes locais de codec e quadro/forma.

### 0.2 — Autoria
- [ ] Símbolos, instâncias, componentes e biblioteca.
- [ ] Interpolação, áudio sincronizado, sprites e hierarquia de cena.
- [ ] Undo/redo confiável, autosave e backups.

### 0.3 — Execução de aplicações
- [ ] Eventos, controles, cenas e scripting Lua documentado.
- [ ] Execução de publicações isoladas e modelo de permissões.
- [ ] Empacotador nativo com manifesto e assets.

### 1.0 — Publicação multiplataforma
- [ ] Windows/Linux/macOS.
- [ ] Android (integração e testes próprios).
- [ ] Web (backend dedicado, não presumir que LÖVE funciona direto).

## Princípios

- **Não recriar os formatos legados**.
- **Não copiar código ou binários proprietários da Adobe**.
- **Recuperar o espírito criativo e a ergonomia**, não fingir que o Adobe Flash Player está licenciado ou atualizado.
- Interface familiar, ferramentas modernas e compatibilidade entre as versões **do próprio Lua-Flash**.
