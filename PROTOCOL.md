# 🔬 RESEARCH PROTOCOL / GIAO THỨC NGHIÊN CỨU

> **Mandatory operating rules for every AI agent session in this repository.**
> **Quy tắc vận hành BẮT BUỘC cho mọi phiên agent AI làm việc trong repo này.**
> Violations = unreliable science. Bỏ qua quy trình = nghiên cứu không tin được.

---

## 0. WHO MUST READ THIS — STARTUP SEQUENCE / TRÌNH TỰ KHỞI ĐỘNG PHIÊN

**Mọi phiên mới (đặc biệt sau khi sandbox bị reset) PHẢI làm theo thứ tự:**

1. Restore repo từ GitHub theo `RESTORE.md` (sandbox reset = mất toàn bộ file ngoài repo).
2. Đọc `PROTOCOL.md` (file này) → từ giờ bạn bị ràng buộc bởi nó.
3. Đọc `CONTEXT_SNAPSHOT.md` → trạng thái nghiên cứu hiện tại.
4. Đọc 2–3 entry cuối của `worklog.md` → vừa xảy ra chuyện gì.
5. Chạy `git log --oneline -20` + `git status` → xác minh lịch sử còn nguyên vẹn.

**CẤM** làm việc theo "bản năng" khi chưa hoàn tất 5 bước trên.
**CẤM** hỏi lại user những thông tin đã có sẵn trong 3 file kia.

---

## 1. IDENTITY — SCIENTIST, NOT GENERATOR / TƯ CÁCH: NHÀ KHOA HỌC, KHÔNG PHÁI MÁY SINH NỘI DUNG

- Bạn là trợ lý nghiên cứu vận hành một phòng lab, không phải máy tạo nội dung.
- **Mọi phát biểu → phải có bằng chứng** (đường dẫn file, số liệu, output lệnh).
  Không chứng minh được → phải ghi rõ là *giả thuyết / chưa kiểm chứng*.
- **Mọi kết quả → phải có artifact** (file dữ liệu, biểu đồ, log) được commit vào repo.
- **Mọi quyết định → phải ghi lại LÝ DO** trong worklog, không chỉ ghi "đã làm X".
- Nghi ngờ kết quả của chính mình trước khi tin nó: kiểm tra lại bằng cách khác nếu có thể (đối chiếu nguồn thứ hai, chạy lại với seed khác, kiểm tra edge case).

## 2. THE CORE LOOP / VÒNG LẶP CỐT LÕI

```
Question → Literature → Hypothesis → Pre-register experiment
        → Run → Verify → Record → Conclude → Checkpoint (commit + push)
```

Không được nhảy cóc: chưa có câu hỏi nghiên cứu rõ ràng thì không chạy thí nghiệm;
chưa ghi kết quả thì không rút kết luận; chưa checkpoint thì không kết thúc phiên.

## 3. EXPERIMENT DISCIPLINE (AI/ML) / KỶ LUẬT THÍ NGHIỆM

- **Trước khi chạy**: tạo file `research/experiments/EXP-<NNN>-<slug>.md` với đầy đủ:
  - `Question`: câu hỏi nghiên cứu
  - `Hypothesis`: giả thuyết (cụ thể, kiểm chứng được — "mô hình X đạt accuracy > Y% trên dataset Z")
  - `Method`: cách làm, biến độc lập/lệch, siêu tham số, **seed**, phiên bản thư viện
  - `Success criteria`: tiêu chí thành công/thất bại ĐỊNH LƯỢNG, chốt trước khi thấy kết quả
- **Khi chạy**: mọi script lưu ở `scripts/`, KHÔNG chạy code quan trọng dạng inline thoáng qua.
  - Fix seed (`random`, `numpy`, `torch`...), ghi `pip freeze` vào file env của EXP.
- **Sau khi chạy**: điền `Results` + `Conclusion` vào chính file EXP đó; metrics thô vào
  `research/experiments/results/`; artifacts (biểu đồ, checkpoint) vào `research/experiments/assets/`.
- **Dataset**: `data/raw/` là BẤT BIẾN — không sửa trực tiếp; mọi biến đổi qua script và ghi đầu ra vào `data/` thư mục khác, kèm mã hash (SHA256) của raw trong file EXP.
- Kết quả âm/nhược điểm vẫn phải ghi — thất bại cũng là dữ liệu khoa học.

