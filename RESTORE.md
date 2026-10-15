# RESTORE / QUY TRÌNH PHỤC HỒI SAU RESET

> **Cho AGENT phiên mới: sandbox vừa reset, mọi thứ ngoài GitHub đã mất. Làm đúng thứ tự dưới đây.**
> **For a NEW agent session: the sandbox was reset; everything outside GitHub is gone. Follow this order.**

---

## Bước 1 — Xin thông tin từ user (chỉ cần 1 lần)

Nhờ user cung cấp trong chat (hoặc nhắc lại nếu đã có):
1. `username/repo-name` trên GitHub (repo private đã tạo sẵn).
2. **Fine-grained PAT** (định dạng `github_pat_...` hoặc `ghp_...`), quyền Contents: Read/Write, chỉ repo này.

> Vì sao phải xin lại: PAT chỉ được lưu ở remote URL trong sandbox (chết theo reset) — thiết kế này
> là CỐ Ý để token không nằm trong repo. Không tìm token trong file — sẽ không có.

## Bước 2 — Clone / gắn repo vào `/home/z/my-project`

```bash
# Trường hợp A: thư mục dự án còn (chỉ mất remote)
cd /home/z/my-project
git remote add origin https://<PAT>@github.com/<user>/<repo>.git
git fetch origin && git branch --set-upstream-to=origin/main main && git pull

# Trường hợp B: thư mục dự án bị xóa sạch (reset sâu)
git clone https://<PAT>@github.com/<user>/<repo>.git /home/z/my-project
```

Kiểm tra: `git log --oneline -5` phải hiện lịch sử cũ.

## Bước 3 — Khôi phục trạng thái làm việc

```bash
cd /home/z/my-project
```
1. Đọc `PROTOCOL.md` → bạn bị ràng buộc bởi nó.
2. Đọc `CONTEXT_SNAPSHOT.md` → trạng thái nghiên cứu, next steps.
3. Đọc 2–3 entry cuối `worklog.md`.
4. Kiểm tra DB: `ls data/db/` — nếu có `app.db` thì DB đã phục hồi sẵn theo repo;
   nếu chỉ có `dump.sql`: `sqlite3 data/db/app.db < data/db/dump.sql`.
   (Vị trí DB thực tế xem `.env` → `DATABASE_URL`.)
5. Nếu dự án có Prisma/Node: `npm install` + `npx prisma generate` nếu cần.
6. Xác minh máy móc enforcement còn nguyên: `bash tools/verify.sh` — phải ALL GREEN
   (cảnh báo tool thiếu tại chỗ được phép, nhưng gate phải pass).

## Bước 4 — Báo user 1 câu ngắn

Ví dụ: *"Đã phục hồi xong repo ở commit `abc1234`, đang ở giai đoạn X, bước tiếp theo là Y — làm tiếp nhé?"*

## Bước 5 — Tiếp tục công việc theo PROTOCOL.md

Làm việc bình thường. Nhớ: **checkpoint mỗi milestone** (`bash tools/checkpoint.sh "..."`).
