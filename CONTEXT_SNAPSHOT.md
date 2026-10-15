# CONTEXT SNAPSHOT / BẢN CHỤP NGỮ CẢNH

> **AGENT: cập nhật file này TRƯỚC lần checkpoint cuối mỗi phiên. Đây là file đọc ĐẦU TIÊN khi phục hồi.**
> **Refresh this file BEFORE the final checkpoint of every session. Read this FIRST when restoring.**

---

- **Last updated / Cập nhật:** 2026-10-16
- **Commit / Mã commit:** *(điền sau lần push đầu)*
- **Phase / Giai đoạn:** 🟢 INFRASTRUCTURE — phòng lab số vừa được dựng, chưa có nghiên cứu cụ thể

## 1. MISSION / SỨC MỆNH

- **Research goal / Mục tiêu nghiên cứu:** *(user chưa chốt chủ đề cụ thể — lĩnh vực: AI/ML)*
- **Success criteria / Tiêu chí thành công:** *(điền khi chốt đề tài)*
- **Constraint / Ràng buộc:** mọi thứ phải sống sót qua sandbox reset → checkpoint đều tay lên GitHub.

## 2. CURRENT STATE / TRẠNG THÁI HIỆN TẾ

- **Done / Đã xong:**
  - Dựng khung phòng lab: PROTOCOL.md, worklog.md, RESTORE.md, tools/ (checkpoint.sh, db_backup.sh), cây thư mục research/ + data/ + scripts/.
  - Chẩn đoán môi trường (2026-10-16): sandbox mới reset (uptime 56 phút), upload/ rỗng, DB là SQLite trong sandbox (`DATABASE_URL=file:...`), git có sẵn nhưng chưa có remote → xác nhận cơ chế mất dữ liệu user mô tả là đúng.
- **In progress / Đang làm:** chờ user tạo repo GitHub + PAT để nối remote và push lần đầu.
- **Blocked / Đang kẹt:** không thể push đến đâu cho đến khi có `username/repo + PAT` từ user.

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

1. **User:** tạo repo GitHub private + fine-grained PAT → gửi `username/repo` + PAT trong chat.
2. **Agent:** `git remote add origin https://<PAT>@github.com/<user>/<repo>.git` → push lần đầu → ghi commit hash vào đây.
3. **User + Agent:** chốt chủ đề nghiên cứu cụ thể → điền mục 1 MISSION.
4. **Agent:** mở `research/experiments/EXP-001-*.md` theo quy trình pre-register của PROTOCOL.md.

## 6. GOTCHAS / BẪY CẦN BIẾT (điều sẽ cắn agent kế nhiệm nếu bỏ qua)

- **Sau reset, remote URL (chứa PAT) cũng mất** → agent mới phải xin PAT lại từ user; đừng tìm kiếm nó trong repo (cấm lưu PAT vào file).
- `skills/`, `upload/`, `.env` bị gitignore cố ý — đừng "sửa" .gitignore để đưa chúng vào repo.
- `download/` (nơi user tải file) KHÁC với `download-exports/` (trong repo). Deliverable cuối cần nằm ở cả hai: copy từ `download-exports/` → `download/`.
- Nhánh mặc định trong sandbox là gì cần kiểm tra (`git branch`): nếu không phải `main` thì đổi trước khi push đầu tiên.

## 7. RESTORE CHECKLIST / DANH SÁCH PHỤC HỒI

→ Xem `RESTORE.md`. Tóm tắt: xin PAT từ user → clone vào `/home/z/my-project` → đọc PROTOCOL.md → file này → tail worklog.md → `git log` kiểm tra → làm tiếp từ mục 5.