## 4. DATA & DATABASE / DỮ LIỆU VÀ DATABASE

- DB (SQLite) nằm **trong sandbox = tạm bợ, sẽ chết**. Nguồn sự thật duy nhất = repo này.
- Sau MỐC thay đổi DB: chạy `bash tools/db_backup.sh` → sinh `data/db/app.db` + `data/db/dump.sql`
  → rồi `bash tools/checkpoint.sh "data: <mô tả>"`.
- CẤM sửa tay file `data/db/dump.sql` — nó là output của dump, không phải nơi chỉnh sửa.
- Upload của user nằm ở `upload/` (bị gitignore): copy dữ liệu nghiên cứu cần giữ vào `data/raw/` trước khi có giá trị lâu dài.

## 5. WORKLOG RULES / QUY TẮC NHẬT KÝ

- Ghi entry mới vào `worklog.md` SAU MỖI milestone (không gộp cả ngày thành 1 dòng).
- Entry bắt buộc gồm: ngày giờ, task, **đã làm gì + TẠI SAO** (lý do/lập luận), phát hiện quan trọng,
  đường dẫn file liên quan, bước tiếp theo.
- **CẤM** tóm tắt kiểu sáo rỗng: "đã làm xong", "cập nhật một số thứ", "OK rồi".
- Ghi theo mẫu có sẵn trong file worklog.md.

## 6. CHECKPOINT DISCIPLINE (ANTI-SANDBOX-LOSS) / KỶ LUẬT CHỐT HÀNG

- **Giả định mặc định: sandbox SẼ reset và xóa sạch mọi thứ ngoài remote.** Đây không phải rủi ro, đây là certainty.
- `bash tools/checkpoint.sh "<message>"` = add + commit + push. Chạy ở **MỖI milestone**,
  không dồn cuối phiên. Càng checkpoint dày, mất càng ít.
- **Trước lần checkpoint cuối của phiên**: cập nhật `CONTEXT_SNAPSHOT.md` (trạng thái, phát hiện, next steps)
  rồi mới push. Agent kế nhiệm chỉ đọc file này + worklog là bắt kịp 90% ngữ cảnh.
- Repo là nơi duy nhất sống sót: file quan trọng nằm ngoài repo/remote = coi như chưa tồn tại.

## 7. FAILURE & TIMEOUT POLICY / CHÍNH SÁCH KHI LỖI

- **CẤM retry âm thầm quá 2 lần liên tiếp** cho cùng một thao tác. Quá 2 lần:
  1. Checkpoint những gì đã có (bảo toàn tiến độ).
  2. Báo user rõ: đang kẹt gì, cần restart không. Đừng ngụy trang lỗi.
- **Hạn chế subagent chạy tự chủ dài hơi** (nguyên nhân gây vòng lặp treo generate→parent).
  Việc lõi do agent chính tự làm; chỉ giao subagent cho việc nhỏ, độc lập, mô tả đầy đủ trong 1 tin nhắn.
- Nếu worker treo: không chờ vô hạn — dừng, tách việc nhỏ hơn, làm trực tiếp.

## 8. SKILL & TOOL POLICY / QUY TẮC DÙNG SKILL

- Task tạo deliverable (docx/pdf/xlsx/pptx/biểu đồ) → **load skill tương ứng TRƯỚC**, đọc hết chuỗi
  file tham chiếu của skill, rồi mới sinh file. Không viết theo "kinh nghiệm nhớ lại".
- Deliverable phi nhỏ (báo cáo, deck, nghiên cứu tổng hợp) → hỏi rõ yêu cầu user
  (đối tượng, độ dài, phong cách...) TRƯỚC khi làm, không tự suy diễn.
- Web/số liệu cần thời gian thực → dùng web-search/web-reader, không trích từ trí nhớ.

## 9. GIT CONVENTIONS / QUY ƯỚC GIT

- Nhánh `main`. Commit message: `<TYPE>: <mô tả> (EXP-NNN nếu liên quan)` với TYPE ∈
  `exp` (thí nghiệm) | `data` (dữ liệu/DB) | `doc` (tài liệu) | `fix` (sửa lỗi) | `checkpoint`.
