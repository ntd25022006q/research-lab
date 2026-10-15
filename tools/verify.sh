#!/usr/bin/env bash
# verify.sh — BẢN PHẢN CHIẾU CI CHẠY TẠI CHỖ (PROTOCOL §12: CI không bao giờ được thấy lỗi lần đầu)
# Chạy TRƯỚC mỗi push (pre-push hook tự gọi). Cùng một bộ kiểm tra với quality.yml + enforce.yml:
#   gate → ruff → shellcheck → actionlint → pytest → bandit
# Chính sách: tool CHẠY và thấy lỗi = chặn. Tool KHÔNG CÀI được = cảnh báo lớn (CI trên GitHub sẽ chấm bù).
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0
WARN=0
step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$1"; }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
ok()   { echo "  ✅ $1"; }

# ── 1. Gate (LỚP 1 — cứng) ───────────────────────────────────────────────────
step "1/6 gate.sh (cấu trúc + secret + size + luật)"
if bash tools/gate.sh; then ok "gate pass"; else bad "gate BLOCKED"; fi

# ── 2. Ruff (Python lint) ────────────────────────────────────────────────────
step "2/6 ruff check ."
if command -v ruff >/dev/null 2>&1 || python3 -m ruff --version >/dev/null 2>&1; then
  ruff check . && ok "ruff sạch" || bad "ruff phát hiện lỗi"
else
  python3 -m pip install -q ruff 2>/dev/null \
    && { ruff check . && ok "ruff sạch" || bad "ruff phát hiện lỗi"; } \
    || warn "không cài được ruff tại chỗ — CI sẽ chấm thay"
fi

# ── 3. Shellcheck (bash lint) ────────────────────────────────────────────────
step "3/6 shellcheck tools/*.sh + hooks"
if ! command -v shellcheck >/dev/null 2>&1; then
  (sudo apt-get install -y shellcheck >/dev/null 2>&1 || apt-get install -y shellcheck >/dev/null 2>&1) || true
fi
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error tools/*.sh tools/hooks/pre-commit tools/hooks/pre-push 2>/dev/null; then
    ok "shellcheck sạch"
  else
    bad "shellcheck phát hiện lỗi"
  fi
else
  warn "shellcheck không có tại chỗ — CI sẽ chấm thay"
fi

# ── 4. Actionlint (workflow YAML) ────────────────────────────────────────────
step "4/6 actionlint .github/workflows/*.yml"
AL=/tmp/actionlint-lab/actionlint
if [ ! -x "$AL" ]; then
  mkdir -p /tmp/actionlint-lab
  curl -sSfL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash \
    | bash -s -- -b /tmp/actionlint-lab latest >/dev/null 2>&1 || true
fi
if [ -x "$AL" ]; then
  if "$AL" -shellcheck= -color; then ok "workflows hợp lệ"; else bad "actionlint phát hiện lỗi"; fi
else
  warn "không tải được actionlint — CI sẽ chấm thay"
fi

# ── 5. Pytest (self-tests) ───────────────────────────────────────────────────
step "5/6 pytest (self-tests)"
if python3 -m pytest --version >/dev/null 2>&1; then
  python3 -m pytest -q && ok "tests pass" || bad "pytest đỏ"
else
  python3 -m pip install -q pytest pyyaml 2>/dev/null \
    && { python3 -m pytest -q && ok "tests pass" || bad "pytest đỏ"; } \
    || warn "không cài được pytest tại chỗ — CI sẽ chấm thay"
fi

# ── 6. Bandit (security) — y hệt quality.yml ────────────────────────────────
step "6/6 bandit -q -ll (security)"
if ! python3 -m bandit --version >/dev/null 2>&1; then
  python3 -m pip install -q bandit 2>/dev/null || true
fi
if python3 -m bandit --version >/dev/null 2>&1; then
  if find . -name '*.py' -not -path './skills/*' -not -path './node_modules/*' -print0 \
    | xargs -0 -r python3 -m bandit -q -ll; then
    ok "bandit sạch"
  else
    bad "bandit phát hiện vấn đề mức MEDIUM+"
  fi
else
  warn "không cài được bandit tại chỗ — CI sẽ chấm thay"
fi

# ── Kết luận ─────────────────────────────────────────────────────────────────
printf '\n'
if [ "$FAIL" -eq 0 ]; then
  echo "✅ VERIFY: ALL GREEN (cảnh báo: $WARN) — được phép push. Sau push: bash tools/ci_status.sh --wait"
else
  echo "🚫 VERIFY: $FAIL LỖI — SỬA TRƯỚC KHI PUSH (PROTOCOL §12). Tắt máy kiểm tra = chống đối protocol."
  exit 1
fi
