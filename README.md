# 🔬 Research Lab / Phòng lab số

Repo lưu trữ vĩnh viễn cho quá trình nghiên cứu (AI/ML) — chống mất dữ liệu do sandbox reset.

[![enforce](https://github.com/ntd25022006q/research-lab/actions/workflows/enforce.yml/badge.svg)](https://github.com/ntd25022006q/research-lab/actions/workflows/enforce.yml)
[![quality](https://github.com/ntd25022006q/research-lab/actions/workflows/quality.yml/badge.svg)](https://github.com/ntd25022006q/research-lab/actions/workflows/quality.yml)
[![nightly](https://github.com/ntd25022006q/research-lab/actions/workflows/nightly.yml/badge.svg)](https://github.com/ntd25022006q/research-lab/actions/workflows/nightly.yml)

**Nguồn sự thật duy nhất = repo này trên GitHub.** Mọi thứ trong sandbox là tạm bợ.
**Môi trường kép (PROTOCOL §12):** sandbox = bàn làm việc; GitHub = phòng giám định độc lập
chấm bài mọi push (4 job mỗi push + ca đêm kiểm toán sâu) và lưu trữ vĩnh viễn.

## Cấu trúc / Structure

| Path | Vai trò |
|---|---|
| `PROTOCOL.md` | Hiến pháp vận hành — agent PHẢI đọc đầu tiên (cùng `CONTEXT_SNAPSHOT.md`) |
| `CONTEXT_SNAPSHOT.md` | Bản chụp ngữ cảnh hiện tại — phục hồi 90% trong 1 lần đọc |
| `worklog.md` | Nhật ký lab: Did / Why / Findings / Next theo từng milestone |
| `RESTORE.md` | Quy trình phục hồi sau reset (agent làm theo đúng thứ tự) |
| `research/` | Giả thuyết, thí nghiệm (EXP-NNN pre-register), tài liệu, literature |
| `data/` | `raw/` bất biến • `db/` SQLite + dump • `datasets/` |
| `scripts/` | Toàn bộ code — phải tái lập được (seed, phiên bản) |
| `tools/` | `checkpoint.sh` (commit+push) • `db_backup.sh` (dump DB) • `verify.sh` (bản phản chiếu CI tại chỗ) • `ci_status.sh` (đọc phán quyết CI) • `new_experiment.sh` (pre-register EXP) • `gate.sh` (cổng chặn) |
| `download-exports/` | Sản phẩm xuất cho người dùng |

## Vòng lặp làm việc / Workflow

```
làm việc → milestone → bash tools/verify.sh → bash tools/checkpoint.sh "<msg>"
         → bash tools/ci_status.sh --wait (xanh = DONE) → (reset xảy ra)
         → agent mới: RESTORE.md → clone → đọc PROTOCOL + SNAPSHOT + worklog → tiếp tục
```
