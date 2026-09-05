#!/usr/bin/env python3
"""Create an encrypted Hermes backup and upload it to a Discord webhook.

The webhook is read from a root-managed SOPS secret, never placed in argv,
logs, Git, or the systemd unit. Full backups are encrypted with the local age
identity and split into conservative-size attachments for Discord.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import fcntl
import math
import os
import shutil
import subprocess
import tempfile
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

CHUNK_SIZE = 7 * 1024 * 1024
UPLOAD_ATTEMPTS = 6
UPLOAD_TIMEOUT = 90
UPLOAD_SPACING_SECONDS = 1.0
COMPLETE_RETENTION_DAYS = 7
FAILED_RETENTION_DAYS = 3

HERMES_HOME = Path(os.environ.get("HERMES_HOME", str(Path.home() / ".hermes")))
HERMES_BIN = os.environ.get("HERMES_BIN", str(Path.home() / ".local/bin/hermes"))
AGE_BIN = os.environ.get("AGE_BIN", "age")
AGE_KEYGEN_BIN = os.environ.get("AGE_KEYGEN_BIN", "age-keygen")
AGE_KEY_FILE = Path(os.environ.get("AGE_KEY_FILE", str(Path.home() / ".config/sops/age/keys.txt")))
WEBHOOK_FILE = Path(os.environ.get("WEBHOOK_FILE", "/run/secrets/hermes-backup-webhook"))
STATE_DIR = Path(os.environ.get("STATE_DIR", "/var/lib/hermes-discord-backup"))
RUNS_DIR = STATE_DIR / "runs"
STATE_FILE = STATE_DIR / "state.json"


def log(message: str) -> None:
    print(message, flush=True)


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def backup_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]


def set_private(path: Path) -> None:
    try:
        path.chmod(0o600)
    except FileNotFoundError:
        pass


def atomic_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, raw_tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".partial", dir=path.parent)
    tmp = Path(raw_tmp)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, sort_keys=True, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        set_private(tmp)
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


def load_state() -> dict[str, Any] | None:
    try:
        value = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def validate_webhook() -> str:
    try:
        value = WEBHOOK_FILE.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise RuntimeError("Discord webhook secret is unavailable") from exc
    try:
        parsed = urlparse(value)
        hostname = parsed.hostname
    except ValueError as exc:
        raise RuntimeError("Discord webhook secret has an unexpected format") from exc
    if (
        parsed.scheme != "https"
        or hostname != "discord.com"
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or not parsed.path.startswith("/api/webhooks/")
        or len(parsed.path.split("/")) != 5
        or any(ch.isspace() for ch in value)
    ):
        raise RuntimeError("Discord webhook secret has an unexpected format")
    return value


def age_recipient() -> str:
    if not AGE_KEY_FILE.is_file():
        raise RuntimeError("age identity file is unavailable")
    try:
        output = subprocess.check_output(
            [AGE_KEYGEN_BIN, "-y", str(AGE_KEY_FILE)],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise RuntimeError("could not derive age recipient") from exc
    for line in output.splitlines():
        candidate = line.strip()
        if candidate.startswith("age1"):
            return candidate
    raise RuntimeError("age identity did not yield a recipient")


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def run_hermes_backup(run_dir: Path, run_id: str) -> Path:
    output = run_dir / f"hermes-{run_id}.zip"
    env = os.environ.copy()
    env["HERMES_HOME"] = str(HERMES_HOME)
    log("Creating consistent Hermes backup ...")
    try:
        result = subprocess.run(
            [HERMES_BIN, "backup", "-o", str(output)],
            env=env,
            capture_output=True,
            text=True,
            timeout=1800,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        output.unlink(missing_ok=True)
        raise RuntimeError("Hermes backup process could not complete") from exc
    if result.returncode != 0 or not output.is_file() or output.stat().st_size == 0:
        output.unlink(missing_ok=True)
        raise RuntimeError(f"Hermes backup failed (exit {result.returncode})")
    log(f"Hermes backup created: {output.stat().st_size} bytes")
    return output


def encrypt_backup(plain: Path, run_dir: Path, run_id: str, recipient: str) -> Path:
    encrypted = run_dir / f"hermes-{run_id}.zip.age"
    try:
        result = subprocess.run(
            [AGE_BIN, "-r", recipient, "-o", str(encrypted), str(plain)],
            capture_output=True,
            text=True,
            timeout=1800,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        encrypted.unlink(missing_ok=True)
        raise RuntimeError("age encryption process could not complete") from exc
    finally:
        # The plaintext contains the complete Hermes state, including sensitive
        # files. Remove it regardless of whether age succeeds.
        plain.unlink(missing_ok=True)
    if result.returncode != 0 or not encrypted.is_file() or encrypted.stat().st_size == 0:
        encrypted.unlink(missing_ok=True)
        raise RuntimeError(f"age encryption failed (exit {result.returncode})")
    set_private(encrypted)
    log(f"Encrypted backup created: {encrypted.stat().st_size} bytes")
    return encrypted


def valid_run_path(raw: Any) -> Path | None:
    if not isinstance(raw, str) or not raw:
        return None
    try:
        candidate = Path(raw).resolve()
        candidate.relative_to(RUNS_DIR.resolve())
    except (ValueError, OSError):
        return None
    return candidate


def resumable_run(state: dict[str, Any] | None) -> tuple[dict[str, Any], Path] | None:
    if not state or state.get("status") == "complete":
        return None
    run_dir = valid_run_path(state.get("run_dir"))
    encrypted = valid_run_path(state.get("encrypted_path"))
    if run_dir is None or encrypted is None or not encrypted.is_file():
        return None
    if encrypted.parent != run_dir:
        return None
    try:
        expected = int(state.get("encrypted_size", 0))
    except (TypeError, ValueError):
        return None
    if expected <= 0 or encrypted.stat().st_size != expected:
        return None
    if state.get("encrypted_sha256") != file_sha256(encrypted):
        return None
    return state, encrypted


def split_encrypted(encrypted: Path, run_dir: Path, run_id: str) -> list[dict[str, Any]]:
    parts_dir = run_dir / "parts"
    if parts_dir.exists():
        shutil.rmtree(parts_dir)
    parts_dir.mkdir(mode=0o700, parents=True)
    size = encrypted.stat().st_size
    source_sha256 = file_sha256(encrypted)
    total = max(1, math.ceil(size / CHUNK_SIZE))
    result: list[dict[str, Any]] = []
    combined = hashlib.sha256()
    with encrypted.open("rb") as source:
        for index in range(1, total + 1):
            name = f"hermes-{run_id}.part-{index:03d}-of-{total:03d}.age"
            path = parts_dir / name
            remaining = min(CHUNK_SIZE, size - (index - 1) * CHUNK_SIZE)
            written = 0
            digest = hashlib.sha256()
            with path.open("wb") as target:
                while written < remaining:
                    block = source.read(min(1024 * 1024, remaining - written))
                    if not block:
                        raise RuntimeError("encrypted backup ended while splitting")
                    target.write(block)
                    digest.update(block)
                    combined.update(block)
                    written += len(block)
                target.flush()
                os.fsync(target.fileno())
            set_private(path)
            result.append(
                {
                    "index": index,
                    "filename": name,
                    "size": written,
                    "sha256": digest.hexdigest(),
                }
            )
    if sum(int(part["size"]) for part in result) != size or combined.hexdigest() != source_sha256:
        shutil.rmtree(parts_dir, ignore_errors=True)
        raise RuntimeError("encrypted backup split failed integrity verification")
    return result


def multipart(payload: dict[str, Any], filename: str, data: bytes) -> tuple[bytes, str]:
    boundary = "----HermesBackup" + uuid.uuid4().hex
    marker = boundary.encode("ascii")
    payload_bytes = json.dumps(payload, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    body = b"".join(
        [
            b"--" + marker + b"\r\n",
            b'Content-Disposition: form-data; name="payload_json"\r\n',
            b"Content-Type: application/json\r\n\r\n",
            payload_bytes,
            b"\r\n--" + marker + b"\r\n",
            f'Content-Disposition: form-data; name="files[0]"; filename="{filename}"\r\n'.encode("ascii"),
            b"Content-Type: application/octet-stream\r\n\r\n",
            data,
            b"\r\n--" + marker + b"--\r\n",
        ]
    )
    return body, boundary


def upload_file(webhook: str, payload: dict[str, Any], path: Path) -> None:
    data = path.read_bytes()
    body, boundary = multipart(payload, path.name, data)
    separator = "&" if "?" in webhook else "?"
    endpoint = webhook + separator + "wait=true"
    last_status: int | None = None
    for attempt in range(1, UPLOAD_ATTEMPTS + 1):
        request = Request(
            endpoint,
            data=body,
            method="POST",
            headers={
                "Content-Type": f"multipart/form-data; boundary={boundary}",
                "Content-Length": str(len(body)),
                "User-Agent": "hermes-discord-backup/1.0",
            },
        )
        try:
            with urlopen(request, timeout=UPLOAD_TIMEOUT) as response:
                status = int(response.status)
                response.read(4096)
            if 200 <= status < 300:
                return
            last_status = status
        except HTTPError as exc:
            last_status = int(exc.code)
            retry_after = exc.headers.get("Retry-After")
            try:
                exc.close()
            except OSError:
                pass
            if last_status not in {429, 500, 502, 503, 504}:
                raise RuntimeError(f"Discord rejected upload (HTTP {last_status})") from None
            try:
                delay = min(120.0, max(1.0, float(retry_after))) if retry_after else min(120.0, 2.0 ** attempt)
            except ValueError:
                delay = min(120.0, 2.0 ** attempt)
            time.sleep(delay)
            continue
        except (URLError, TimeoutError, OSError):
            if attempt == UPLOAD_ATTEMPTS:
                raise RuntimeError("Discord upload failed after network retries") from None
            time.sleep(min(120.0, 2.0 ** attempt))
            continue
        if attempt < UPLOAD_ATTEMPTS:
            time.sleep(min(120.0, 2.0 ** attempt))
    raise RuntimeError(f"Discord upload failed after retries (HTTP {last_status})")


def restore_hint(run_id: str, parts: list[dict[str, Any]]) -> str:
    names = " ".join(part["filename"] for part in parts)
    joined = f"hermes-{run_id}.zip.age"
    plain = f"hermes-{run_id}.zip"
    return (
        f"cat {names} > {joined} && age -d -i ~/.config/sops/age/keys.txt "
        f"-o {plain} {joined} && hermes import {plain}"
    )


def cleanup_runs(current: Path | None = None) -> None:
    if not RUNS_DIR.is_dir():
        return
    now = time.time()
    for child in RUNS_DIR.iterdir():
        if not child.is_dir() or child.is_symlink() or child == current:
            continue
        state = None
        marker = child / "run.json"
        try:
            state = json.loads(marker.read_text(encoding="utf-8")) if marker.exists() else None
            age_days = COMPLETE_RETENTION_DAYS if isinstance(state, dict) and state.get("status") == "complete" else FAILED_RETENTION_DAYS
            if now - child.stat().st_mtime > age_days * 86400:
                shutil.rmtree(child)
        except (OSError, json.JSONDecodeError):
            continue


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="create and validate an encrypted backup without uploading",
    )
    args = parser.parse_args()

    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    RUNS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    STATE_DIR.chmod(0o700)
    RUNS_DIR.chmod(0o700)
    lock_path = STATE_DIR / "backup.lock"
    with lock_path.open("a+", encoding="utf-8") as lock_handle:
        set_private(lock_path)
        try:
            fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("another Hermes Discord backup is already running") from None

        webhook = validate_webhook()
        recipient = age_recipient()
        old_state = load_state()

        if args.dry_run:
            if resumable_run(old_state) is not None:
                raise RuntimeError("cannot run dry-run while an upload is resumable")
            run_id = backup_id()
            run_dir = RUNS_DIR / run_id
            run_dir.mkdir(mode=0o700)
            try:
                plain = run_hermes_backup(run_dir, run_id)
                encrypted = encrypt_backup(plain, run_dir, run_id, recipient)
                parts = split_encrypted(encrypted, run_dir, run_id)
                log(
                    f"DRY RUN: encrypted_sha256={file_sha256(encrypted)} "
                    f"bytes={encrypted.stat().st_size} parts={len(parts)}"
                )
            finally:
                shutil.rmtree(run_dir, ignore_errors=True)
            return 0

        resumed = resumable_run(old_state)
        if resumed is not None:
            state, encrypted = resumed
            run_id = str(state["run_id"])
            run_dir = valid_run_path(state["run_dir"])
            if run_dir is None:
                raise RuntimeError("saved backup state is invalid")
            log(f"Resuming encrypted backup {run_id}")
        else:
            run_id = backup_id()
            run_dir = RUNS_DIR / run_id
            run_dir.mkdir(mode=0o700)
            plain = run_hermes_backup(run_dir, run_id)
            encrypted = encrypt_backup(plain, run_dir, run_id, recipient)
            state = {
                "format": "hermes-discord-backup-v1",
                "run_id": run_id,
                "status": "uploading",
                "created_utc": utc_stamp(),
                "run_dir": str(run_dir),
                "encrypted_path": str(encrypted),
                "encrypted_size": encrypted.stat().st_size,
                "encrypted_sha256": file_sha256(encrypted),
                "age_recipient": recipient,
                "uploaded_parts": [],
            }
            atomic_json(run_dir / "run.json", state)
            atomic_json(STATE_FILE, state)

        if state.get("age_recipient") != recipient:
            raise RuntimeError("saved backup uses a different age recipient")
        parts = split_encrypted(encrypted, run_dir, run_id)
        state["parts"] = parts
        state["part_size"] = CHUNK_SIZE
        state["total_parts"] = len(parts)
        uploaded = []
        for value in state.get("uploaded_parts", []):
            try:
                index = int(value)
            except (TypeError, ValueError):
                continue
            if 1 <= index <= len(parts):
                uploaded.append(index)
        state["uploaded_parts"] = sorted(set(uploaded))
        atomic_json(run_dir / "run.json", state)
        atomic_json(STATE_FILE, state)

        log(f"Encrypted archive split into {len(parts)} Discord-safe parts")
        for part in parts:
            index = int(part["index"])
            if index in state["uploaded_parts"]:
                continue
            path = run_dir / "parts" / part["filename"]
            payload = {
                "content": (
                    f"Hermes encrypted backup {run_id} — part {index}/{len(parts)} "
                    f"({part['size']} bytes, sha256 {part['sha256'][:16]})"
                ),
                "allowed_mentions": {"parse": []},
            }
            log(f"Uploading part {index}/{len(parts)} ...")
            upload_file(webhook, payload, path)
            state["uploaded_parts"].append(index)
            state["uploaded_parts"] = sorted(set(state["uploaded_parts"]))
            atomic_json(run_dir / "run.json", state)
            atomic_json(STATE_FILE, state)
            time.sleep(UPLOAD_SPACING_SECONDS)

        manifest = {
            "format": "hermes-discord-backup-v1",
            "run_id": run_id,
            "created_utc": state["created_utc"],
            "encrypted_filename": f"hermes-{run_id}.zip.age",
            "encrypted_size": state["encrypted_size"],
            "encrypted_sha256": state["encrypted_sha256"],
            "age_recipient": recipient,
            "part_size": CHUNK_SIZE,
            "parts": parts,
            "restore": restore_hint(run_id, parts),
        }
        manifest_path = run_dir / f"hermes-{run_id}.manifest.json"
        atomic_json(manifest_path, manifest)
        manifest_payload = {
            "content": (
                f"Hermes encrypted backup complete — {run_id}; "
                f"{len(parts)} parts, {state['encrypted_size']} bytes, "
                f"sha256 {state['encrypted_sha256'][:16]}"
            ),
            "allowed_mentions": {"parse": []},
        }
        log("Uploading backup manifest ...")
        upload_file(webhook, manifest_payload, manifest_path)
        state["status"] = "complete"
        state["completed_utc"] = utc_stamp()
        state["manifest_filename"] = manifest_path.name
        atomic_json(run_dir / "run.json", state)
        atomic_json(STATE_FILE, state)
        shutil.rmtree(run_dir / "parts", ignore_errors=True)
        cleanup_runs(current=run_dir)
        log(f"Backup upload complete: {run_id} ({len(parts)} parts)")
        return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        log("Backup interrupted; encrypted staging data was retained for retry")
        raise SystemExit(130)
    except Exception as exc:
        log(f"Backup failed: {exc}")
        raise SystemExit(1)
