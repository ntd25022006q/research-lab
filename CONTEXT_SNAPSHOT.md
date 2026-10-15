# CONTEXT SNAPSHOT / BẢN CHỤP NGỮ CẢNH

> **AGENT: cập nhật file này TRƯỚC lần checkpoint cuối mỗi phiên. Đây là file đọc ĐẦU TIÊN khi phục hồi.**
> **Refresh this file BEFORE the final checkpoint of every session. Read this FIRST when restoring.**

---

- **Last updated / Cập nhật:** 2026-10-16 21:45
- **Commit / Mã commit:** xem `git log` (chuỗi: 29fe386 bootstrap → d06c49a enforcement → 2fde992 ci-probe → f896733 findings → bộ kiểm thử)
- **Phase / Giai đoạn:** 🟢 DUAL-ENVIRONMENT ACTIVE — repo public, branch protection khóa, CI 4 job giám định mọi push, 13 self-tests xanh cục bộ

## 1. MISSION / SỨC MỆNH

- **Research goal / Mục tiêu nghiên cứu:** *(user chưa chốt chủ đề cụ thể — lĩnh vực: AI/ML)*
- **Success criteria / Tiêu chí thành công:** *(điền khi chốt đề tài)*
- **Constraint / Ràng buộc:** mọi thứ phải sống sót qua sandbox reset → checkpoint đều tay lên GitHub.

## 2. CURRENT STATE / TRẠNG THÁI HIỆN TẾ

- **Done / Đã xong:**
  - Dựng khung phòng lab: PROTOCOL.md, worklog.md, RESTORE.md, tools/ (checkpoint.sh, db_backup.sh), cây thư mục research/ + data/ + scripts/.
  - Chẩn đoán môi trường (2026-10-16): sandbox mới reset (uptime 56 phút), upload/ rỗng, DB là SQLite trong sandbox (`DATABASE_URL=file:...`), git có sẵn nhưng chưa có remote → xác nhận cơ chế mất dữ liệu user mô tả là đúng.
  - **Nối GitHub thành công:** repo `ntd25022006q/research-lab` (private), push main lần đầu.
  - **Kích hoạt 3 lớp khóa cứng:** (1) `tools/gate.sh` + git pre-commit hook chặn secret/.env/file lớn/xóa luật; (2) CI `enforce` trên GitHub quét mọi push; (3) bảo vệ nhánh main cấm force-push. Chi tiết: PROTOCOL.md Điều 11.
  - **Môi trường kép hoàn chỉnh:** repo PUBLIC (Actions free vô hạn + branch protection free đã bật: cấm force-push/xóa); `tests/test_infra.py` 13 self-tests tự chứng minh gate/db_backup/checkpoint hoạt động thật (kể cả test bypass và sparse-file bẫy); `quality.yml` 3 job (lint ruff+shellcheck+actionlint / pytest / bandit) + enforce.yml = 4 job giám định mỗi push; `ci_status.sh` bắt buộc check phán quyết CI sau mỗi push; PROTOCOL Điều 12 (local pass ≠ done, CI đỏ = dừng mọi việc).
- **In progress / Đang làm:** xác minh 4 job CI xanh trên repo public (kiểm chứng giả thuyết limit-chỉ-áp-dụng-private).
- **Blocked / Đang kẹt:** không có blocker nào.

## 3. KEY FINDINGS / PHÁT HIỆN QUAN TRỌNG (kèm bằng chứng)

