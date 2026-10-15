#!/usr/bin/env bash
# new_experiment.sh — PRE-REGISTER thí nghiệm TRƯỚC KHI CHẠY (PROTOCOL §3 + §13)
# usage: bash tools/new_experiment.sh <NNN> "<tên ngắn slug>" [seed]
#   vd:   bash tools/new_experiment.sh 001 "baseline-cnn-cifar10" 42
# Vì sao pre-register: chốt Hypothesis + Success criteria TRƯỚC khi thấy kết quả
# để không thể tự lừa mình (p-hacking, chọn lọc kết quả đẹp sau diễn).
set -euo pipefail
cd "$(dirname "$0")/.."

NNN="${1:-}"
TITLE="${2:-}"
SEED="${3:-42}"

[[ "$NNN" =~ ^[0-9]{3}$ ]] || { echo "❌ Số EXP phải là 3 chữ số. vd: bash tools/new_experiment.sh 001 \"baseline-cnn\" 42"; exit 2; }
[ -n "$TITLE" ] || { echo "❌ Thiếu tên thí nghiệm."; exit 2; }

SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
FILE="research/experiments/EXP-${NNN}-${SLUG}.md"

if [ -e "$FILE" ]; then
  echo "❌ ĐÃ TỒN TẠI: $FILE — pre-register KHÔNG được ghi đè (hợp lệ thì tăng số NNN mới)."
  exit 1
fi

mkdir -p research/experiments research/experiments/envs research/experiments/results research/experiments/assets

DATE="$(date '+%Y-%m-%d %H:%M')"
PYV="$(python3 --version 2>&1 || echo 'python: ?')"

cat > "$FILE" <<EOF
# EXP-${NNN} — ${TITLE}

- **Registered / Đăng ký:** ${DATE}
- **Default seed / Seed mặc định:** ${SEED}
- **Status / Trạng thái:** PRE-REGISTERED — chưa chạy.
  ⚠️ KHÔNG được sửa \`Hypothesis\`/\`Success criteria\` sau khi đã thấy kết quả.
  Muốn đổi hướng → viết EXP mới tham chiếu EXP này.

## Question
(Câu hỏi nghiên cứu — cụ thể, 1-2 câu.)

## Hypothesis
(Giả thuyết KIỂM CHỨNG ĐƯỢC: có số có dataset, vd: "model X đạt accuracy > Y% trên Z với seed ${SEED}".)

## Method
(Thuật toán/cách làm. Biến độc lập/phụ thuộc. Siêu tham số. Seed. Cách đo metric.
Bắt buộc ghi baseline so sánh — xem PROTOCOL §13.)

## Success criteria
(Tiêu chí ĐỊNH LƯỢNG chốt trước khi chạy: đạt nếu ..., thất bại nếu ...
Ghi rõ số liệu baseline để đối chiếu.)

## Results
(Điền SAU khi chạy. Metrics thô vào research/experiments/results/, artifacts vào research/experiments/assets/.
Kết quả âm vẫn phải ghi — thất bại cũng là dữ liệu khoa học.)

## Conclusion
(Điền sau — kết luận phải khớp Results, không khớp mong muốn.)
EOF

ENVF="research/experiments/envs/EXP-${NNN}.env"
{
  echo "# EXP-${NNN} environment freeze @ ${DATE}"
  echo "# ${PYV}"
  echo "SEED=${SEED}"
  pip freeze 2>/dev/null || true
} > "$ENVF"

echo "✅ Pre-registered: $FILE"
echo "✅ Env freeze:     $ENVF"
echo "→ Giờ mới được chạy thí nghiệm (scripts/ phải qua lint+test)."
echo "→ Sau khi chạy: điền Results + Conclusion vào chính file này rồi checkpoint."
