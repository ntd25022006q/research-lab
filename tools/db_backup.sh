#!/usr/bin/env bash
# db_backup.sh — dump SQLite DB trong dự án vào data/db/ (app.db + dump.sql)
# Được checkpoint.sh gọi tự động (SAU gate). Idempotent — chạy bao nhiêu lần cũng an toàn.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/db

# 1. Tìm DB: ưu tiên đường dẫn DATABASE_URL=file:... trong .env, fallback quét file *.db
DB_FILE=""
if [ -f .env ]; then
  CAND="$(python3 << 'PYEOF'
import re
try:
    env = open(".env").read()
except OSError:
    print(""); raise SystemExit
m = re.search(r"file:[\"']?([^\"'\s]+)", env)
print(m.group(1) if m else "")
PYEOF
)"
  if [ -n "$CAND" ]; then
    for p in "$CAND" "./$CAND" "prisma/$CAND" "prisma/${CAND#./}"; do
      if [ -f "$p" ]; then DB_FILE="$p"; break; fi
    done
  fi
fi
if [ -z "$DB_FILE" ]; then
  DB_FILE="$(find . -maxdepth 3 \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) \
    -not -path './skills/*' -not -path './node_modules/*' -not -path './data/db/*' -print 2>/dev/null | head -1 || true)"
fi

if [ -z "$DB_FILE" ] || [ ! -f "$DB_FILE" ]; then
  echo "[db_backup] Không tìm thấy SQLite DB nào — bỏ qua (bình thường nếu dự án chưa có DB)."
  exit 0
fi

# 2. Copy DB gốc + dump SQL (ghi đè — lịch sử phiên bản do git đảm nhiệm)
cp "$DB_FILE" data/db/app.db
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 data/db/app.db .dump > data/db/dump.sql
  echo "[db_backup] Đã dump: $DB_FILE -> data/db/app.db ($(du -h data/db/app.db | cut -f1)) + data/db/dump.sql"
else
  # không có sqlite3 CLI: dùng Python (luôn có trong sandbox và trên runner GitHub)
  python3 - "$DB_FILE" << 'PYEOF'
import sqlite3
import sys

src = sqlite3.connect(sys.argv[1])
with open("data/db/dump.sql", "w", encoding="utf-8") as f:
    for line in src.iterdump():
        f.write(line + "\n")
print("[db_backup] Đã dump (qua python): data/db/app.db + data/db/dump.sql")
PYEOF
fi
echo "[db_backup] Source of truth = repo này. Đừng sửa tay data/db/dump.sql."