1. Sandbox ephemeral 100% — bằng chứng: uptime 56 phút, upload/ rỗng, không còn worklog cũ. (`worklog.md` entry #001)
2. DB in-sandbox: `.env` khai báo `DATABASE_URL` dạng `file:` → SQLite cục bộ, chết theo reset. (`tools/db_backup.sh` được viết để tự tìm mọi file `*.db|*.sqlite*` trong dự án)
3. Git có sẵn trong sandbox nhưng rỗng và không remote → phải tự nối GitHub bằng PAT.

## 4. FILE MAP / BẢN ĐỒ FILE

| Path | Vai trò / Role |
|---|---|
| `PROTOCOL.md` | Hiến pháp vận hành — AGENT PHẢI ĐỌC TRƯỚC TIÊN cùng file này |
| `worklog.md` | Nhật ký chi tiết theo milestone (append-only) |
| `RESTORE.md` | Quy trình phục hồi sau reset |
| `tools/checkpoint.sh` | Add + commit + push toàn bộ (chạy mỗi milestone) |
| `tools/db_backup.sh` | Dump SQLite → `data/db/app.db` + `data/db/dump.sql` |
| `research/experiments/` | File EXP-NNN (pre-register + kết quả) |
| `data/raw/` | Dữ liệu gốc BẤT BIẾN (không sửa trực tiếp) |
| `scripts/` | Toàn bộ code thí nghiệm |
| `download-exports/` | Sản phẩm xuất cho user (pdf/xlsx...) — nhớ copy ra `download/` nữa |

## 5. NEXT STEPS / BƯỚC TIẾP THEO (theo thứ tự)

1. ~~User tạo repo + PAT~~ ✅ xong — repo `ntd25022006q/research-lab`, remote đã nối, push đầu tiên OK.
2. ~~Agent nối remote + push~~ ✅ xong.
3. **User + Agent:** chốt chủ đề nghiên cứu cụ thể → điền mục 1 MISSION.
4. **Agent:** mở `research/experiments/EXP-001-*.md` theo quy trình pre-register của PROTOCOL.md.
5. **User (khuyến nghị):** sau khi setup ổn định, thu hồi PAT classic này + thay bằng fine-grained token (chỉ repo research-lab, Contents: R/W).

## 6. GOTCHAS / BẪY CẦN BIẾT (điều sẽ cắn agent kế nhiệm nếu bỏ qua)

- **Sau reset, remote URL (chứa PAT) cũng mất** → agent mới phải xin PAT lại từ user; đừng tìm kiếm nó trong repo (gate + CI chặn cứng — pattern PAT trong file làm CI đỏ).
- **PAT user đang dùng là CLASSIC quyền admin toàn phần** (`admin:org`, `delete_repo`...) — vượt needs; đã khuyến cáo user thu hồi + thay fine-grained sau khi setup ổn định. Nếu token cũ bị thu hồi mà user chưa đưa token mới: xin lại, đừng đoán.
- **CI (Layer 2) trên PRIVATE từng bị chặn cấp tài khoản** — đã chuyển repo sang PUBLIC để khắc phục (khớp giả thuyết billing/plan-limit). Sau reset: ĐỪNG chuyển lại private nếu không muốn CI chết lại.
- **Repo giờ là PUBLIC** — tuyệt đối không đẩy dữ liệu nhạy cảm/nghĩa vụ bảo mật vào; dữ liệu riêng để ở repo private khác hoặc cần user đồng ý.
- **Branch protection full cần GitHub Pro** cho repo private — nhưng trên public đã ACTIVE (không cần hành động gì thêm).
- `skills/`, `upload/`, `.env` bị gitignore cố ý — đừng "sửa" .gitignore để đưa chúng vào repo.
- `download/` (nơi user tải file) KHÁC với `download-exports/` (trong repo). Deliverable cuối cần nằm ở cả hai: copy từ `download-exports/` → `download/`.
- Nhánh mặc định là `main` (đã xác minh) — đừng tạo nhánh khác khi push thông thường.

## 7. RESTORE CHECKLIST / DANH SÁCH PHỤC HỒI

→ Xem `RESTORE.md`. Tóm tắt: xin PAT từ user → clone vào `/home/z/my-project` → đọc PROTOCOL.md → file này → tail worklog.md → `git log` kiểm tra → làm tiếp từ mục 5.
