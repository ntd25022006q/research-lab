#!/usr/bin/env bash
# db_backup.sh — dump SQLite DB trong dự án vào data/db/ (app.db + dump.sql)
# Được checkpoint.sh gọi tự động. Idempotent — chạy bao nhiêu lần cũng an toàn.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/db

# 1. Tìm DB: ưu tiên đường dẫn trong .env (DATABASE_URL=file:...), fallback quét file
DB_FILE=""
if [ -f .env ]; then
  CAND="$(sed -n 's/.*file:\(.*\)/\1/p' .env | head -1 | tr -d '"'"'"' \r')"
  if [ -n "$CAND" ]; then
    # giải quyết đường dẫn tương đối
    if [ -f "$CAND" ]; then DB_FILE="$CAND"; fi
    if [ -z "$DB_FILE" ] && [ -f "prisma/${CAND#./}" ]; then DB_FILE="prisma/${CAND#./}"; fi
    if [ -z "$DB_FILE" ] && [ -f "${CAND#./}" ]; then DB_FILE="${CAND#./}"; fi
  fi
fi
if [ -z "$DB_FILE" ]; then
  DB_FILE="$(find . -maxdepth 3 \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) \
    -not -path './skills/*' -not -path './node_modules/*' -not -path './data/db/*' 2>/dev/null | head -1 || true)"
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
  # không có sqlite3 CLI: dùng Python (luôn có trong sandbox)
  python3 - "$DB_FILE" << 'EOF'
import sqlite3, sys
src = sqlite3.connect(sys.argv[1])
with open('data/db/dump.sql', 'w', encoding='utf-8') as f:
    for line in src.iterdump():
        f.write(line + '\n')
print("[db_backup] Đã dump (qua python): data/db/app.db + data/db/dump.sql")
EOF
fi
echo "[db_backup] Source of truth = repo này. Đừng sửa tay data/db/dump.sql."
