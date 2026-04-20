# snk-dicionario

> Skill Claude Code que impede invenção de campos/tabelas inexistentes em projetos Sankhya.

**Problema:** dev cola nome de campo errado, descobre no deploy.
**Solução:** Claude valida contra o dicionário oficial + DDL do cliente antes de escrever 1 linha.
**Você faz:** `"Claude, gera a query/classe pra essa tabela"` — ele verifica antes.

## Instalação em 1 comando

```bash
curl -fsSL https://raw.githubusercontent.com/lbigor/snk-dicionario/main/install.sh | bash
```

Depois, exporte o DDL do seu cliente (ver [INSTALACAO.md](INSTALACAO.md)).

## Como funciona

1. Antes de gerar SQL ou Java/JAPE, Claude consulta a skill.
2. A skill verifica cada tabela/campo referenciado contra 5 fontes:
   - `sankhya_core.md` — dicionário oficial (1.645 tabelas nativas)
   - `sankhya_core.sql` — DDL completo das nativas
   - `<CLIENTE>-DDL.csv` — tabelas + campos do cliente (inclui `AD_*`)
   - `<CLIENTE>-DDL-Campos.csv` — opções de campos
   - `<CLIENTE>-DDL-Relacionamentos.csv` — PKs e FKs
3. Se não encontrar: recusa gerar e sugere o nome mais próximo.
4. Se for campo de valor (QTDNEG, ESTOQUE, VLRUNIT…): sinaliza que precisa `ISNULL`/`NVL`.

## Documentação

- [INSTALACAO.md](INSTALACAO.md) — passo-a-passo (cabe no iPad)
- [SKILL.md](SKILL.md) — orquestrador técnico (o que o Claude lê)
- [BOAS_PRATICAS.md](BOAS_PRATICAS.md) — o que a skill faz e não faz
- [CONTRIBUTING.md](CONTRIBUTING.md) — como contribuir

## Licença

MIT. Contribuições via PR — apenas @lbigor aprova merge.
