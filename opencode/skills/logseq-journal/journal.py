#!/usr/bin/env python3
"""
OpenCode Session Metadata Extractor

Reads OpenCode session data from SQLite (preferred) or legacy JSON files on
disk and outputs structured JSON metadata for use by the LLM in generating
Logseq journal entries.

Usage:
    python journal.py <session_id> <project_hash> [options]

Options:
    --project-dir PATH    Project directory for handoff tracking
    --chain               Follow handoff chain for related sessions
    --storage-root PATH   Override OpenCode storage root directory (legacy JSON)
    --db-path PATH        Override OpenCode SQLite database path

Output:
    JSON metadata to stdout
"""

import argparse
import json
import math
import re
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def ms_to_datetime(ms: int) -> datetime:
    """Convert Unix-millisecond timestamp to UTC datetime."""
    return datetime.fromtimestamp(ms / 1000.0, tz=timezone.utc)


def ms_to_local(ms: int) -> datetime:
    """Convert Unix-millisecond timestamp to local datetime."""
    return datetime.fromtimestamp(ms / 1000.0)


def format_duration(start_ms: int, end_ms: int) -> str:
    """Return a human-readable duration string (e.g. '12m', '1h 5m')."""
    seconds = max(0, (end_ms - start_ms)) / 1000.0
    minutes = int(seconds / 60)
    if minutes < 60:
        return f"{max(1, minutes)}m"
    hours = minutes // 60
    remaining = minutes % 60
    if remaining == 0:
        return f"{hours}h"
    return f"{hours}h {remaining}m"


def format_cost(cost: float) -> str:
    """Format a dollar cost to 2 decimal places."""
    return f"${cost:.2f}"


# ---------------------------------------------------------------------------
# OpenCodeStorage — reads session/message/part data from SQLite or JSON files
# ---------------------------------------------------------------------------

