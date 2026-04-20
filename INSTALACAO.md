# Instalação — snk-dicionario

Cinco passos. Cada um é uma frase.

## 1. Pré-requisito: Claude Code instalado

Se ainda não tem, rode: `curl -fsSL https://claude.ai/install.sh | bash` (ou siga [claude.ai/code](https://claude.ai/code)).

## 2. Instale a skill

```bash
curl -fsSL https://raw.githubusercontent.com/lbigor/snk-dicionario/main/install.sh | bash
```

Isso copia `SKILL.md` e `BOAS_PRATICAS.md` para `~/.claude/skills/snk-dicionario/`.

## 3. Exporte o DDL do seu cliente

Peça ao DBA rodar `scripts/exportar-ddl-cliente.sql` no banco Sankhya (SQL Server ou Oracle) e salvar os 3 CSVs em `~/Documents/GitHub/Sankhya/`:

- `<SEU_CLIENTE>-DDL.csv` — tabelas + campos (inclui `AD_*`)
- `<SEU_CLIENTE>-DDL-Campos.csv` — opções de campos
- `<SEU_CLIENTE>-DDL-Relacionamentos.csv` — PKs + FKs

Exemplo: `CPAPS-DDL.csv`, `CPAPS-DDL-Campos.csv`, `CPAPS-DDL-Relacionamentos.csv`.

## 4. Garanta o dicionário nativo

Confirme que existe `~/Documents/Claude/sankhya_core.md` e `~/Documents/Claude/sankhya_core.sql`. Sem eles, a skill só valida campos `AD_*`.

## 5. Teste

Abra o Claude Code e peça: `gera a query que soma QTDNEG por CODPARC em TGFCAB`. A skill deve validar `TGFCAB.QTDNEG` como inexistente (é em `TGFITE`) e sugerir o nome correto, incluindo a regra `ISNULL(QTDNEG, 0)`.
