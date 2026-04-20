---
name: snk-dicionario
description: Valida tabelas e campos Sankhya contra o dicionário oficial + DDL do cliente ANTES de gerar SQL ou código JAPE/Java. Dispara sempre que Claude for escrever query SQL, DAO, FinderWrapper, DynamicVO, FluidCreateVO, FluidUpdateVO, trigger, procedure, evento programável ou qualquer código que referencie tabela/campo do ERP Sankhya. Recusa gerar se o nome não existir e sugere o mais próximo. Sinaliza campos de valor que exigem ISNULL/NVL.
---

# snk-dicionario — skill de validação Sankhya

## Quando acionar

Acionar ANTES de gerar qualquer artefato que referencie nome de tabela ou campo Sankhya:

- Query SQL (SELECT, UPDATE, INSERT, DELETE, MERGE)
- DAO com JAPE (`JapeFactory.dao("NOME_DAO")`, `FinderWrapper`, `DynamicVO`)
- FluidCreateVO / FluidUpdateVO
- Trigger, procedure, view
- Evento programável Sankhya (`EventoProgramavelJava`)
- Ação de rotina Java (`AcaoRotinaJava`)
- Integrações que mapeiam coluna → campo

Se o usuário colar SQL pronto pedindo revisão, também validar.

## Fontes consultadas (ordem de prioridade)

1. `~/Documents/Claude/sankhya_core.md` — dicionário oficial Sankhya (1.645 tabelas nativas, campos, PKs, FKs, opções)
2. `~/Documents/Claude/sankhya_core.sql` — DDL completo das tabelas nativas
3. `~/Documents/GitHub/Sankhya/<CLIENTE>-DDL.csv` — tabelas + campos do cliente (inclui `AD_*`)
4. `~/Documents/GitHub/Sankhya/<CLIENTE>-DDL-Campos.csv` — opções dos campos do cliente
5. `~/Documents/GitHub/Sankhya/<CLIENTE>-DDL-Relacionamentos.csv` — PKs e FKs do cliente

Se o cliente não estiver definido na sessão, perguntar `Qual cliente? (CPAPS, FABMED, etc.)` e usar o prefixo correspondente.

## Fluxo de validação (etapas numeradas)

1. **Extrair referências** — parsear o texto que Claude vai gerar e extrair toda tabela (`FROM`, `JOIN`, `UPDATE`, `INSERT INTO`) e todo campo (`SELECT`, `WHERE`, `SET`, `VALUES`, referência `tabela.campo`).
2. **Classificar origem** — para cada tabela:
   - Prefixo `AD_` → custom do cliente → consultar (3) (4) (5).
   - Sem prefixo → nativa → consultar (1) (2). Se não achar, tentar (3) (4) (5) (pode ser view custom).
3. **Verificar existência** — tabela presente? Campo presente naquela tabela?
4. **Se não existir:**
   - Calcular distância Levenshtein para os 5 nomes mais próximos dentro do escopo correto (nativa vs AD_).
   - Responder com bloco `NÃO VALIDADO` (formato abaixo). **Não gerar o código.**
   - Se o cliente não exportou DDL recente, sugerir rodar `scripts/exportar-ddl-cliente.sql`.
5. **Se existir:**
   - Ler tipo (`TIPO_CAMPO`: NUMBER/VARCHAR/DATE/BLOB), tamanho, precisão, decimais, nullable, FK.
   - Responder com bloco `VALIDADO` incluindo metadados.
   - Se o campo for de valor monetário ou quantitativo (lista abaixo), anexar aviso `REGRA ISNULL/NVL`.

## Campos de valor — regra obrigatória ISNULL/NVL

Lista não-exaustiva de campos que, quando referenciados em `WHERE`, `SELECT`, `JOIN`, `SUM`, `CASE`, `HAVING`, exigem `ISNULL(campo, 0)` (SQL Server) ou `NVL(campo, 0)` (Oracle):

- Quantidades: `QTDNEG`, `QTDPED`, `QTDCAN`, `QTDENT`, `QTDATENDIDA`, `QTDLIB`
- Estoque: `ESTOQUE`, `RESERVADO`, `WMSBLOQUEADO`, `DISPONIVEL`
- Valores: `VLRUNIT`, `VLRTOT`, `VLRDESC`, `VLRIPI`, `VLRICMS`, `VLRBASEICMS`, `VLRFRETE`, `VLRSEGURO`, `VLROUTROS`
- Saldos financeiros: `VLRDESDOB`, `VLRBAIXA`, `VLRLIQUIDO`, `VLRCORRIGIDO`, `VLRJUROS`, `VLRMULTA`

**Padrão correto em agregação:** `SUM(ISNULL(campo, 0))` e NÃO `ISNULL(SUM(campo), 0)` — a primeira forma trata NULL em cada linha antes de agregar.

**Motivo:** NULL quebra filtros silenciosamente (`ESTOQUE - RESERVADO > 0` vira NULL se uma parcela for NULL e a linha some), agregações (`SUM` em coluna toda NULL vira NULL) e comparações (`valor > 0` é falso para NULL).

Quando detectar um desses campos, incluir no bloco `VALIDADO` a linha `REGRA ISNULL/NVL obrigatória` e já sugerir a query com o wrapping.

## Formato de resposta — NÃO VALIDADO

```
NÃO VALIDADO — não vou gerar o código.

Motivo: <TABELA>.<CAMPO> não existe.
Escopo consultado: [nativa | AD_ do cliente <CLIENTE>]

Sugestões (Levenshtein):
  1. <nome_proximo_1>  (distância N)
  2. <nome_proximo_2>  (distância N)
  3. <nome_proximo_3>  (distância N)

Próximos passos:
- Se era um destes: me passa o nome correto e eu gero.
- Se é campo novo: o DDL do cliente pode estar desatualizado.
  Rode scripts/exportar-ddl-cliente.sql e atualize
  ~/Documents/GitHub/Sankhya/<CLIENTE>-DDL.csv.
```

## Formato de resposta — VALIDADO

```
VALIDADO

<TABELA>.<CAMPO>
  tipo:     NUMBER(10,0) | VARCHAR(40) | DATE | ...
  nullable: N | S
  FK:       <TABELA_REF>.<CAMPO_REF>   (se houver)
  origem:   nativa (sankhya_core.md) | custom (<CLIENTE>-DDL.csv)

[REGRA ISNULL/NVL obrigatória — campo de valor]
```

Repetir o bloco para cada tabela/campo validado. Depois dos blocos, gerar o código.

## Regras de comportamento

- Nunca gerar código se qualquer referência falhar a validação.
- Nunca "assumir" que um campo existe porque parece plausível (ex.: `TGFPAR.EMAIL_COMERCIAL` não existe em core — é `TGFPAR.EMAIL`).
- Respeitar `NOME_DAO` do CSV quando for usar `JapeFactory.dao()` — não é sempre igual a `NOME_TABELA`.
- Se a tabela é nativa e o campo é `AD_*`, validar contra o CSV do cliente (campos custom em tabela nativa).
- Quando migrar query entre SQL Server ↔ Oracle, trocar `ISNULL` ↔ `NVL` preservando a semântica.

## Fora do escopo

- Não valida views ou stored procedures (só tabelas).
- Não inventa campos faltantes — sempre pede export atualizado.
- Não altera o DDL do cliente — só lê.