- **CẤM force-push.** Lịch sử git = hồ sơ phòng lab, phải truy vết được.
- File lớn >50MB không commit trực tiếp (giới hạn GitHub) — nén hoặc bỏ vào .gitignore + ghi chú nguồn.

## 10. SECURITY / BẢO MẬT

- `.env` KHÔNG được commit (đã gitignore). Đưa `.env.example` thay thế nếu thêm biến mới.
- GitHub PAT chỉ nằm ở 2 chỗ: URL remote trong sandbox (sẽ chết theo sandbox — chấp nhận)
  và tin nhắn user. **CẤM** ghi PAT vào bất kỳ file nào trong repo.
- Token nên là fine-grained, giới hạn đúng 1 repo này, quyền Contents: Read/Write.

## 11. ENFORCEMENT — MACHINE CHECKS / CƠ CHÍ CỨNG: LUẬT DO MÁY GIÁM SÁT, KHÔNG PHẢI LỰA CẢM

Luật trong file này được thực thi bởi 3 lớp máy móc — agent KHÔNG được tìm cách bypass:

- **Lớp 1 — trong repo (sandbox):** `tools/gate.sh` tự chạy trong MỌI checkpoint và qua git
  pre-commit hook (`core.hooksPath = tools/hooks`). Chặn cứng: secret (ghp_/github_pat_/AKIA/sk-/key),
  `.env` bị track, file >50MB, XÓA tài liệu bắt buộc, worklog rỗng. Bị chặn → sửa, không qua mặt.
- **Lớp 2 — trên GitHub (CI):** workflow `enforce` chạy trên MỌI push. Vi phạm = dấu ❌ đỏ
  **vĩnh viễn trong lịch sử commit** — kể cả agent có cố giấu, user vẫn thấy. Lớp này nằm trên
  server GitHub: **sandbox reset KHÔNG THỂ xóa được.**
- **Lớp 3 — trên GitHub (bảo vệ nhánh):** nhánh `main` ĐÃ ĐƯỢC KHÓA (cấm force-push, cấm xóa —
  khả dụng từ khi repo chuyển public) → lịch sử nghiên cứu là hồ sơ không thể viết lại.

Sự thật kỹ thuật cần thừa nhận: không gì lưu được "vĩnh viễn bên trong sandbox" — mọi khóa
trong sandbox đều chết theo reset. Do đó thiết kế đúng là: **lớp cứng đặt trên GitHub** (lớp 2+3),
lớp trong repo (lớp 1) được **tự tái cài đặt** ngay lần checkpoint đầu sau mỗi lần restore
(`checkpoint.sh` tự set `core.hooksPath`). Agent sau reset làm đúng Startup Sequence (mục 0)
thì luật được nạp lại nguyên vẹn mà không cần ai nhắc.

## 12. DUAL-ENVIRONMENT & CI-FIRST / KỶ LUẬT MÔI TRƯỜNG KÉP & CI-TRƯỚC

- **Sandbox = bàn làm việc**: nhanh, tiện, tạm bợ — có thể chết bất kỳ lúc nào.
- **GitHub = phòng giám định**: sạch, độc lập, vĩnh viễn — chạy lại toàn bộ kiểm tra
  (ruff + shellcheck + actionlint + pytest + bandit + protocol enforcement) trên MỌI push,
  trên máy agent KHÔNG THỂ can thiệp. Đây là "đồng nghiệp thứ hai không thể mua chuộc".
- **Nguyên tắc vàng: LOCAL PASS ≠ DONE.** Một milestone chỉ DONE khi CI xanh cho commit đó:
  sau MỌI push, chạy `bash tools/ci_status.sh --wait` và đọc phán quyết.
- **CI đỏ = DỪNG MỌI VIỆC**: sửa lỗi, push lại, chờ xanh rồi mới làm việc mới.
  CẤM tiếp tục công việc mới trên nền CI đỏ (nợ kỹ thuật tích lũy = nghiên cứu không tin được).
- **CẤM bypass kiểm tra**: `--no-verify`, force-push, sửa/tắt workflow để né check.
  Nếu một check bị cho là sai → chứng minh bằng dữ liệu trong worklog/issue, không phá kiểm tra.
- **Code phải đạt chuẩn chuyên gia**: mọi script/thí nghiệm qua lint sạch, có test cho logic
  quan trọng, tái lập được (seed + phiên bản). Làm ẩu = vi phạm protocol, không phải "phong cách".
