# WORKLOG — NHẬT KÝ PHÒNG LAB / LAB NOTEBOOK

> Append-only. MỖI milestone = 1 entry mới bên dưới, KHÔNG sửa entry cũ.
> Entry mới luôn đặt ở ĐÍNH file (mới nhất trên cùng). Mẫu bắt buộc:

```markdown
---
## [YYYY-MM-DD HH:MM] Task ID: <id> — <tên việc>
- **Did / Đã làm:** (cụ thể, có đường dẫn)
- **Why / Tại sao:** (lý do, lập luận — không được bỏ qua)
- **Findings / Phát hiện:** (kèm bằng chứng: file, số liệu, output)
- **Next / Tiếp theo:** (bước kế tiếp rõ ràng)
```

---

## [2026-10-16 04:20 +07] Task ID: 6 — Nâng cấp arsenal: verify.sh phản chiếu CI + pre-push hook + nightly audit + pre-register tool + PROTOCOL §13

- **Did / Đã làm:**
  - `tools/verify.sh` — bản phản chiếu CI chạy tại chỗ: gate → ruff → shellcheck → actionlint → pytest → bandit. Chính sách: tool chạy thấy lỗi = CHẶN; tool không cài được tại sandbox = cảnh báo lớn (CI trên GitHub chấm bù).
  - `tools/hooks/pre-push` — gate (cứng, không skip) + verify trước mỗi push; lỗ thoát hiểm duy nhất `CHECKPOINT_SOFT_SKIP="<lý do>"` phải ghi worklog, và CI vẫn chấm lại độc lập.
  - `tools/new_experiment.sh` — pre-register EXP-NNN: sinh file đủ Question/Hypothesis/Method/Success criteria + freeze môi trường (pip freeze + seed) vào `research/experiments/envs/`, TỪ CHỐI ghi đè file đã có (bản chất của pre-register).
  - `.github/workflows/nightly.yml` — ca đêm 08:30 (+07) hằng ngày: gitleaks quét secret trên TOÀN BỘ lịch sử git + test dump DB còn import được (backup hỏng = checkpoint vô nghĩa) + cảnh báo worklog im lặng >14 ngày.
  - Siết `gate.sh` + `enforce.yml`: danh sách file bắt buộc nâng lên 16 file (đồng bộ 3 nơi: gate / enforce / test MANDATORY); chống cắt xén PROTOCOL (phải đủ mục ## 0. → ## 13.); chống worklog sáo rỗng (bắt buộc Did/Why/Findings/Next + ≥4 entry, cấm xóa lịch sử).
  - PROTOCOL thêm **§13 SCIENTIFIC HONESTY — NOVELTY & BASELINES**: mọi tuyên bố "đột phá/mới" bắt buộc có baseline định lượng + nguồn tra cứu + phạm vi hiệu lực; kết quả đẹp bất thường phải nghi trước (leakage/seed) và chạy lại seed khác; §12 bổ sung quy tắc verify-trước-push.
  - `tests/test_infra.py` lên 15 test: thêm test nightly (cron + gitleaks + backup integrity), test new_experiment (scaffold + chống ghi đè), đồng bộ MANDATORY + sections 0..13; README thêm badge 3 workflow.
- **Why / Tại sao:**
  - User yêu cầu vũ khí hóa tối đa: "cái gì cũng quét qua GitHub, không chống đối, code chuẩn chuyên gia, thuật toán đột phá, NCKH thành công". Thiếu sót lớn nhất trước đó: agent có thể push code bẩn rồi mới thấy CI đỏ (CI biết trước agent) — `verify.sh` + pre-push đảo chiều đó: CI không bao giờ được thấy lỗi lần đầu.
  - §13 giải quyết rủi ro lớn nhất của NCKH bằng AI: tự lừa mình bằng kết quả không có baseline/nguồn — đột phá chỉ đếm được khi đối chứng được.
- **Findings / Phát hiện:**
  - `verify.sh` bắt 2 lỗi thật ngay lần chạy đầu (trước cả push): (1) dòng test vượt 110 ký tự ruff E501; (2) bẫy YAML 1.1 — pyyaml parse key `on:` thành boolean `True` nên `data["on"]` KeyError, phải `data.get("on", data.get(True, {}))`. Ghi vào đây để người sau không tái phạm.
  - shellcheck + actionlint không cài được trong sandbox (không sudo) — verify.sh xử lý đúng thiết kế: warn + chờ CI chấm.
- **Next / Tiếp theo:**
  1. `ci_status --wait` xác nhận xanh cho commit này (theo §12, milestone chỉ DONE khi CI xanh).
  2. Chốt chủ đề NCKH với user → `bash tools/new_experiment.sh 001 "<slug>" <seed>` → EXP-001.
  3. Sáng mai kiểm tra run `nightly` đầu tiên (gitleaks + backup integrity).

## [2026-10-16 20:45] Task ID: 2 — Nối GitHub + lắp 3 lớp khóa cứng (enforcement)

- **Did / Đã làm:**
  - Xác minh PAT user cung cấp (login `ntd25022006q`, token CLASSIC quyền admin toàn phần — đã cảnh báo user nên thay bằng fine-grained sau setup).
  - Tạo repo private `ntd25022006q/research-lab` qua API, nối remote, push lần đầu thành công (nhánh `main`).
  - **Lớp 1 (trong repo):** viết `tools/gate.sh` — chặn secret (ghp_/github_pat_/AKIA/sk-/private key), `.env` bị track, file >50MB, xóa tài liệu bắt buộc, worklog rỗng; tạo `tools/hooks/pre-commit`; `checkpoint.sh` giờ tự set `core.hooksPath` + chạy gate trước mọi push (tự tái cài sau reset).
  - **Lớp 2 (GitHub):** tạo `.github/workflows/enforce.yml` — CI chạy trên mọi push: kiểm tra tài liệu bắt buộc tồn tại (chống xóa luật), quét secret, cấm file >50MB.
  - **Lớp 3 (GitHub):** sẽ bật bảo vệ nhánh main (cấm force-push/xóa) qua API sau push này.
  - Thêm Điều 11 ENFORCEMENT vào PROTOCOL.md ghi rõ cơ chế 3 lớp + sự thật kỹ thuật (khóa trong sandbox không thể vĩnh viễn — lớp cứng phải nằm trên GitHub, lớp trong repo tự tái cài).
- **Why / Tại sao:**
  - User yêu cầu "khóa cứng vào hệ thống, dù reset không bị xóa, chặn khi không làm đúng" — điều đó technically bất khả bên trong sandbox (mọi thứ trong sandbox chết theo reset), nên thiết kế đúng là đặt lớp cứng trên server GitHub (CI + branch protection — không bypass được từ sandbox), còn lớp trong repo tự tái cài đặt qua startup sequence.
  - Pattern quét secret được viết dạng regex có yêu cầu hậu tố ≥22-36 ký tự để không tự khớp chính file quét (tránh false-positive làm CI đỏ oan).
- **Findings / Phát hiện:**
  - Push bootstrap `29fe386` lên GitHub OK; token classic hoạt động cho toàn bộ: tạo repo, push, (tiếp: protection + CI).
  - Gate phải chạy SAU `git add -A` (quét index) và cả trước commit — thiết kế hiện tại: checkpoint gọi gate trực tiếp + pre-commit hook dự phòng.
- **Next / Tiếp theo:**
  1. Push enforcement commit → xác minh CI `enforce` xanh.
  2. Bật branch protection (no force-push, no delete) qua API.
  3. User chốt chủ đề NCKH → mở EXP-001.

## [2026-10-16 22:05] Task ID: 5 — Chu trình CI-first lần 1: đỏ bandit → chẩn đoán → sửa → xanh

- **Did / Đã làm:**
  - Push `5283bb1` → chạy `ci_status --wait` → **4 job thực thi trên public** (xác nhận giả thuyết: limit chỉ áp dụng private): pytest ✅ enforce ✅ lint ✅ bandit ❌.
  - Truy vết: log runner → `exit code 123` (mã đặc trưng của xargs: lệnh con thoát 1-125). Tái hiện cục bộ chính xác lệnh CI → `bandit: error: argument -v/--verbose: not allowed with argument -q/--quiet`. Không phải finding bảo mật thật — là 2 cờ xung đột do tôi lắp.
  - Sửa quality.yml (bỏ `-v`, thêm comment cảnh báo người sau), tái hiện lại cục bộ: exit 0 → push sửa.
- **Why / Tại sao:**
  - Đây là lần đầu PROTOCOL §12 chạy trọn vòng đời thật: local pass → push → CI đỏ → DỪNG → chẩn đoán bằng log → tái hiện cục bộ → sửa → push lại. Không được phép bỏ qua hay né check.
- **Findings / Phát hiện:**
  - Exit code 123 của xargs là manh mối chẩn đoán quý: nghĩa là "lệnh con thoát 1-125" — luôn phải soi lệnh con thay vì đổ lỗi cho dữ liệu.
  - CI public xác nhận hoạt động: 4/4 job thực thi thật (khác hẳn private: 0 bước, 2s, 0 log).
- **Next / Tiếp theo:**
  1. `ci_status --wait` xác nhận 4/4 xanh → milestone DONE theo §12.
  2. Chốt chủ đề NCKH → EXP-001.

## [2026-10-16 21:30] Task ID: 4 — Môi trường kép: bộ kiểm thử chuyên gia + CI 4 job + chuyển public

- **Did / Đã làm:**
  - **Chuyển repo sang PUBLIC** (API PATCH) + **bật branch protection THÀNH CÔNG** (cấm force-push/xóa — giờ free trên public) → Layer 3 chính thức cứng.
  - **Bộ kiểm thử tự phản chiếu** `tests/test_infra.py` (14 test): chứng minh gate chặn secret/file lớn/thiếu file, checkpoint không bị bypass, db_backup dump đúng schema+data, worklog/PROTOCOL không bị cắt xén, workflow YAML hợp lệ, script bash chuẩn cú pháp.
  - **Workflow `quality.yml`** 3 job mới song song: lint (ruff + shellcheck + actionlint), self-tests (pytest), security (bandit -ll) — bổ sung cho enforce.yml → mỗi push được chấm bởi 4 job độc lập trên runner sạch.
  - **`tools/ci_status.sh`**: agent BẮT BUỘC kiểm tra phán quyết CI sau mỗi push (--wait tối đa 5 phút); exit code 0/1/2 rõ ràng.
  - **PROTOCOL thêm Điều 12 (DUAL-ENVIRONMENT & CI-FIRST)**: local pass ≠ done; CI đỏ = dừng mọi việc; cấm --no-verify/force-push/tắt workflow; làm ẩu = vi phạm protocol.
  - Viết lại phần parse `.env` trong db_backup.sh (heredoc python thay thế chuỗi tr/inti lồng — sạch cho shellcheck); xóa `minimal-test.yml` (canary đã hoàn thành nhiệm vụ, được quality suite thay thế).
  - Tự phát hiện + sửa 2 lỗi logic trong test TRƯỚC khi push: db_backup không thuộc nhánh gọi gate (bỏ khỏi test bypass), file >50MB tạo bằng seek là sparse file khiến du không đếm (sửa thành ghi zeros thật).
- **Why / Tại sao:**
  - User yêu cầu "môi trường thứ 2 song song + kiểm thử cực kỹ + code chuẩn chuyên gia" — kiến trúc đúng là: sandbox = bàn làm việc (có thể gian lận/có thể chết), GitHub = phòng giám định độc lập (không thể can thiệp). CI là lần rà soát thứ 2 không thể mua chuộc.
  - Chính hệ thống kiểm tra phải được kiểm tra trước: nếu gate hỏng mà không ai biết thì cả 3 lớp là trang trí.
- **Findings / Phát hiện:**
  - Branch protection chỉ khả dụng cho public repo ở free tier — chuyển public giải quyết đồng thời: CI free vô hạn + protection free. Đã đánh đổi bảo mật: repo KHÔNG chứa secret nào (gate xác minh), protocol/docs/tools có thể công khai.
  - Sparse file + du = bẫy test giả dương điển hình; ghi chú vào test để người sau không tái phạm.
- **Next / Tiếp theo:**
  1. Tự kiểm tra cục bộ (ruff + pytest) → push → `ci_status --wait` → xác minh 4 job xanh (kiểm chứng giả thuyết: CI limit chỉ áp dụng repo private).
  2. Chốt chủ đề NCKH → EXP-001.

## [2026-10-16 21:00] Task ID: 3 — Kích hoạt CI + chẩn đoán CI bị chặn (thí nghiệm đối chứng)

- **Did / Đã làm:**
  - Push enforcement commit `d06c49a` → CI `enforce` báo **failure** ngay lập tức.
  - Truy vết 4 tầng: (1) check-run annotations trống; (2) log cấp run + job → rỗng/BlobNotFound; (3) job chết sau 2 giây với `steps: []` — runner chưa hề chạy; (4) tái hiện 4 check cục bộ trên cây `d06c49a` → tất cả PASS.
  - **Thí nghiệm đối chứng (EXP: ci-probe):** tạo `.github/workflows/minimal-test.yml` chỉ có `echo` → push (`2fde992`) + `workflow_dispatch` → **cả 3 run đều failure y hệt** (2s, 0 bước, 0 log).
  - Tạo tag `infra-v1` ghim mốc infrastructure (thay thế branch protection không khả dụng — private repo cần GitHub Pro).
  - Gate Layer 1 xác nhận hoạt động THẬT: nó đã chặn 1 lần push khi thấy `.env` bị track → sửa `git rm --cached .env` rồi push lại OK.
- **Why / Tại sao:**
  - Workflow tối giản `echo` cũng chết như nhau ⇒ loại trừ giả thuyết "YAML của tôi sai" ⇒ nguyên nhân nằm ở cấp tài khoản/repo. Triệu chứng (chết ngay, 0 bước, 0 log) khớp chuẩn với Actions bị chặn do **billing/spending limit hoặc kiểm duyệt tài khoản mới** trên repo private.
- **Findings / Phát hiện:**
  - CI (Layer 2) hiện KHÔNG hoạt động — lỗi ở cấp tài khoản GitHub của user, không phải code enforcement.
  - Branch protection (Layer 3 đầy đủ) cần GitHub Pro cho repo private → dùng tag `infra-v1` ghim mốc làm phương án tạm, PROTOCOL vẫn cấm force-push bằng luật.
  - Layer 1 (gate.sh) đã được chứng minh hoạt động thật bằng trường hợp chặn `.env`.
- **Next / Tiếp theo:**
  1. User kiểm tra `github.com/settings/billing` + mở tab Actions của repo xem banner lỗi chính xác (spending limit / verify account).
  2. Khi CI sống lại: `minimal-test` phải xanh trước, `enforce` xanh sau (canary test).
  3. Nếu không muốn sửa billing: chọn 1 — repo public (CI + branch protection free) hoặc chấp nhận chỉ có Layer 1.
  4. Chốt chủ đề NCKH → EXP-001.

## [2026-10-16 20:20] Task ID: 1 — Chẩn đoán môi trường + dựng khung phòng lab số (persistence infrastructure)

- **Did / Đã làm:**
  - Khám nghiệm sandbox sau reset: uptime 56 phút; `upload/` rỗng; `download/` chỉ còn README mặc định; `worklog.md` cũ không còn; git chỉ có 1 commit rỗng và **không có remote**.
  - Xác định loại DB: `.env` → `DATABASE_URL` dạng `file:` → **SQLite nằm trong sandbox** → chết theo reset (phân tích bằng script, không in credentials).
  - Dựng bộ khung: `PROTOCOL.md` (10 điều vận hành khoa học), `CONTEXT_SNAPSHOT.md`, `RESTORE.md`, `tools/checkpoint.sh`, `tools/db_backup.sh`, cây thư mục `research/` `data/` `scripts/` `tools/` `download-exports/`; mở rộng `.gitignore` (`.env`, `upload/`, cache...).
- **Why / Tại sao:**
  - User báo mất dữ liệu lặp lại (file upload, DB, ngữ cảnh nghiên cứu) do sandbox reset — chẩn đoán xác nhận 100%: không có cơ chế persistent nào mặc định. Git remote (GitHub private) là kênh duy nhất sống sót và cho phép agent phiên sau `git clone` để phục hồi ngữ cảnh đầy đủ.
  - Worklog cũ bị mất + ghi tóm tắt sáo rỗng → thiết kế worklog bắt buộc ghi "Did/Why/Findings/Next" và snapshot ngữ cảnh riêng, vì agent kế nhiệm chỉ có thể đọc được những gì nằm trong repo.
- **Findings / Phát hiện:**
  - Mọi thứ ngoài remote đều tạm bợ — phải checkpoint đều tay, không dồn cuối phiên.
  - PAT không được lưu trong repo (cấm) → sau mỗi reset agent phải xin lại PAT từ user; quy trình chi tiết ở `RESTORE.md`.
- **Next / Tiếp theo:**
  1. User tạo repo GitHub private + fine-grained PAT → gửi `username/repo` + token.
  2. Agent nối remote, push lần đầu, ghi commit hash vào `CONTEXT_SNAPSHOT.md`.
  3. Chốt chủ đề nghiên cứu (AI/ML) → mở `EXP-001` theo quy trình pre-register.
