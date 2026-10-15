#!/usr/bin/env bash
# checkpoint.sh — commit + push toàn bộ tiến độ lên GitHub
# usage: bash tools/checkpoint.sh "<message>"
# Chạy ở MỖI milestone (xem PROTOCOL.md mục 6). Càng dày càng an toàn.

set -euo pipefail
cd "$(dirname "$0")/.."

MSG="${1:-checkpoint: update worklog and artifacts $(date '+%Y-%m-%d %H:%M')}"

# 0. Tự cài lại git hook (sống sót qua reset: lần checkpoint đầu sau restore tự kích hoạt lại)
git config core.hooksPath tools/hooks

# 0.5 LỚP 1 — GATE: chặn secret, .env, file >50MB, xóa luật. Bị chặn = phải sửa, KHÔNG được bypass.
bash "$(dirname "$0")/gate.sh"

# 1. Backup DB (nếu có) trước khi commit — DB luôn đi kèm checkpoint
bash "$(dirname "$0")/db_backup.sh" || true

git add -A

# 2. Commit nếu có thay đổi
if git diff --cached --quiet; then
  echo "[checkpoint] Không có thay đổi gì mới."
else
  git commit -m "$MSG"
  echo "[checkpoint] Đã commit: $MSG"
fi

# 3. Push nếu đã cấu hình remote
if git remote get-url origin >/dev/null 2>&1; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push -u origin "$BRANCH" && echo "[checkpoint] Đã push lên origin/$BRANCH ✅"
  echo "[checkpoint] ⚠️ BƯỚC BẮT BUỘC TIẾP THEO (PROTOCOL §12): bash tools/ci_status.sh --wait"
  echo "[checkpoint]    Local pass ≠ done — milestone chỉ DONE khi môi trường thứ 2 (CI) xanh."
else
  echo "[checkpoint] ⚠️  Chưa có remote origin — chỉ commit cục bộ (sẽ mất khi reset!)."
  echo "            Nối remote: git remote add origin https://<PAT>@github.com/<user>/<repo>.git"
fi
