-- ============================================================
-- exportar-ddl-cliente.sql
-- Exporta o DDL de um cliente Sankhya em 3 CSVs, para uso com
-- a skill snk-dicionario.
--
-- Produz:
--   <CLIENTE>-DDL.csv                    (tabelas + campos, inclui AD_*)
--   <CLIENTE>-DDL-Campos.csv             (opções de campos)
--   <CLIENTE>-DDL-Relacionamentos.csv    (PKs e FKs)
--
-- Compatível com Oracle (default do Sankhya clássico). Se o cliente
-- roda SQL Server, veja o bloco comentado no final.
--
-- Ajuste o schema/owner conforme seu ambiente. Não invente tabelas:
-- se sua instalação usa nomes diferentes para metadata do Sankhya
-- (TDDCAM, TDDTAB, TDDOPC), mantenha os originais — eles são padrão.
-- ============================================================


-- ------------------------------------------------------------
-- 1) <CLIENTE>-DDL.csv
-- Colunas esperadas:
--   TABELA_ADICIONAL, NOME_TABELA, NOME_DAO, MODULO,
--   NUCAMPO, NOME_CAMPO, DESCRICAO_CAMPO,
--   TIPO_CAMPO, TAMANHO, PRECISAO, DECIMAIS, NULLABLE, DATA_DEFAULT
-- ------------------------------------------------------------

SELECT
    TAB.TABELAADICIONAL           AS TABELA_ADICIONAL,   -- 'S' para AD_*, 'N' para nativa
    TAB.NOMETAB                   AS NOME_TABELA,
    TAB.NOMEDAO                   AS NOME_DAO,
    TAB.MODULO                    AS MODULO,
    CAM.NUCAMPO                   AS NUCAMPO,
    CAM.NOMECAMPO                 AS NOME_CAMPO,
    CAM.DESCRCAMPO                AS DESCRICAO_CAMPO,
    CAM.TIPCAMPO                  AS TIPO_CAMPO,          -- NUMBER, VARCHAR, DATE, BLOB...
    CAM.TAMANHO                   AS TAMANHO,
    CAM.PRECISAO                  AS PRECISAO,
    CAM.DECIMAIS                  AS DECIMAIS,
    CAM.NULLABLE                  AS NULLABLE,            -- 'S' ou 'N'
    CAM.DATADEFAULT               AS DATA_DEFAULT
FROM TDDTAB TAB
INNER JOIN TDDCAM CAM ON CAM.IDTAB = TAB.IDTAB
ORDER BY TAB.NOMETAB, CAM.NUCAMPO;


-- ------------------------------------------------------------
-- 2) <CLIENTE>-DDL-Campos.csv
-- Colunas esperadas:
--   NUCAMPO, OPCAO, VALOR
-- ------------------------------------------------------------

SELECT
    OPC.NUCAMPO   AS NUCAMPO,
    OPC.DESCROPC  AS OPCAO,       -- ex.: "Sim"
    OPC.VALOR     AS VALOR        -- ex.: "S"
FROM TDDOPC OPC
ORDER BY OPC.NUCAMPO, OPC.VALOR;


-- ------------------------------------------------------------
-- 3) <CLIENTE>-DDL-Relacionamentos.csv
-- Colunas esperadas:
--   TABELA, CAMPO, CONSTRAINT_NOME, TIPO, TABELA_REFERENCIADA, CAMPO_REFERENCIADO
--
-- TIPO = 'P' (primary key) ou 'R' (foreign key / referencial)
-- Para PK, TABELA_REFERENCIADA e CAMPO_REFERENCIADO ficam vazios.
-- ------------------------------------------------------------

-- Oracle:
SELECT
    UC.TABLE_NAME         AS TABELA,
    UCC.COLUMN_NAME       AS CAMPO,
    UC.CONSTRAINT_NAME    AS CONSTRAINT_NOME,
    UC.CONSTRAINT_TYPE    AS TIPO,           -- 'P' ou 'R'
    REF.TABLE_NAME        AS TABELA_REFERENCIADA,
    REF_COL.COLUMN_NAME   AS CAMPO_REFERENCIADO
FROM   USER_CONSTRAINTS UC
INNER JOIN USER_CONS_COLUMNS UCC
        ON UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
LEFT JOIN USER_CONSTRAINTS REF
        ON REF.CONSTRAINT_NAME = UC.R_CONSTRAINT_NAME
LEFT JOIN USER_CONS_COLUMNS REF_COL
        ON REF_COL.CONSTRAINT_NAME = REF.CONSTRAINT_NAME
       AND REF_COL.POSITION        = UCC.POSITION
WHERE  UC.CONSTRAINT_TYPE IN ('P','R')
ORDER BY UC.TABLE_NAME, UC.CONSTRAINT_NAME, UCC.POSITION;


-- ============================================================
-- Fallback SQL Server (descomente se o cliente roda em MSSQL)
-- ============================================================
-- ajuste conforme seu schema — nomes INFORMATION_SCHEMA são padrão
-- ANSI, mas a classificação PK/FK usa sys.key_constraints /
-- sys.foreign_keys. A query abaixo cobre o necessário para o CSV 3:

-- SELECT
--     tp.name                    AS TABELA,
--     cp.name                    AS CAMPO,
--     kc.name                    AS CONSTRAINT_NOME,
--     CASE kc.type
--         WHEN 'PK' THEN 'P'
--         WHEN 'F'  THEN 'R'
--     END                        AS TIPO,
--     tr.name                    AS TABELA_REFERENCIADA,
--     cr.name                    AS CAMPO_REFERENCIADO
-- FROM sys.key_constraints kc
-- INNER JOIN sys.tables tp             ON tp.object_id = kc.parent_object_id
-- INNER JOIN sys.index_columns ic      ON ic.object_id = kc.parent_object_id
--                                     AND ic.index_id  = kc.unique_index_id
-- INNER JOIN sys.columns cp            ON cp.object_id = ic.object_id
--                                     AND cp.column_id = ic.column_id
-- LEFT  JOIN sys.foreign_key_columns fkc
--                                     ON fkc.constraint_object_id = kc.object_id
-- LEFT  JOIN sys.tables tr             ON tr.object_id = fkc.referenced_object_id
-- LEFT  JOIN sys.columns cr            ON cr.object_id = fkc.referenced_object_id
--                                     AND cr.column_id = fkc.referenced_column_id
-- ORDER BY tp.name, kc.name;

-- Para TDDTAB/TDDCAM/TDDOPC em SQL Server, a sintaxe é idêntica ao
-- Oracle acima — essas tabelas são do Sankhya, não do catálogo do SGBD.