class OpenCodeStorage:
    """Reads OpenCode session data from SQLite or the legacy JSON storage directory.

    Auto-detects the storage backend: if the SQLite database exists at
    ``db_path``, it is used; otherwise falls back to reading JSON files
    from ``storage_root``.
    """

    _DEFAULT_DB = Path.home() / ".local" / "share" / "opencode" / "opencode.db"
    _DEFAULT_STORAGE = Path.home() / ".local" / "share" / "opencode" / "storage"

    def __init__(
        self,
        storage_root: Optional[str] = None,
        db_path: Optional[str] = None,
    ):
        # Resolve paths
        self._db_path = Path(db_path) if db_path else self._DEFAULT_DB
        self.root = Path(storage_root) if storage_root else self._DEFAULT_STORAGE

        # Decide backend: explicit db_path always wins; otherwise auto-detect
        if db_path:
            self._use_sqlite = self._db_path.is_file()
        elif storage_root:
            # Caller explicitly asked for JSON storage
            self._use_sqlite = False
        else:
            # Auto-detect: prefer SQLite when available
            self._use_sqlite = self._db_path.is_file()

    # -- SQLite helpers ----------------------------------------------------

    def _connect(self) -> sqlite3.Connection:
        """Open a read-only SQLite connection with row-factory."""
        conn = sqlite3.connect(f"file:{self._db_path}?mode=ro", uri=True)
        conn.row_factory = sqlite3.Row
        return conn

    @staticmethod
    def _session_row_to_dict(row: sqlite3.Row) -> dict:
        """Convert a SQLite session row to the legacy JSON dict shape."""
        r = dict(row)
        return {
            "id": r.get("id", ""),
            "slug": r.get("slug", ""),
            "version": r.get("version", ""),
            "projectID": r.get("project_id", ""),
            "directory": r.get("directory", ""),
            "title": r.get("title", ""),
            "time": {
                "created": r.get("time_created", 0),
                "updated": r.get("time_updated", 0),
            },
            "summary": {
                "additions": r.get("summary_additions"),
                "deletions": r.get("summary_deletions"),
                "files": r.get("summary_files"),
            },
        }

    @staticmethod
    def _message_row_to_dict(row: sqlite3.Row) -> dict:
        """Convert a SQLite message row to the legacy JSON dict shape.

        The ``data`` column is a JSON blob containing ``role``, ``time``,
        ``cost``, ``tokens``, etc.  We merge the parsed blob with the
        row-level ``id`` and ``session_id`` columns.
        """
        r = dict(row)
        data_blob = r.get("data")
        msg: dict = json.loads(data_blob) if data_blob else {}
        msg["id"] = r.get("id", "")
        msg["sessionID"] = r.get("session_id", "")
        return msg

    @staticmethod
    def _part_row_to_dict(row: sqlite3.Row) -> dict:
        """Convert a SQLite part row to the legacy JSON dict shape.

        The ``data`` column is a JSON blob containing ``type``, ``tool``,
        ``state``, etc.  We merge the parsed blob with the row-level ``id``.
        """
        r = dict(row)
        data_blob = r.get("data")
        part: dict = json.loads(data_blob) if data_blob else {}
        part["id"] = r.get("id", "")
        return part

    # -- sessions ----------------------------------------------------------

    def read_session(self, session_id: str, project_hash: str) -> Optional[dict]:
        """Read a single session by ID and project hash."""
        if self._use_sqlite:
            return self._read_session_sqlite(session_id, project_hash)
        path = self.root / "session" / project_hash / f"{session_id}.json"
        return self._read_json(path)

    def _read_session_sqlite(self, session_id: str, project_hash: str) -> Optional[dict]:
        try:
            with self._connect() as conn:
                row = conn.execute(
                    "SELECT * FROM session WHERE id = ? AND project_id = ?",
                    (session_id, project_hash),
                ).fetchone()
                if row is None:
                    return None
                return self._session_row_to_dict(row)
        except (sqlite3.Error, json.JSONDecodeError):
            return None

    def find_sessions(self, project_hash: str) -> list[dict]:
        """Return all sessions for a project hash, sorted by creation time."""
        if self._use_sqlite:
            return self._find_sessions_sqlite(project_hash)
        session_dir = self.root / "session" / project_hash
        if not session_dir.is_dir():
            return []
        sessions = []
        for f in session_dir.glob("ses_*.json"):
            data = self._read_json(f)
            if data:
                sessions.append(data)
        sessions.sort(key=lambda s: s.get("time", {}).get("created", 0))
        return sessions

    def _find_sessions_sqlite(self, project_hash: str) -> list[dict]:
        try:
            with self._connect() as conn:
                rows = conn.execute(
                    "SELECT * FROM session WHERE project_id = ? ORDER BY time_created",
                    (project_hash,),
                ).fetchall()
                return [self._session_row_to_dict(r) for r in rows]
        except (sqlite3.Error, json.JSONDecodeError):
            return []

    # -- messages ----------------------------------------------------------

    def read_messages(self, session_id: str) -> list[dict]:
        """Return all messages for a session, sorted by creation time."""
        if self._use_sqlite:
            return self._read_messages_sqlite(session_id)
        msg_dir = self.root / "message" / session_id
        if not msg_dir.is_dir():
            return []
        messages = []
        for f in msg_dir.glob("msg_*.json"):
            data = self._read_json(f)
            if data:
                messages.append(data)
        messages.sort(key=lambda m: m.get("time", {}).get("created", 0))
        return messages

    def _read_messages_sqlite(self, session_id: str) -> list[dict]:
        try:
            with self._connect() as conn:
                rows = conn.execute(
                    "SELECT * FROM message WHERE session_id = ? ORDER BY time_created",
                    (session_id,),
                ).fetchall()
                return [self._message_row_to_dict(r) for r in rows]
        except (sqlite3.Error, json.JSONDecodeError):
            return []

    # -- parts -------------------------------------------------------------

    def read_parts(self, message_id: str) -> list[dict]:
        """Return all parts for a message, sorted by start time."""
        if self._use_sqlite:
            return self._read_parts_sqlite(message_id)
        part_dir = self.root / "part" / message_id
        if not part_dir.is_dir():
            return []
        parts = []
        for f in part_dir.glob("prt_*.json"):
            data = self._read_json(f)
            if data:
                parts.append(data)
        # Sort by time.start if available, falling back to 0
        def sort_key(p):
            t = p.get("time", {})
            if isinstance(t, dict):
                return t.get("start", 0)
            return 0
        parts.sort(key=sort_key)
        return parts

    def _read_parts_sqlite(self, message_id: str) -> list[dict]:
        try:
            with self._connect() as conn:
                rows = conn.execute(
                    "SELECT * FROM part WHERE message_id = ? ORDER BY time_created",
                    (message_id,),
                ).fetchall()
                parts = [self._part_row_to_dict(r) for r in rows]
                # Apply the same sort as the legacy JSON path: by time.start
                def sort_key(p):
                    t = p.get("time", {})
                    if isinstance(t, dict):
                        return t.get("start", 0)
                    return 0
                parts.sort(key=sort_key)
                return parts
        except (sqlite3.Error, json.JSONDecodeError):
            return []

    # -- internal ----------------------------------------------------------

    @staticmethod
    def _read_json(path: Path) -> Optional[dict]:
        try:
            with open(path, "r", encoding="utf-8") as fh:
                return json.load(fh)
        except (FileNotFoundError, json.JSONDecodeError, OSError):
            return None


