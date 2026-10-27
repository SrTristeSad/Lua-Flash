# Engenharia reversa: Flash Player Projector 32.0.0.465 (Windows)

## Arquivo estudado

Arquivo recebido diretamente nesta conversa: `flashplayer_32_sa_debug.exe`.

- **SHA-256:** `9d51df0c26e9ec4717a3da2e184cde831ca139d49e4a7c2f9e26028f8c4dfa52`
- **Tamanho:** 16.811.576 bytes
- **Formato:** PE32, Windows GUI, arquitetura x86 (32 bits)
- **Data do cabeçalho PE:** 2020-11-24 22:19:59 UTC (não é garantia da data de compilação)
- **Versão de arquivo e produto:** 32.0.0.465, obtida do recurso VERSIONINFO
- **CompanyName:** Adobe
- **FileDescription:** Adobe Flash Player 32.0 r0
- **OriginalFilename:** SAFlashPlayer.exe

A análise foi **exclusivamente estática**: o executável não foi iniciado, instrumentado nem instalado.

## Estrutura identificada

| Seção | Tamanho físico no arquivo | Função típica no formato PE |
|---|---:|---|
| `.text` | 10.728.960 bytes | Código de máquina |
| `.rodata` | 4.608 bytes | Dados constantes |
| `.rdata` | 2.646.016 bytes | Dados somente-leitura, imports/exports |
| `.data` | 864.256 bytes | Dados inicializados |
| `.gfids` | 512 bytes | Metadados de mitigação |
| `.rsrc` | 2.114.048 bytes | Recursos Windows, inclusive menus/diálogos |
| `.reloc` | 444.416 bytes | Relocações |

Bibliotecas na **tabela estática** de importação: `KERNEL32.dll` e `ADVAPI32.dll`. Esse resultado **não permite concluir** que o programa use apenas essas bibliotecas; outras podem ser carregadas dinamicamente.

O executável contém diversos recursos visuais, menus, diálogos, strings e manifestos Windows. Os exports incluem `_WinMainSandboxed@20` e nomes `IAEModule_*`. São observações técnicas, sem atribuição de finalidade interna não comprovada.

## Certificado incorporado

Existe uma estrutura Authenticode de 7.736 bytes no diretório de segurança PE. O certificado de assinatura de código nela embutido indica:

- **Subject:** Adobe Inc. / Flash Player
- **Issuer:** DigiCert EV Code Signing CA (SHA2)
- **Algoritmos declarados:** SHA-256 e RSA PKCS#1 v1.5

**Limite:** a presença e a leitura do certificado não são equivalentes à validação criptográfica da assinatura e da cadeia de confiança. A autenticidade completa não foi atestada por este relatório.

## O que vamos reproduzir no Lua-Flash

Esta pesquisa **não** muda a direção do produto: Lua-Flash é uma plataforma **nova**, sem compatibilidade com conteúdo legado Adobe. O executável original serve para pesquisar soluções de projeto.

1. **Ciclo de execução do Player:** abertura da aplicação, loop de eventos, agendamento de quadros, pausa e saída.
2. **Experiência de janela e depuração:** menus, atalhos, painel de erros e respostas a falhas.
3. **Separação entre lógica e host:** janela, entrada, áudio e renderização abstraídos por backends; Lua controla cenas e comportamento do conteúdo novo.
4. **Isolamento e permissões:** o futuro runtime deve controlar APIs, arquivos e rede quando executar conteúdos de terceiros.
5. **Studio separado do Player:** a criação visual (palco, camadas, timeline, símbolos, biblioteca) pertence ao Lua-Flash Studio e não deve ser confundida com recursos presentes no executável do Flash Player.

## Próximas verificações

- Mapear os recursos PE (menus, caixas de diálogo e atalhos) sem copiá-los diretamente para a UI própria.
- Estudar dinamicamente o comportamento em **máquina virtual isolada**, sem acesso à rede e com snapshots.
- Construir testes com **conteúdos novos criados por nós**, na plataforma Lua-Flash.
- Evoluir um formato de publicação próprio e APIs Lua, sem parser SWF, ActionScript ou conversão FLA.

## Segurança e propriedade intelectual

Não publicar o executável Adobe no repositório; apenas informações derivadas da observação técnica. Não reutilizar código compilado, ícones, marcas gráficas ou outros recursos proprietários. Comparar comportamentos observáveis para desenvolver implementação independente.

**Estado:** inspeção estrutural concluída; assinatura ainda não validada criptograficamente; testes dinâmicos não realizados.
