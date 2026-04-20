#!/usr/bin/env bash
# test.sh — validações locais do repo snk-dicionario
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok()    { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail()  { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "[1/5] Arquivos markdown obrigatórios"
for f in README.md SKILL.md INSTALACAO.md BOAS_PRATICAS.md CONTRIBUTING.md LICENSE; do
  if [[ -f "$f" ]]; then ok "$f existe"; else fail "$f ausente"; fi
done

echo ""
echo "[2/5] Frontmatter de SKILL.md"
if head -n 1 SKILL.md | grep -q '^---$'; then
  ok "abre com ---"
else
  fail "SKILL.md não começa com frontmatter ---"
fi
if awk '/^---$/{c++} c==2{exit} END{exit c<2}' SKILL.md; then
  ok "fecha frontmatter"
else
  fail "frontmatter não fecha"
fi
for key in name description; do
  if awk '/^---$/{c++; next} c==1' SKILL.md | grep -q "^${key}:"; then
    ok "frontmatter tem ${key}:"
  else
    fail "frontmatter sem ${key}:"
  fi
done

echo ""
echo "[3/5] Sintaxe do install.sh"
if bash -n install.sh; then
  ok "install.sh tem sintaxe válida"
else
  fail "install.sh com erro de sintaxe"
fi

echo ""
echo "[4/5] Script SQL presente"
if [[ -f scripts/exportar-ddl-cliente.sql ]]; then
  ok "scripts/exportar-ddl-cliente.sql existe"
  if grep -q "TDDTAB" scripts/exportar-ddl-cliente.sql \
     && grep -q "TDDCAM" scripts/exportar-ddl-cliente.sql \
     && grep -q "TDDOPC" scripts/exportar-ddl-cliente.sql; then
    ok "SQL referencia TDDTAB/TDDCAM/TDDOPC"
  else
    fail "SQL não referencia as 3 tabelas de metadata esperadas"
  fi
else
  fail "scripts/exportar-ddl-cliente.sql ausente"
fi

echo ""
echo "[5/5] Link check interno (relativo)"
# extrai [texto](arquivo.md) e [texto](pasta/arquivo) sem http
python3 - <<'PY' || true
import re, os, sys
bad = 0
for md in ["README.md","INSTALACAO.md","BOAS_PRATICAS.md","CONTRIBUTING.md","SKILL.md"]:
    if not os.path.exists(md):
        continue
    txt = open(md).read()
    for m in re.finditer(r'\[[^\]]+\]\(([^)]+)\)', txt):
        link = m.group(1)
        if link.startswith(('http://','https://','#','mailto:')):
            continue
        # remove âncora
        path = link.split('#',1)[0]
        if not path:
            continue
        if not os.path.exists(path):
            print(f"  ✗ {md}: link quebrado → {link}")
            bad += 1
if bad == 0:
    print("  ✓ todos os links relativos apontam para arquivos existentes")
else:
    sys.exit(1)
PY
if [[ $? -eq 0 ]]; then
  ok "link check OK"
else
  fail "links internos quebrados"
fi

echo ""
echo "========================================="
echo "Resultado: $PASS passaram, $FAIL falharam"
echo "========================================="
if [[ $FAIL -gt 0 ]]; then exit 1; fi
