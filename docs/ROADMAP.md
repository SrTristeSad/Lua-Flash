# Lua-Flash — Player + Studio

## Objetivo
O Lua-Flash será uma continuação **independente** do ecossistema Flash clássico, com **duas funções no mesmo projeto**:

1. **Lua-Flash Player:** abrir e executar arquivos SWF originais (jogos, animações e aplicações), com fidelidade crescente.
2. **Lua-Flash Studio:** criar e editar animações e jogos no fluxo clássico: palco, camadas, timeline, símbolos, biblioteca, propriedades, scripts e exportações.

Queremos que quem já sabe usar Flash encontre um ambiente familiar, sem precisar reaprender conceitos ou refazer manualmente seus arquivos.

## Arquitetura
- **Lua**: núcleo de documentos, ferramentas, interface e orquestração.
- **LÖVE**: janela, desenho e entrada nas primeiras versões para desktop.
- **SWF**: leitor e visualizador inicial em Lua, evoluindo por testes com arquivos reais.
- **ActionScript 1/2/3**: futuro motor compatível. Avaliar o Ruffle (Rust; MIT/Apache-2.0) como backend opcional para não reimplementar à toa o que a comunidade já construiu. Uma possível integração nativa exige desenvolvimento e validação específicos por plataforma; **não existe integração hoje**.
- **Formatos editáveis**: inicialmente .lflash; importação/exportação FLA, XFL e SWF serão implementadas de forma incremental. Um SWF compilado **não** contém obrigatoriamente todos os dados do projeto FLA original.

## Marcos

### 0.1 — Base (parcial)
- [x] Modelo de documentos e quadros-chave em Lua.
- [x] Leitor experimental SWF FWS/CWS com quadros e formas básicas (no protótipo independente anterior).
- [ ] Interface unificada Player/Studio no repositório.
- [ ] Salvar e abrir projetos .lflash na UI.
- [ ] Testes de integração do aplicativo.

### 0.2 — Player clássico
- [ ] Imagens, gradientes, sprites, áudio e texto.
- [ ] Reprodução determinística por quadros, eventos e sincronização.
- [ ] Melhorar a compatibilidade com ActionScript por um backend confiável.
- [ ] Matriz de testes com jogos SWF antigos.

### 0.3 — Editor clássico
- [ ] Desenho vetorial completo, símbolos e biblioteca de recursos.
- [ ] Timeline com interpolação, múltiplas cenas e ferramentas de edição.
- [ ] Importador XFL; importador FLA quando viável.
- [ ] Publicação SWF validada e exportação para formatos modernos.

### 1.0
- [ ] Player e Studio conectados por um pipeline de exportação/teste.
- [ ] Estabilidade, projetos recuperáveis e empacotamento Windows/Linux/macOS.
- [ ] Android e Web por backends validados (não presumir suporte automático).

## Limites e proteção de compatibilidade
- Flash Player (execução de SWF) e Flash Professional/Animate (autoria) eram produtos distintos.
- Compatibilidade SWF não implica código-fonte FLA editável.
- Não distribuir código, instaladores, recursos ou marcas proprietários da Adobe.
- Nunca anunciar que um SWF com ActionScript funciona antes de passar em testes.
- Preservar funcionalidades existentes: novos recursos não devem quebrar o Player ou o Studio.
