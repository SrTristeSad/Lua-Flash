# Engenharia reversa do editor Flash clássico — plano de compatibilidade

## Objetivo

Reconstruir no **Lua-Flash Studio** o comportamento e o fluxo de trabalho do editor Flash clássico, a partir de observações verificáveis, documentação de formatos e testes comparativos. Manter o Player Lua como projeto separado. Não reutilizar código, recursos proprietários ou marcas da Adobe.

**Estado:** preparação. Nenhum binário do *editor* original foi analisado neste plano; o executável Flash Player de depuração não substitui o editor de autoria.

## Metodologia (caixa-preta primeiro)

1. Identificar edição e versão exata do editor de referência e arquivar capturas das telas e menus usados nos testes.
2. Criar uma suíte de projetos mínimos no editor original: palco vazio, formas, camadas, símbolos, instâncias, quadros comuns, quadros-chave, motion/shape tween, som, imagens, texto e eventos.
3. Para cada operação, registrar **entrada → ação → saída** (tela, timeline, propriedades, arquivo salvo e exportação).
4. Inspecionar *metadados e estrutura* dos arquivos produzidos e documentar limites e incertezas. SWF, FLA e XFL exigem tratamento próprio: suporte não deve ser declarado antes de um leitor/escritor compatível.
5. Reproduzir os comportamentos em módulos isolados do Studio; manter o formato interno `.lflash` e criar importação/exportação por adaptadores.
6. Validar ida e volta em projetos de teste e comparar resultado visual, temporal e editável.
7. Testar Windows, compatibilidade de projetos e performance antes de uma versão 1.0.

## Inventário inicial — o que já existe no Studio Lua

| Subsistema | Estado atual | Lacuna de compatibilidade |
|---|---|---|
| Palco e desenho vetorial | Pincel, linha, retângulo, elipse, seleção, borracha | Ferramentas de transformação, preenchimento, curvas e precisão do editor de referência |
| Timeline | Quadros-chave, camadas, rolagem, zoom, seleção e arraste | Semântica de exposição de quadros, interpolação de autoria, múltiplas trilhas e propriedades |
| Documento | `.lflash` próprio | Importação FLA/XFL, exportação SWF e equivalência de semântica ainda não disponíveis |
| Biblioteca | Não implementada como painel de símbolos | Símbolos, instâncias, biblioteca, reutilização e vínculo de recursos |
| Texto | Não implementado como ferramenta de autoria | Fontes, caixas de texto, edição, métricas |
| Áudio | Player tem suporte; Studio básico | Importação, sincronização e edição de áudio |
| Scripts | Sem ActionScript/FLA | Definir tradutor ou runtime isolado e escopo de compatibilidade verificável |
| Publicação | Player separado | Pipeline editor → pacote → Player/arquivos de exportação |

## Ordem de implementação

- **Fase 0 — referência:** versão exata do aplicativo original, screenshots e projetos comparativos; matriz de evidências.
- **Fase 1 — arquitetura:** modelo de documento, operações editáveis, biblioteca e propriedades.
- **Fase 2 — timeline:** quadros normais vs quadros-chave, interpolação e edição multicamada.
- **Fase 3 — ferramentas:** vetores, texto, máscaras, símbolos e transformações.
- **Fase 4 — formatos:** leitores/escritores progressivos de FLA/XFL/SWF, conforme evidências e testes.
- **Fase 5 — integração:** edição, execução no Player, publicação, regressão visual e homologação.

## Regras de execução

- Nunca marcar compatibilidade 1:1 sem casos de teste verificáveis.
- Evitar suposições sobre comportamento com base só em screenshots.
- Implementar componentes novos de maneira modular e documentar diferenças.
- Preservar compatibilidade do Player e do formato `.lflash` existente.
- Executar análise de binários somente sobre cópias legítimas fornecidas/permitidas; não contornar licenças, ativação ou proteções.