# ---------------------------------------------------------------------------
# HandoffChainTracker — finds related sessions via handoff artifacts
# ---------------------------------------------------------------------------

class HandoffChainTracker:
    """Discovers handoff artifacts and builds multi-session work chains."""

    HANDOFF_PATTERN = re.compile(r"handoff-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2})\.md$")

    def __init__(self, project_dir: str):
        self.project_dir = Path(project_dir)
        self.artifacts_dir = self.project_dir / ".claude" / "artifacts"

    def find_handoffs(self) -> list[dict]:
        """Return all handoff artifacts sorted by creation time."""
        if not self.artifacts_dir.is_dir():
            return []
        handoffs = []
        for f in self.artifacts_dir.glob("handoff-*.md"):
            match = self.HANDOFF_PATTERN.search(f.name)
            if not match:
                continue
            parsed = self._parse_handoff(f, match.group(1))
            if parsed:
                handoffs.append(parsed)
        handoffs.sort(key=lambda h: h["timestamp"])
        return handoffs

    def build_chain(self, session: dict, all_sessions: list[dict]) -> list[dict]:
        """Build a work chain: find sessions linked by handoff artifacts.

        A handoff artifact created during session A links to the next session B
        that starts after the handoff timestamp. We walk both directions from
        the given session.
        """
        handoffs = self.find_handoffs()
        if not handoffs:
            return [session]

        session_start = session.get("time", {}).get("created", 0)
        session_end = session.get("time", {}).get("updated", 0)

        # Index sessions by ID for quick lookup
        by_id = {s["id"]: s for s in all_sessions}

        # Find handoffs that fall within each session's time range
        # handoff.timestamp is a datetime; session times are ms timestamps
        session_handoffs: dict[str, list[dict]] = {}  # session_id -> [handoffs created during it]
        for ho in handoffs:
            ho_ms = ho["timestamp"].timestamp() * 1000
            for s in all_sessions:
                s_start = s.get("time", {}).get("created", 0)
                s_end = s.get("time", {}).get("updated", 0)
                if s_start <= ho_ms <= s_end:
                    session_handoffs.setdefault(s["id"], []).append(ho)
                    break

        # Walk the chain forward and backward from the current session
        chain_ids: set[str] = {session["id"]}
        queue = [session["id"]]
        visited: set[str] = set()

        while queue:
            current_id = queue.pop(0)
            if current_id in visited:
                continue
            visited.add(current_id)
            current = by_id.get(current_id)
            if not current:
                continue

            current_end = current.get("time", {}).get("updated", 0)

            # Forward: if this session has a handoff, find the next session that starts after it
            for ho in session_handoffs.get(current_id, []):
                ho_ms = ho["timestamp"].timestamp() * 1000
                # Find the session that starts closest after the handoff
                candidates = [
                    s for s in all_sessions
                    if s["id"] not in chain_ids
                    and s.get("time", {}).get("created", 0) > ho_ms
                ]
                if candidates:
                    candidates.sort(key=lambda s: s["time"]["created"])
                    next_session = candidates[0]
                    chain_ids.add(next_session["id"])
                    queue.append(next_session["id"])

            # Backward: if a handoff points to this session (handoff timestamp < session start)
            current_start = current.get("time", {}).get("created", 0)
            for sid, hos in session_handoffs.items():
                if sid in chain_ids:
                    continue
                for ho in hos:
                    ho_ms = ho["timestamp"].timestamp() * 1000
                    # If handoff was created before this session started (within 30 min)
                    if ho_ms < current_start and (current_start - ho_ms) < 30 * 60 * 1000:
                        chain_ids.add(sid)
                        queue.append(sid)

        # Return chain sorted by creation time
        chain = [by_id[sid] for sid in chain_ids if sid in by_id]
        chain.sort(key=lambda s: s.get("time", {}).get("created", 0))
        return chain

    def _parse_handoff(self, path: Path, date_str: str) -> Optional[dict]:
        """Parse a handoff markdown file with YAML frontmatter."""
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            return None

        # Parse timestamp from filename — make it timezone-aware using local tz
        try:
            timestamp = datetime.strptime(date_str, "%Y-%m-%d-%H-%M")
            local_tz = datetime.now(timezone.utc).astimezone().tzinfo
            timestamp = timestamp.replace(tzinfo=local_tz)
        except ValueError:
            return None

        result: dict = {
            "path": str(path),
            "timestamp": timestamp,
            "content": content,
            "branch": None,
            "commit": None,
            "beads_in_progress": [],
        }

        # Extract YAML frontmatter
        fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
        if fm_match:
            fm_text = fm_match.group(1)
            # Simple YAML parsing (no external deps)
            for line in fm_text.split("\n"):
                line = line.strip()
                if line.startswith("branch:"):
                    result["branch"] = line.split(":", 1)[1].strip().strip('"\'')
                elif line.startswith("commit:"):
                    result["commit"] = line.split(":", 1)[1].strip().strip('"\'')
                elif line.startswith("beads_in_progress:"):
                    val = line.split(":", 1)[1].strip()
                    # Parse [B-101, B-102] format
                    bead_match = re.findall(r"B-\d+", val)
                    result["beads_in_progress"] = bead_match

        return result


