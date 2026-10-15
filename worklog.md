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
