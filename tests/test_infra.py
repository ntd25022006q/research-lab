"""Self-tests: the lab verifies its own enforcement machinery.

Nguyên tắc: chính hệ thống kiểm tra phải được kiểm tra (quis custodiet ipsos custodes?).
Mỗi test ở đây chứng minh một cơ chế enforcement hoạt động THẬT, không phải tồn tại cho có.
"""

import shutil
import sqlite3
import subprocess
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parent.parent

# Danh sách BẮT BUỘC khớp với tools/gate.sh mục 1 + .github/workflows/enforce.yml step 1
MANDATORY = [
    "PROTOCOL.md",
    "CONTEXT_SNAPSHOT.md",
    "RESTORE.md",
    "worklog.md",
    "README.md",
    "pyproject.toml",
    "tests/test_infra.py",
    "tools/checkpoint.sh",
    "tools/db_backup.sh",
    "tools/gate.sh",
    "tools/ci_status.sh",
    "tools/verify.sh",
    "tools/new_experiment.sh",
    ".github/workflows/enforce.yml",
    ".github/workflows/quality.yml",
    ".github/workflows/nightly.yml",
]

PROTOCOL_SECTIONS = [f"## {i}." for i in range(14)]  # 0..13


def test_mandatory_files_exist():
    for f in MANDATORY:
        assert (REPO / f).is_file(), f"missing mandatory file: {f}"


def test_worklog_has_real_entries():
    txt = (REPO / "worklog.md").read_text(encoding="utf-8")
    assert "Task ID" in txt, "worklog không có entry nào"
    assert txt.count("## [") >= 2, "worklog cần ít nhất 2 entry có dấu thời gian"


def test_protocol_has_all_sections():
    txt = (REPO / "PROTOCOL.md").read_text(encoding="utf-8")
    for sec in PROTOCOL_SECTIONS:
        assert sec in txt, f"PROTOCOL.md thiếu mục {sec} — luật không được bị cắt xén"


def test_protocol_keeps_key_rules():
    """Ai xóa bớt điều luật quan trọng trong PROTOCOL.md phải làm test này đỏ."""
    txt = (REPO / "PROTOCOL.md").read_text(encoding="utf-8")
    assert "STARTUP SEQUENCE" in txt, "thiếu trình tự khởi động phiên"
    assert "LOCAL PASS" in txt, "thiếu kỷ luật CI-first (local pass ≠ done)"
    assert "force-push" in txt, "thiếu lệnh cấm force-push"
    assert "Baseline" in txt, "thiếu điều 13 (trung thực khoa học: baseline bắt buộc)"


def test_workflows_are_valid_yaml():
    import yaml  # noqa: PLC0415 — import cục bộ để môi trường không có pyyaml vẫn chạy test khác

    for wf in [
        ".github/workflows/enforce.yml",
        ".github/workflows/quality.yml",
        ".github/workflows/nightly.yml",
    ]:
        data = yaml.safe_load((REPO / wf).read_text(encoding="utf-8"))
        assert "jobs" in data, f"{wf} không có jobs"
        for job_name, job in data["jobs"].items():
            assert job.get("steps"), f"{wf} job {job_name} không có steps"


def test_gate_passes_on_the_real_repo():
    r = subprocess.run(["bash", "tools/gate.sh"], cwd=REPO, capture_output=True, text=True, timeout=60)
    assert r.returncode == 0, f"gate phải PASS trên repo sạch:\n{r.stdout}\n{r.stderr}"


def test_shell_scripts_have_valid_syntax():
    for f in [
        "tools/checkpoint.sh",
        "tools/db_backup.sh",
        "tools/gate.sh",
        "tools/ci_status.sh",
        "tools/verify.sh",
        "tools/new_experiment.sh",
        "tools/hooks/pre-commit",
        "tools/hooks/pre-push",
    ]:
        r = subprocess.run(["bash", "-n", str(REPO / f)], capture_output=True, text=True)
        assert r.returncode == 0, f"{f} lỗi cú pháp bash:\n{r.stderr}"