# ---------------------------------------------------------------------------
# ContentSanitizer — strips secrets from text before writing
# ---------------------------------------------------------------------------

class ContentSanitizer:
    """Detects and redacts secrets, tokens, and high-entropy strings."""

    # Compiled patterns: (regex, replacement label)
    PATTERNS: list[tuple[re.Pattern, str]] = [
        # OpenAI keys
        (re.compile(r"sk-[A-Za-z0-9_-]{20,}"), "[REDACTED:openai-key]"),
        # GitHub tokens
        (re.compile(r"ghp_[A-Za-z0-9]{36,}"), "[REDACTED:github-token]"),
        (re.compile(r"gho_[A-Za-z0-9]{36,}"), "[REDACTED:github-token]"),
        (re.compile(r"ghu_[A-Za-z0-9]{36,}"), "[REDACTED:github-token]"),
        (re.compile(r"ghs_[A-Za-z0-9]{36,}"), "[REDACTED:github-token]"),
        (re.compile(r"github_pat_[A-Za-z0-9_]{22,}"), "[REDACTED:github-token]"),
        # Bearer tokens
        (re.compile(r"Bearer\s+[A-Za-z0-9._\-/+=]{20,}"), "Bearer [REDACTED:token]"),
        # AWS keys
        (re.compile(r"AKIA[A-Z0-9]{16}"), "[REDACTED:aws-key]"),
        # Password fields in JSON/YAML-like content
        (re.compile(r'(["\']?password["\']?\s*[:=]\s*)["\'][^"\']{1,}["\']', re.IGNORECASE),
         r"\1[REDACTED:password]"),
        # API key fields
        (re.compile(r'(["\']?api[_-]?key["\']?\s*[:=]\s*)["\'][^"\']{1,}["\']', re.IGNORECASE),
         r"\1[REDACTED:api-key]"),
        # Secret fields
        (re.compile(r'(["\']?(?:client_)?secret["\']?\s*[:=]\s*)["\'][^"\']{1,}["\']', re.IGNORECASE),
         r"\1[REDACTED:secret]"),
        # Database/connection string URLs with embedded credentials
        (re.compile(r'(postgres(?:ql)?|mysql|mongodb(?:\+srv)?|redis|amqp)://[^\s"\'`,;>]+', re.IGNORECASE),
         r"[REDACTED:\1-connection-string]"),
        # .env style patterns: KEY=value where KEY contains secret-like words
        (re.compile(
            r'^([A-Z_]*(?:SECRET|TOKEN|PASSWORD|PASSWD|API_KEY|APIKEY|ACCESS_KEY|PRIVATE_KEY)[A-Z_]*)\s*=\s*(.+)$',
            re.IGNORECASE | re.MULTILINE,
        ), r"\1=[REDACTED:env-value]"),
    ]

    ENTROPY_MIN_LENGTH = 20
    ENTROPY_THRESHOLD = 4.5

    @classmethod
    def sanitize(cls, text: str) -> str:
        """Apply all sanitization rules to the given text."""
        if not text:
            return text
        for pattern, replacement in cls.PATTERNS:
            text = pattern.sub(replacement, text)
        text = cls._redact_high_entropy(text)
        return text

    @classmethod
    def _shannon_entropy(cls, s: str) -> float:
        """Calculate Shannon entropy in bits per character."""
        if not s:
            return 0.0
        freq: dict[str, int] = {}
        for ch in s:
            freq[ch] = freq.get(ch, 0) + 1
        length = len(s)
        entropy = 0.0
        for count in freq.values():
            p = count / length
            if p > 0:
                entropy -= p * math.log2(p)
        return entropy

    @classmethod
    def _redact_high_entropy(cls, text: str) -> str:
        """Find and redact high-entropy tokens that look like secrets."""
        # Match long alphanumeric+symbol tokens that could be secrets
        # Avoid matching common words, URLs, file paths
        token_pattern = re.compile(r'(?:^|(?<=["\':=\s]))[A-Za-z0-9+/=_\-]{20,}(?=["\'\s,;\n]|$)', re.MULTILINE)

        def check_token(match: re.Match) -> str:
            token = match.group(0)
            # Skip things that look like base64-encoded common content or file paths
            if token.startswith(("http", "file", "/Users", "/home", "/var", "/tmp")):
                return token
            # Skip if it's all lowercase or all uppercase (likely a normal identifier)
            if token.isalpha() and (token.islower() or token.isupper()):
                return token
            entropy = cls._shannon_entropy(token)
            if entropy > cls.ENTROPY_THRESHOLD:
                return "[REDACTED:high-entropy]"
            return token

        return token_pattern.sub(check_token, text)


