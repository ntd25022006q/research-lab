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
