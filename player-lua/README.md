# Lua-Flash Player 0.19 — áudio polifônico e canais

O Player é escrito em Lua com LÖVE e abre animações `.lflash` e jogos declarativos `.lfgame` (LUAFGAME 1–9). Não executa SWF/ActionScript nem código Lua importado de jogos.

## Áudio polifônico

Antes desta versão, cada arquivo WAV tinha uma única fonte sonora, reiniciada ao receber um novo evento. Isso cortava efeitos que ainda estavam tocando.

Agora o módulo `src/audio_mixer.lua` gerencia um conjunto pequeno de fontes por arquivo WAV. Quando um efeito é disparado e a fonte anterior ainda está tocando, ele pode iniciar outra fonte e manter a primeira. Os efeitos de cliques/teclado/colisões/vitória e os sons programados na linha do tempo passam por dois canais de volume distintos.

O orçamento é de **16 vozes totais** e **4 por arquivo WAV**. Ao atingir o limite, o mixer interrompe e reutiliza a voz mais antiga, priorizando estabilidade e uso previsível de memória. É possível que um efeito curto seja cortado se o jogo disparar sons além da capacidade configurada.

A trilha `timeline` mantém a semântica de tocar quando a reprodução atravessa um quadro. Agora também reconhece voltas completas consecutivas e dispara cada passagem pelos respectivos quadros em ordem cronológica. Como proteção contra loops extremos, são permitidos **no máximo 64 disparos da timeline por atualização**.

O volume final de cada voz corresponde a `volumeGeral × volumeDoCanal`. O mudo interrompe vozes ativas e impede novos disparos enquanto está ativado.

### Controles de áudio

| Tecla | Função |
|---|---|
| **F5** | Alternar entre o canal `effects` e `timeline`. |
| **F6 / F7** | Diminuir/aumentar em 10% o volume do canal selecionado. |
| **F8 / F9** | Diminuir/aumentar em 10% o volume geral. |
| **F10** | Silenciar ou reativar todo o áudio. |
| **F3** | Mostrar vozes totais/ativas, reutilizações e volumes dos canais, além dos diagnósticos existentes. |

Os demais controles de editor e timeline continuam: **E** abre o editor de chaves; **Ctrl+S** salva; **Ctrl+Z/Ctrl+Y** desfazem/refazem; **Ctrl+R** restaura cópias verificadas.

## Implementação e compatibilidade

As amostras PCM são decodificadas uma vez e fontes `love.audio.Source` são criadas sob demanda. Os recursos PNG continuam usando a otimização existente de máscaras alfa e cena interpolada. Na ausência de `Source:isPlaying` (como em simulações e versões simplificadas de áudio), o mixer reutiliza a fonte sem criar vozes extras.

**O formato LUAFGAME 9 não mudou.** Jogos LUAFGAME 1–9 e arquivos `.lflash` mantêm a leitura anterior. Nenhum arquivo externo executa Lua arbitrário. O aplicativo Studio não foi modificado.

## Testar

```bash
lua tests/audio_mixer_test.lua
lua tests/package_v6_test.lua
lua tests/package_v4_test.lua
lua tests/gui_smoke.lua
python3 tools/sync_core.py --check
python3 tools/package_player.py
```

A CI verifica sobreposição, volumes dos canais, limites de vozes e múltiplos loops e também executa o LÖVE real em display virtual, com áudio fictício (*dummy audio*) para validar a criação de fontes.

**Limitações:** ainda não existem streaming de áudio para faixas longas, panorâmica estéreo individual, música de fundo separada em outro formato, fades automáticos ou mixer profissional com efeitos DSP. São necessários testes manuais em Windows e medições de latência de áudio com placas reais antes da versão 1.0.

O Player ainda é distribuído em `.love` e requer LÖVE instalado.
