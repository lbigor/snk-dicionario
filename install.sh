#!/usr/bin/env bash
set -euo pipefail
SKILL_DIR="$HOME/.claude/skills/snk-dicionario"
mkdir -p "$SKILL_DIR"
BASE="https://raw.githubusercontent.com/lbigor/snk-dicionario/main"
for f in SKILL.md BOAS_PRATICAS.md; do
  curl -fsSL "$BASE/$f" -o "$SKILL_DIR/$f"
done
echo "✓ snk-dicionario instalada em $SKILL_DIR"
echo "→ Próximo passo: exporte o DDL do seu cliente (veja INSTALACAO.md)"
