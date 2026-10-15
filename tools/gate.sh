#!/usr/bin/env bash
# gate.sh — LỚP 1: CỔNG CHẶN BẮT BUỘC trước mọi commit/push
# Vi phạm = chặn cứng, KHÔNG cho phép lưu. Được gọi tự động bởi checkpoint.sh + git pre-commit hook.
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0

# ── 1. Tài liệu bắt buộc phải tồn tại (chống xóa luật) ──────────────────────
# DANH SÁCH NÀY PHẢI KHỚP: tests/test_infra.py MANDATORY + enforce.yml step 1.
for f in PROTOCOL.md CONTEXT_SNAPSHOT.md RESTORE.md worklog.md README.md \
         pyproject.toml tests/test_infra.py \
         tools/checkpoint.sh tools/db_backup.sh tools/gate.sh tools/ci_status.sh \
         tools/verify.sh tools/new_experiment.sh \
         .github/workflows/enforce.yml .github/workflows/quality.yml .github/workflows/nightly.yml; do
  [ -f "$f" ] || { echo "[gate] ❌ THIẾU file bắt buộc: $f — LUẬT KHÔNG ĐƯỢC XÓA"; FAIL=1; }
done

# ── 1b. Hiến pháp không được cắt xén: đủ mục 0..13 ──────────────────────────
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13; do
  grep -qE "^## ${i}\." PROTOCOL.md 2>/dev/null \
    || { echo "[gate] ❌ PROTOCOL.md thiếu mục ## ${i}. — CẤM cắt xén luật"; FAIL=1; }
done

# ── 1c. Worklog phải đúng mẫu (Did/Why/Findings/Next) ───────────────────────
for kw in "Did /" "Why /" "Findings /" "Next /"; do
  grep -q "$kw" worklog.md 2>/dev/null \
    || { echo "[gate] ❌ worklog.md thiếu mục '$kw' — nhật ký phải theo mẫu, cấm tóm tắt sáo rỗng"; FAIL=1; }
done

# ── 2. .env không được vào repo (chống lộ biến môi trường) ──────────────────
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo "[gate] ❌ .env đang bị track! Chạy: git rm --cached .env"; FAIL=1
fi

# ── 3. Quét secret trên toàn bộ file được track ────────────────────────────
PATTERNS=(
  'ghp_[A-Za-z0-9]{36}'
  'github_pat_[A-Za-z0-9_]{22,}'
  'AKIA[0-9A-Z]{16}'
  '\bsk-[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
)
FILES="$(git ls-files)"
[ -z "$FILES" ] && FILES="$(ls -A)"
for p in "${PATTERNS[@]}"; do
  HITS="$(printf '%s\n' "$FILES" | xargs -d '\n' grep -nIE "$p" 2>/dev/null || true)"
  if [ -n "$HITS" ]; then
    echo "[gate] ❌ PHÁT HIỆN SECRET (mẫu: $p):"
    echo "$HITS" | head -5
    FAIL=1
  fi
done

# ── 4. File >50MB không được commit trực tiếp (giới hạn GitHub) ─────────────
BIG="$(git ls-files -z | xargs -0 -I{} du -m "{}" 2>/dev/null | awk '$1 > 50 {print $2}')"
if [ -n "$BIG" ]; then
  echo "[gate] ❌ File vượt 50MB — nén hoặc bỏ vào .gitignore:"; echo "$BIG"; FAIL=1
fi

# ── 5. Worklog phải tồn tại và có entry thật ────────────────────────────────
grep -q "Task ID" worklog.md 2>/dev/null || { echo "[gate] ❌ worklog.md không có entry nào"; FAIL=1; }
# Cấm nhân bản/sửa mất lịch sử: ít nhất 4 entry có dấu thời gian
N_ENTRY=$(grep -c '^## \[' worklog.md 2>/dev/null || true)
[ "${N_ENTRY:-0}" -ge 4 ] || { echo "[gate] ❌ worklog.md chỉ còn ${N_ENTRY} entry (<4) — lịch sử nhật ký KHÔNG được xóa bớt"; FAIL=1; }

# ── Kết luận ────────────────────────────────────────────────────────────────
if [ "$FAIL" -eq 0 ]; then
  echo "[gate] ✅ PASSED — không vi phạm protocol."
else
  echo "[gate] 🚫 BLOCKED — sửa các lỗi trên trước khi lưu. Agent KHÔNG được bypass gate."
  exit 1
fi
