#!/bin/bash
# Headless-проверка ядра: запускает собранный бинарь с --self-test.
# Он включает caffeinate, проверяет power-assertions через pmset, выключает и
# проверяет, что они снялись.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/release/Coffein"
[ -f "$BIN" ] || BIN="$ROOT/.build/debug/Coffein"
[ -f "$BIN" ] || { echo "Сначала соберите проект: swift build"; exit 1; }

exec "$BIN" --self-test
