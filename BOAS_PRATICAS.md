# Boas práticas — snk-dicionario

## O que a skill FAZ

| ✓ | Ação |
|---|---|
| ✓ | Valida tabela nativa contra `sankhya_core.md` e `sankhya_core.sql` |
| ✓ | Valida campo nativo contra `sankhya_core.md` |
| ✓ | Valida tabela `AD_*` (custom) contra `<CLIENTE>-DDL.csv` |
| ✓ | Valida campo `AD_*` em tabela nativa ou custom |
| ✓ | Resolve `NOME_DAO` correto a partir do CSV do cliente |
| ✓ | Sugere o nome mais próximo (Levenshtein) quando não encontra |
| ✓ | Sinaliza campos de valor (QTDNEG, ESTOQUE, VLRUNIT…) com regra `ISNULL`/`NVL` |
| ✓ | Lê opções de campo em `<CLIENTE>-DDL-Campos.csv` (ex.: `TIPMOV` = `P` Pedido / `V` Venda) |
| ✓ | Lê FKs em `<CLIENTE>-DDL-Relacionamentos.csv` |
| ✓ | Recusa gerar código se qualquer referência não existe |

## O que a skill NÃO FAZ

| ✗ | Limite |
|---|---|
| ✗ | Não valida views nem stored procedures (só tabelas) |
| ✗ | Não inventa campo que não está no DDL — pede para você exportar |
| ✗ | Não altera o DDL do cliente — só lê |
| ✗ | Não executa query — só valida nomes |
| ✗ | Não valida semântica de negócio (ex.: pode ser campo certo mas regra errada) |
| ✗ | Não valida permissão de usuário Sankhya |
| ✗ | Não substitui o `sankhya_api.md` para classes Java (skill é só de campos/tabelas) |

## Regra global — campos de valor

Todo campo monetário ou de quantidade (`QTDNEG`, `QTDPED`, `QTDCAN`, `ESTOQUE`, `RESERVADO`, `WMSBLOQUEADO`, `VLRUNIT`, `VLRTOT`, `VLRDESC`, `VLRIPI`, `VLRICMS`, `VLRBASEICMS`, saldos, agregações…) deve vir envolto em:

- **SQL Server** (Sankhya padrão): `ISNULL(campo, 0)`
- **Oracle**: `NVL(campo, 0)`

Aplicar no **primeiro rascunho**, em `WHERE`, `SELECT`, `JOIN`, `SUM`, `CASE`, qualquer contexto. Escrever `SUM(ISNULL(campo, 0))` em vez de `ISNULL(SUM(campo), 0)` quando houver risco de linhas individuais virem NULL.

**Por quê?** NULL em campo de valor quebra filtros silenciosamente (`ESTOQUE - RESERVADO > 0` retorna NULL se qualquer parcela for NULL e a linha é descartada), agregações (`SUM` sobre coluna toda NULL vira NULL) e comparações (`valor > 0` é falso para NULL). Incidente recorrente: item com estoque real sumia do empenho automático por `RESERVADO` NULL em `TGFEST`.

## Quando desconfiar do resultado

- CSV do cliente com mais de 3 meses → exportar de novo antes de implementar feature grande.
- Campo `AD_*` criado hoje não aparece → exportar CSV.
- Validação passou mas código quebrou no deploy → provavelmente tipo de dado (ex.: passar `String` onde é `BigDecimal`); a skill valida existência, não conversão.