# ---------------------------------------------------------------------------
# WorkChain — aggregated data for one or more linked sessions
# ---------------------------------------------------------------------------

class WorkChain:
    """Aggregated view of one or more linked sessions."""

    # URL pattern for extracting URLs from text
    _URL_PATTERN = re.compile(r"https?://[^\s\)\]\"'`,;>]+")
    _GITHUB_URL_PATTERN = re.compile(r"https?://github\.com/[^\s\)\]\"'`,;>]+")

    def __init__(self):
        self.sessions: list[dict] = []
        self.segments: list[dict] = []  # Each segment = {session, messages, parts_by_msg}

    @property
    def title(self) -> str:
        """Use the title of the first session, or its slug."""
        for seg in self.segments:
            t = seg["session"].get("title")
            if t:
                return t
        if self.sessions:
            return self.sessions[0].get("slug", "untitled")
        return "untitled"

    @property
    def start_time_ms(self) -> int:
        if not self.sessions:
            return 0
        return self.sessions[0].get("time", {}).get("created", 0)

    @property
    def end_time_ms(self) -> int:
        if not self.sessions:
            return 0
        return self.sessions[-1].get("time", {}).get("updated", 0)

    @property
    def total_cost(self) -> float:
        total = 0.0
        for seg in self.segments:
            for msg in seg["messages"]:
                total += msg.get("cost", 0) or 0
        return total

    @property
    def total_tokens(self) -> int:
        total = 0
        for seg in self.segments:
            for msg in seg["messages"]:
                tokens = msg.get("tokens", {})
                if isinstance(tokens, dict):
                    total += tokens.get("input", 0) + tokens.get("output", 0) + tokens.get("reasoning", 0)
                    cache = tokens.get("cache", {})
                    if isinstance(cache, dict):
                        total += cache.get("read", 0) + cache.get("write", 0)
        return total

    @property
    def total_messages(self) -> int:
        return sum(len(seg["messages"]) for seg in self.segments)

    @property
    def project_name(self) -> str:
        for seg in self.segments:
            d = seg["session"].get("directory", "")
            if d:
                return Path(d).name
        return "unknown"

    def user_prompts(self) -> list[dict]:
        """Extract user prompts with timestamps."""
        prompts = []
        for seg in self.segments:
            for msg in seg["messages"]:
                if msg.get("role") != "user":
                    continue
                parts = seg["parts_by_msg"].get(msg["id"], [])
                text_parts = [p for p in parts if p.get("type") == "text"]
                if text_parts:
                    text = " ".join(p.get("text", "") for p in text_parts)
                    created = msg.get("time", {}).get("created", 0)
                    prompts.append({"text": text, "time_ms": created})
        return prompts

    def tool_summary(self) -> dict:
        """Aggregate tool usage across all segments."""
        files_read: list[str] = []
        files_edited: list[str] = []
        commands_run: list[str] = []
        tasks_delegated: list[dict] = []
        github_urls: list[str] = []

        for seg in self.segments:
            for msg in seg["messages"]:
                parts = seg["parts_by_msg"].get(msg["id"], [])
                for part in parts:
                    if part.get("type") == "text":
                        text = part.get("text", "")
                        # Only extract GitHub URLs from user messages to avoid
                        # capturing example/illustrative URLs from assistant text
                        if msg.get("role") == "user":
                            github_urls.extend(self._extract_github_urls(text))
                    elif part.get("type") == "tool":
                        tool_name = part.get("tool", "")
                        state = part.get("state", {})
                        inp = state.get("input", {})

                        if tool_name == "read":
                            fp = inp.get("filePath") or inp.get("file_path") or ""
                            if fp:
                                files_read.append(fp)
                        elif tool_name in ("write", "edit"):
                            fp = inp.get("filePath") or inp.get("file_path") or ""
                            if fp:
                                files_edited.append(fp)
                        elif tool_name == "bash":
                            cmd = inp.get("command", "")
                            if cmd:
                                commands_run.append(cmd)
                        elif tool_name == "task":
                            desc = inp.get("description", "") or state.get("title", "")
                            agent = inp.get("subagent_type", "unknown")
                            if desc:
                                tasks_delegated.append({"description": desc, "agent": agent})

                        # Check tool output for GitHub URLs
                        output = state.get("output", "")
                        if isinstance(output, str):
                            github_urls.extend(self._extract_github_urls(output))

        return {
            "files_read": sorted(set(files_read)),
            "files_edited": sorted(set(files_edited)),
            "commands_run": commands_run,
            "tasks_delegated": tasks_delegated,
            "github_urls": sorted(set(github_urls)),
        }

    def extract_delegation_info(self) -> dict:
        """Extract per-agent delegation data with edit attribution.

        Captain edits are counted from all edit/write tool parts in the main
        session. Delegated agents get call counts only (their edits happen
        in separate subagent sessions we can't see from here).
        """
        agent_data: dict[str, dict] = {}
        captain_lines_added = 0
        captain_lines_removed = 0
        captain_files: set[str] = set()

        for seg in self.segments:
            for msg in seg["messages"]:
                if msg.get("role") != "assistant":
                    continue
                parts = seg["parts_by_msg"].get(msg["id"], [])
                for part in parts:
                    if part.get("type") != "tool":
                        continue

                    tool_name = part.get("tool", "")
                    state = part.get("state", {})
                    inp = state.get("input", {})

                    if tool_name == "task":
                        # Count delegation to subagent
                        agent = inp.get("subagent_type", "unknown")
                        if agent not in agent_data:
                            agent_data[agent] = {
                                "agent": agent,
                                "calls": 0,
                                "lines_added": None,
                                "lines_removed": None,
                                "files_edited": [],
                            }
                        agent_data[agent]["calls"] += 1

                    elif tool_name == "edit":
                        # Captain's edit — count lines
                        fp = inp.get("filePath") or inp.get("file_path") or ""
                        old_str = inp.get("oldString", "")
                        new_str = inp.get("newString", "")
                        old_lines = old_str.count("\n") + 1 if old_str else 0
                        new_lines = new_str.count("\n") + 1 if new_str else 0
                        captain_lines_added += new_lines
                        captain_lines_removed += old_lines
                        if fp:
                            captain_files.add(fp)

                    elif tool_name == "write":
                        # Captain's write — count lines added
                        fp = inp.get("filePath") or inp.get("file_path") or ""
                        content = inp.get("content", "")
                        if content:
                            captain_lines_added += content.count("\n") + 1
                        if fp:
                            captain_files.add(fp)

                    elif tool_name == "apply_patch":
                        # Captain's patch — count lines from diff hunks
                        patch = inp.get("patch", "") or inp.get("diff", "") or ""
                        for line in patch.split("\n"):
                            if line.startswith("+") and not line.startswith("+++"):
                                captain_lines_added += 1
                            elif line.startswith("-") and not line.startswith("---"):
                                captain_lines_removed += 1
                        # Extract file paths from diff headers
                        for match in re.finditer(r"^(?:\+\+\+|---)\s+[ab]/(.+)$", patch, re.MULTILINE):
                            captain_files.add(match.group(1))

        # Build the agents list, captain first
        agents = [
            {
                "agent": "captain",
                "calls": 0,  # captain doesn't get "called"
                "lines_added": captain_lines_added,
                "lines_removed": captain_lines_removed,
                "files_edited": sorted(captain_files),
            }
        ]

        # Add delegated agents sorted by call count descending
        for agent_info in sorted(agent_data.values(), key=lambda a: a["calls"], reverse=True):
            agents.append(agent_info)

        return {
            "agents": agents,
            "critic_called": "critic" in agent_data,
            "architect_called": "architect" in agent_data,
        }

    def extract_research_urls(self) -> dict:
        """Extract URLs from webfetch tool calls and librarian delegations."""
        librarian_sources: list[dict] = []

        for seg in self.segments:
            for msg in seg["messages"]:
                if msg.get("role") != "assistant":
                    continue
                parts = seg["parts_by_msg"].get(msg["id"], [])
                for part in parts:
                    if part.get("type") != "tool":
                        continue

                    tool_name = part.get("tool", "")
                    state = part.get("state", {})
                    inp = state.get("input", {})

                    if tool_name == "task" and inp.get("subagent_type") == "librarian":
                        # Extract context from the task description/prompt
                        context = inp.get("description", "") or inp.get("prompt", "") or ""
                        # Extract URLs from the task output
                        output = state.get("output", "")
                        if isinstance(output, str):
                            urls = self._URL_PATTERN.findall(output)
                            for url in urls:
                                librarian_sources.append({
                                    "url": url,
                                    "context": context[:200] if context else "",
                                })

                    elif tool_name == "webfetch":
                        url = inp.get("url", "")
                        # Use the description or surrounding context
                        context = inp.get("description", "") or ""
                        if url:
                            librarian_sources.append({
                                "url": url,
                                "context": context[:200] if context else "",
                            })

        return {
            "librarian_sources": librarian_sources,
        }

    def extract_github_urls(self) -> dict:
        """Extract GitHub URLs split into issues vs PRs."""
        tools = self.tool_summary()
        all_urls = tools["github_urls"]

        issues: list[str] = []
        pull_requests: list[str] = []

        for url in all_urls:
            if "/issues/" in url:
                issues.append(url)
            elif "/pull/" in url:
                pull_requests.append(url)

        return {
            "issues": sorted(set(issues)),
            "pull_requests": sorted(set(pull_requests)),
        }

    def extract_token_usage(self) -> dict:
        """Extract detailed token usage and cost breakdown."""
        total_usd = 0.0
        input_tokens = 0
        output_tokens = 0
        cache_read_tokens = 0
        cache_write_tokens = 0

        for seg in self.segments:
            for msg in seg["messages"]:
                total_usd += msg.get("cost", 0) or 0
                tokens = msg.get("tokens", {})
                if isinstance(tokens, dict):
                    input_tokens += tokens.get("input", 0)
                    output_tokens += tokens.get("output", 0) + tokens.get("reasoning", 0)
                    cache = tokens.get("cache", {})
                    if isinstance(cache, dict):
                        cache_read_tokens += cache.get("read", 0)
                        cache_write_tokens += cache.get("write", 0)

        return {
            "total_usd": round(total_usd, 4),
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cache_read_tokens": cache_read_tokens,
            "cache_write_tokens": cache_write_tokens,
        }

    def extract_project_info(self) -> dict:
        """Extract project repository information.

        Uses the session directory field and handoff data for branch info.
        """
        repositories: list[dict] = []
        seen_paths: set[str] = set()

        for seg in self.segments:
            directory = seg["session"].get("directory", "")
            if directory and directory not in seen_paths:
                seen_paths.add(directory)
                repo_name = Path(directory).name
                # Try to find branch from handoff data in the chain
                branch = self._find_branch_for_directory(directory)
                repositories.append({
                    "path": directory,
                    "name": repo_name,
                    "branch": branch,
                })

        return {
            "repositories": repositories,
        }

    def _find_branch_for_directory(self, directory: str) -> Optional[str]:
        """Try to find a git branch name from session or handoff data."""
        # Check if any session has branch info directly
        for seg in self.segments:
            sess = seg["session"]
            branch = sess.get("branch")
            if branch:
                return branch

        # Check bash commands for git branch indicators
        for seg in self.segments:
            for msg in seg["messages"]:
                parts = seg["parts_by_msg"].get(msg["id"], [])
                for part in parts:
                    if part.get("type") != "tool" or part.get("tool") != "bash":
                        continue
                    state = part.get("state", {})
                    cmd = state.get("input", {}).get("command", "")
                    output = state.get("output", "")
                    # Look for "git checkout -b <branch>" or "git switch -c <branch>"
                    branch_match = re.search(
                        r"git\s+(?:checkout\s+-b|switch\s+-c)\s+(\S+)", cmd
                    )
                    if branch_match:
                        return branch_match.group(1)
                    # Look for "On branch <name>" in git status output
                    if isinstance(output, str):
                        on_branch = re.search(r"On branch\s+(\S+)", output)
                        if on_branch:
                            return on_branch.group(1)

        return None

    @staticmethod
    def _extract_github_urls(text: str) -> list[str]:
        """Extract GitHub URLs from text."""
        pattern = re.compile(r"https?://github\.com/[^\s\)\]\"'`,;>]+")
        return pattern.findall(text)


