# Lua-Flash Studio 0.1

Editor visual experimental do ecossistema Lua-Flash. O editor existente foi preservado nesta pasta.

## Executar

Instale LÖVE 11.5 e execute na raiz do repositorio:

```bash
love studio-lua
```

Recursos atuais: palco, pincel, linhas, retangulos, elipses, borracha, selecao, camadas, quadros-chave, salvar e abrir .lflash. O botao de previa do editor nao substitui o programa Player, que agora vive em `../player-lua/`.

Para testar no Player: salve usando Ctrl+S e depois clique **PROJETO SALVO** no Player; ambos usam a mesma identidade de armazenamento do LÖVE (`lua-flash`). Tambem e possivel arrastar um arquivo .lflash diretamente para o Player.

O sistema ainda nao executa scripts Lua de projetos, e esta versao nao foi validada em todos os sistemas.
