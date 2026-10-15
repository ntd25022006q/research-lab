#!/usr/bin/env bash
# ci_status.sh — KIỂM TRA PHÁN QUYẾT CI CHO COMMIT HIỆN TẠI (môi trường thứ 2 trên GitHub)
# usage:
#   bash tools/ci_status.sh            # xem nhanh, thoát ngay
#   bash tools/ci_status.sh --wait     # chờ tối đa 5 phút cho tới khi mọi check hoàn tất
# Exit code: 0 = mọi check xanh | 1 = có check đỏ | 2 = chưa xong/không có remote
# QUY TẮC (PROTOCOL §12): local pass ≠ done. Milestone chỉ DONE khi lệnh này exit 0.

set -uo pipefail
cd "$(dirname "$0")/.."

WAIT=0
[ "${1:-}" = "--wait" ] && WAIT=300

URL="$(git remote get-url origin 2>/dev/null || true)"
if [ -z "$URL" ]; then
  echo "[ci] ⚠️ Chưa có remote origin — không có môi trường giám định thứ 2."
  exit 2
fi
SLUG="$(printf '%s' "$URL" | sed -E 's#https://([^@]+@)?github\.com/##; s#\.git$##')"
TOKEN="$(printf '%s' "$URL" | sed -nE 's#https://([^@]+)@github\.com/.*#\1#p' | sed -E 's/^[^:]+://')"
SHA="$(git rev-parse HEAD)"
AUTH=()
[ -n "$TOKEN" ] && AUTH=(-H "Authorization: Bearer $TOKEN")

fetch() {
  curl -s "${AUTH[@]}" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$SLUG/commits/$SHA/check-runs" \
    | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("[]"); raise SystemExit
runs = d.get("check_runs", [])
print(json.dumps([[r["name"], r["status"], r["conclusion"]] for r in runs]))'
}

# Vòng chờ: đợi các check xuất hiện rồi hoàn tất
ELAPSED=0
while :; do
  RUNS_JSON="$(fetch)"
  N="$(printf '%s' "$RUNS_JSON" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
  DONE="$(printf '%s' "$RUNS_JSON" | python3 -c '
import json, sys
runs = json.load(sys.stdin)
print(sum(1 for _, st, _ in runs if st == "completed"))')"

  echo "[ci] commit ${SHA:0:7} @ $SLUG — check chạy: $N, hoàn tất: $DONE"
  if [ "$N" -gt 0 ] && [ "$DONE" -eq "$N" ]; then
    break
  fi
  if [ "$N" -eq 0 ] && [ "$ELAPSED" -ge 60 ]; then
    echo "[ci] ⚠️ Không thấy check nào sau 60s — CI có thể đang tắt/bị chặn ở cấp tài khoản."
    echo "[ci]    Kiểm tra: https://github.com/$SLUG/actions — xem banner lỗi."
    exit 2
  fi
  if [ "$ELAPSED" -ge "$WAIT" ]; then
    printf '%s\n' "$RUNS_JSON" | python3 -c '
import json, sys
for name, st, con in json.load(sys.stdin):
    print(f"  - {name}: {st} ({con})")'
    echo "[ci] ⏳ Hết thời gian chờ — chạy lại sau."
    exit 2
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

# In phán quyết
printf '%s\n' "$RUNS_JSON" | python3 -c '
import json, sys
runs = json.load(sys.stdin)
bad = 0
for name, st, con in runs:
    mark = "✅" if con == "success" else ("❌" if con not in (None, "skipped", "neutral") else "⏭️")
    if con not in ("success", "skipped", "neutral"):
        bad += 1
    print(f"  {mark} {name}: {con}")
sys.exit(1 if bad else 0)'
RC=$?

if [ "$RC" -eq 0 ]; then
  echo "[ci] ✅ MÔI TRƯỜNG THỨ 2 CHẤP NHẬN — milestone này được coi là DONE."
else
  echo "[ci] 🚫 CI ĐỎ — DỪNG MỌI VIỆC. Sửa lỗi, push lại (PROTOCOL §12: cấm làm việc mới khi CI đỏ)."
fi
exit $RC