# ---------------------------------------------------------------------------
# Metadata extraction
# ---------------------------------------------------------------------------

def extract_session_metadata(chain: WorkChain) -> dict:
    """Extract all metadata from a WorkChain and return as JSON-serializable dict."""
    return {
        "session": {
            "id": chain.sessions[0]["id"] if chain.sessions else "unknown",
            "title": chain.title,
            "start_time": ms_to_datetime(chain.start_time_ms).isoformat() if chain.start_time_ms else None,
            "end_time": ms_to_datetime(chain.end_time_ms).isoformat() if chain.end_time_ms else None,
            "duration_seconds": max(0, (chain.end_time_ms - chain.start_time_ms)) // 1000 if chain.start_time_ms and chain.end_time_ms else 0,
            "duration_human": format_duration(chain.start_time_ms, chain.end_time_ms) if chain.start_time_ms and chain.end_time_ms else None,
        },
        "cost": chain.extract_token_usage(),
        "project": chain.extract_project_info(),
        "github": chain.extract_github_urls(),
        "delegation": chain.extract_delegation_info(),
        "research": chain.extract_research_urls(),
        "tools": chain.tool_summary(),
        "prompts": [
            {
                "text": p["text"],
                "time": ms_to_datetime(p["time_ms"]).isoformat() if p["time_ms"] else None,
            }
            for p in chain.user_prompts()
        ],
        "work_chain": {
            "session_count": len(chain.sessions),
            "sessions": [s["id"] for s in chain.sessions],
        },
    }


