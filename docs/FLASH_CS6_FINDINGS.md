# Flash CS6 — resultados da primeira análise de engenharia reversa

Fonte: pacote local `Flash-CS6-Engenharia-Reversa.zip` enviado para análise em 2026-10-28. Esta síntese é autoral; o pacote original de metadados não foi publicado no repositório.

## Evidências confirmadas pela análise estática recebida

- ISO de 1.478.500.352 bytes, SHA-256 `68668cf51142706e3aceb881cd85931c8aa3854e7319676887e32f8f20b870b0`.
- Editor contido na mídia: **Flash CS6 macOS Intel 32 bits**, versão **12.0.0.481**; não é uma distribuição do editor Windows.
- Inventário de 7.110 entradas, 245 binários (242 Mach-O, 3 PE), 157 arquivos FLA (68 ZIP e 89 OLE), 127 SWF, 407 recursos de menu e 98 layouts XML.
- Corpus XFL: `DOMDocument → DOMTimeline → DOMLayer → DOMFrame → elements`, incluindo `DOMShape`, `DOMSymbolInstance`, `DOMSymbolItem`, `Matrix`, `Edge` e `DOMTextAttrs`.
- `DOMFrame` apresenta atributos `index`, `duration`, `tweenType`, entre outros: spans têm representação explícita, diferente do modelo simplificado atual de quadros-chave do Studio.
- O FLA antigo (OLE) não foi decodificado internamente. Os FLA ZIP/XFL foram examinados estruturalmente; seis ZIPs apresentaram anomalia de central directory documentada pelo levantamento.

## Limites

O Codex executou **análise estática**, não observação funcional do aplicativo. Portanto, comportamento de ferramentas, algoritmos de tween, gramática de curvas `Edge`, ordenação e unidades de matrizes, fluxo de símbolos, ActionScript e publicação ainda requerem confirmação. O corpus local comparado pelo Codex foi `Lua-Flash-Player-0.21.love`, **não o checkout atual do Studio**; a análise de lacunas precisa ser validada com este repositório.

## Plano de implementação no Studio existente

1. Validar `studio-lua/src/model.lua`, `runtime.lua` e invariantes de `.lflash`. Documentar contratos e testes antes de alterar a serialização.
2. Introduzir modelo interno de spans com duração, mantendo migração e leitura do `.lflash` legado.
3. Acrescentar biblioteca de símbolos com identidades estáveis, instâncias e timelines aninhadas.
4. Criar importador XFL de subset declarado: ZIP seguro, parsing XML, índice 0→1, `DOMDocument/Timeline/Layer/Frame`, preservando o que não for interpretado sem descarte silencioso.
5. Desenvolver autorias de vetores, interpolação e transformações com testes de pares mínimos; não supor equivalência a partir dos nomes de campos.
6. Posteriormente investigar FLA OLE, SWF e ActionScript como subsistemas distintos.

## Próxima bateria de verificações

- Diferenciar frame vazio, quadro-chave vazio e prolongamento de exposição.
- Comparar seleção, movimento e exclusão de ranges entre camadas com e sem sobreposição.
- Verificar loop e relógio próprio de Graphic, MovieClip e Button.
- Inspecionar XML mínimo de símbolos, matriz afim e origem/pivô.
- Criar fixtures autorais e testes de round-trip em vez de distribuir exemplos proprietários.

Não incluir executáveis, bibliotecas, scripts, fontes, mídia ou recursos proprietários do CS6 no repositório.
