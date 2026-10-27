# LUAFGAME 3 — especificação experimental

O formato `.lfgame` versão 3 é um **envelope de dados**, não código Lua. Contém uma cena `.lflash` do Lua-Flash, com as regras de execução previamente definidas.

## Registros

O arquivo começa com `LUAFGAME 3`, seguido por linhas separadas por tabulação:

```text
TITLE\tNome%20do%20jogo
DURATION\t40
GOAL\t8
SMOOTH\t1
OBJECT\tbola
OBJECT\tbarreira
BIND\tbola\t2\t1\t1
BIND\tbola\t2\t23\t1
BIND\tbarreira\t3\t1\t1
STATE\tchoques\t0
RULE\tCOLLIDE\tbola\tbarreira\tADD\tchoques\t1\t-\t-\t-\t-
SCENE_BYTES\tNNNN
... exatamente NNNN bytes de uma cena .lflash ...
ENDGAME
```

No arquivo real, as sequências `\t` acima são caracteres de tabulação e `NNNN` representa a quantidade exata de bytes da cena. Há um `\n` entre a cena e o registro final `ENDGAME\n`. Os campos de título usam percent-encoding de caracteres especiais.

- `OBJECT id`: objeto nomeado, com identificador ASCII até 32 bytes.
- `BIND id layer frame shape`: associa o objeto à forma de índice `shape` na camada `layer` **no quadro-chave** `frame`. O mesmo ID pode ter vínculos diferentes em vários quadros-chave.
- `STATE id initial`: contador de jogo inteiro, inicialmente de 0 a 1.000.000.
- `RULE event target other action argument1 argument2 condition condition-id operator value`: permite gatilhos `CLICKID`, `KEY` ou `COLLIDE` e ações validadas `SCORE`, `SEEK`, `PLAY`, `PAUSE`, `ADD` e `SET`. Campos não usados são `-`.
- `WHEN`: condição opcional com `EQ`, `GE` ou `LE`.

## Funcionamento das colisões

O motor obtém as formas visíveis na posição atual da timeline, localiza os IDs pelo `BIND` associado ao último quadro-chave e verifica pares que possuem regra `COLLIDE`. O evento dispara **apenas ao iniciar o contato**; o par precisa se separar antes de poder disparar novamente.

Para formas vetoriais simples, há testes específicos de retângulo e elipse. Para linha ou pincel, o contato é aproximado por caixa delimitadora, portanto pode produzir falsos positivos.

## Limites e evolução

Máximo de 25 MB por jogo, 256 objetos, 4.096 vínculos, 128 regras e 64 estados. Nenhum código Lua de terceiros é executado. Os formatos LUAFGAME 1 e 2 permanecem válidos e são lidos pelos decodificadores anteriores.

**Atenção:** os IDs persistem nos dados do pacote de jogo, não no formato editável `.lflash`. A inserção e reordenação de formas **dentro de um mesmo quadro-chave** ainda exige atualizar o vínculo BIND na republicação. O objetivo futuro é integrar IDs persistentes ao formato editável e ao Studio.