def test_nightly_workflow_has_hard_checks():
    """Ca đêm phải quét secret full-history + kiểm tra dump DB còn phục hồi được."""
    import yaml  # noqa: PLC0415

    data = yaml.safe_load((REPO / ".github" / "workflows" / "nightly.yml").read_text(encoding="utf-8"))
    # Bẫy YAML 1.1: key `on:` được parser hiểu là boolean True — phải tra cả hai
    triggers = data.get("on", data.get(True, {}))
    assert triggers.get("schedule"), "nightly phải có cron schedule"
    raw = (REPO / ".github" / "workflows" / "nightly.yml").read_text(encoding="utf-8")
    assert "gitleaks" in raw, "nightly thiếu gitleaks (quét secret full-history)"
    assert "restore_check.db" in raw, "nightly thiếu test khôi phục DB dump"


def test_new_experiment_scaffolds_preregistration(tmp_path):
    """new_experiment.sh phải sinh file EXP đủ mục pre-register + từ chối ghi đè."""
    tmp = Path(tmp_path)
    (tmp / "tools").mkdir(parents=True)
    shutil.copy(REPO / "tools" / "new_experiment.sh", tmp / "tools" / "new_experiment.sh")
    r = subprocess.run(
        ["bash", "tools/new_experiment.sh", "001", "baseline-demo", "42"],
        cwd=tmp, capture_output=True, text=True, timeout=60,
    )
    assert r.returncode == 0, f"scaffold thất bại:\n{r.stdout}\n{r.stderr}"
    exps = list((tmp / "research" / "experiments").glob("EXP-001-*.md"))
    assert len(exps) == 1, "phải sinh đúng 1 file EXP-001"
    txt = exps[0].read_text(encoding="utf-8")
    for kw in ["## Question", "## Hypothesis", "## Method", "## Success criteria", "PRE-REGISTERED"]:
        assert kw in txt, f"file EXP thiếu mục bắt buộc: {kw}"
    env_file = tmp / "research" / "experiments" / "envs" / "EXP-001.env"
    assert env_file.is_file(), "thiếu env freeze"
    assert "SEED=42" in env_file.read_text(encoding="utf-8")
    # Ghi đè phải bị từ chối — pre-register không được phá
    r2 = subprocess.run(
        ["bash", "tools/new_experiment.sh", "001", "baseline-demo", "42"],
        cwd=tmp, capture_output=True, text=True, timeout=60,
    )
    assert r2.returncode != 0, "new_experiment KHÔNG được phép ghi đè file đã có"