# ---------------------------------------------------------------------------
# Main orchestration
# ---------------------------------------------------------------------------

def build_work_chain(
    session_id: str,
    project_hash: str,
    storage: OpenCodeStorage,
    project_dir: Optional[str] = None,
    follow_chain: bool = False,
) -> WorkChain:
    """Load session data and build a WorkChain."""
    session = storage.read_session(session_id, project_hash)
    if not session:
        print(f"Error: Session {session_id} not found for project {project_hash}", file=sys.stderr)
        sys.exit(1)

    # Determine which sessions to include
    if follow_chain and project_dir:
        all_sessions = storage.find_sessions(project_hash)
        tracker = HandoffChainTracker(project_dir)
        sessions = tracker.build_chain(session, all_sessions)
    else:
        sessions = [session]

    chain = WorkChain()
    chain.sessions = sessions

    for sess in sessions:
        messages = storage.read_messages(sess["id"])
        parts_by_msg: dict[str, list[dict]] = {}
        for msg in messages:
            msg_id = msg.get("id")
            if not msg_id:
                continue
            parts_by_msg[msg_id] = storage.read_parts(msg_id)
        chain.segments.append({
            "session": sess,
            "messages": [m for m in messages if m.get("id")],
            "parts_by_msg": parts_by_msg,
        })

    return chain


def main():
    parser = argparse.ArgumentParser(
        description="Extract session metadata as JSON from OpenCode sessions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("session_id", help="OpenCode session ID (e.g. ses_3b20ac5f...)")
    parser.add_argument("project_hash", help="Project hash (directory hash)")
    parser.add_argument("--project-dir", help="Project directory for handoff tracking")
    parser.add_argument("--chain", action="store_true", help="Follow handoff chain for related sessions")
    parser.add_argument("--storage-root", help="Override OpenCode storage root directory (legacy JSON)")
    parser.add_argument("--db-path", help="Override OpenCode SQLite database path")

    args = parser.parse_args()

    storage = OpenCodeStorage(storage_root=args.storage_root, db_path=args.db_path)
    chain = build_work_chain(
        session_id=args.session_id,
        project_hash=args.project_hash,
        storage=storage,
        project_dir=args.project_dir,
        follow_chain=args.chain,
    )

    metadata = extract_session_metadata(chain)

    # Sanitize the entire JSON output
    output = json.dumps(metadata, indent=2, default=str)
    output = ContentSanitizer.sanitize(output)
    print(output)


if __name__ == "__main__":
    main()