def _make_mini_lab(tmp: Path) -> Path:
    """Dựng một phòng lab thu nhỏ ĐỦ file bắt buộc trong thư mục tạm.
    Nhờ đó khi gate chặn, lý do duy nhất là lỗi được test nhắm tới (secret/size/missing)."""
    tmp = Path(tmp)
    (tmp / "tools").mkdir(parents=True)
    (tmp / ".github" / "workflows").mkdir(parents=True)
    for f in ["PROTOCOL.md", "CONTEXT_SNAPSHOT.md", "RESTORE.md"]:
        (tmp / f).write_text("placeholder", encoding="utf-8")
    (tmp / "worklog.md").write_text("Task ID: 1\n", encoding="utf-8")
    for wf in ["enforce.yml", "quality.yml"]:
        stub = "jobs: stub: {runs-on: ubuntu-latest, steps: []}\n"
        (tmp / ".github" / "workflows" / wf).write_text(stub, encoding="utf-8")
    for f in ["gate.sh", "db_backup.sh"]:
        shutil.copy(REPO / "tools" / f, tmp / "tools" / f)
    for f in ["checkpoint.sh", "ci_status.sh"]:
        (tmp / "tools" / f).write_text("#!/usr/bin/env bash\ntrue\n", encoding="utf-8")
    subprocess.run(["git", "init", "-q"], cwd=tmp, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.local"], cwd=tmp, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=tmp, check=True)
    subprocess.run(["git", "add", "-A"], cwd=tmp, check=True)
    return tmp


def test_gate_blocks_leaked_secret(tmp_path):
    tmp = _make_mini_lab(tmp_path)
    fake_token = "ghp_" + "a" * 36  # tạo động để scanner không tự khớp file test này
    (tmp / "leak.txt").write_text(f"token={fake_token}\n", encoding="utf-8")
    subprocess.run(["git", "add", "-A"], cwd=tmp, check=True)
    r = subprocess.run(["bash", "tools/gate.sh"], cwd=tmp, capture_output=True, text=True, timeout=60)
    assert r.returncode == 1, "gate phải CHẶN file chứa secret"
    assert "SECRET" in r.stdout + r.stderr


def test_gate_blocks_missing_mandatory_file(tmp_path):
    tmp = _make_mini_lab(tmp_path)
    (tmp / "RESTORE.md").unlink()
    subprocess.run(["git", "add", "-A"], cwd=tmp, check=True)
    r = subprocess.run(["bash", "tools/gate.sh"], cwd=tmp, capture_output=True, text=True, timeout=60)
    assert r.returncode == 1, "gate phải CHẶN khi thiếu tài liệu bắt buộc"
    assert "THIẾU" in r.stdout + r.stderr


def test_gate_blocks_oversized_file(tmp_path):
    tmp = _make_mini_lab(tmp_path)
    big = tmp / "big.bin"
    # GHI ZEROS THẬT (không dùng seek tạo sparse file) — vì gate đo bằng du (block thật)
    big.write_bytes(b"\0" * (51 * 1024 * 1024))
    subprocess.run(["git", "add", "-A"], cwd=tmp, check=True)
    r = subprocess.run(["bash", "tools/gate.sh"], cwd=tmp, capture_output=True, text=True, timeout=120)
    assert r.returncode == 1, "gate phải CHẶN file >50MB"
    assert "50MB" in r.stdout + r.stderr


def test_db_backup_dumps_sqlite(tmp_path):
    tmp = _make_mini_lab(tmp_path)
    con = sqlite3.connect(tmp / "app.db")
    con.execute("CREATE TABLE experiment (id INTEGER PRIMARY KEY, name TEXT)")
    con.execute("INSERT INTO experiment VALUES (1, 'baseline')")
    con.commit()
    con.close()
    r = subprocess.run(["bash", "tools/db_backup.sh"], cwd=tmp, capture_output=True, text=True, timeout=60)
    dump = (tmp / "data" / "db" / "dump.sql").read_text(encoding="utf-8")
    assert "CREATE TABLE experiment" in dump, f"dump thiếu schema:\n{r.stdout}\n{r.stderr}"
    assert "baseline" in dump, "dump thiếu dữ liệu"


@pytest.mark.parametrize("script", ["checkpoint.sh", "gate.sh"])
def test_pipeline_refuses_to_bypass_gate(tmp_path, script):
    """Khi gate chặn (có secret), checkpoint/gate phải thất bại — không có đường tắt.
    (db_backup.sh không thuộc nhánh gọi gate — nó là công cụ bị động, được checkpoint gọi SAU gate.)"""
    tmp = _make_mini_lab(tmp_path)
    fake_token = "ghp_" + "b" * 36
    (tmp / "leak2.txt").write_text(f"k={fake_token}\n", encoding="utf-8")
    shutil.copy(REPO / "tools" / "checkpoint.sh", tmp / "tools" / "checkpoint.sh")
    (tmp / "worklog.md").write_text("Task ID: x\n", encoding="utf-8")
    subprocess.run(["git", "add", "-A"], cwd=tmp, check=True)
    r = subprocess.run(["bash", f"tools/{script}"], cwd=tmp, capture_output=True, text=True, timeout=60)
    assert r.returncode != 0, f"{script} không được phép thành công khi gate chặn"
    assert "BLOCKED" in r.stdout + r.stderr
