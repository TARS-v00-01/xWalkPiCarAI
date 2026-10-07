#!/usr/bin/env python3
"""Check the deliberately small public source boundary and rendered publication for common leaks.

This supplements human content review; pattern checks cannot establish that arbitrary prose is public.
Only the chapter source directory is passed to MkDocs. Never point the build at developer-note artifacts.
"""

from pathlib import Path
import ipaddress
import hashlib
import json
from urllib.parse import urlsplit, unquote
import re
import sys


CHAPTERS = (
    "01-xwalk-workspace", "02-xwalk-hardware", "03-xwalk-interface", "04-xwalk-software",
    "05-xwalk-node", "06-xwalk-tool", "07-xwalk-trace", "08-xwalk-guides",
)
PUBLIC_URLS = {
    "https://github.com/TARS-v00-01/xWalkPiCarApp",
    "https://github.com/TARS-v00-01/xWalkPiCarAI",
    "https://github.com/TARS-v00-01/xWalkPiCarAI.git",
}
PUBLIC_HOSTS = {
    "alphacephei.com", "docs.gtk.org", "docs.hivemq.com", "docs.kernel.org", "docs.opencv.org",
    "docs.sunfounder.com", "eclipse.dev", "www.destinationhalmstad.se", "api.openai.com",
    "dashscope-intl.aliyuncs.com", "provider.example", "example.invalid", "127.0.0.1", "localhost", "::1",
}
FORBIDDEN = re.compile(
    r"(?:/home/|/Users/|file://|ssh://|\.atlassian\.net|\.internal\b|\.lan\b|"
    r"BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|"
    r"AKIA[A-Z0-9]{16}|[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}|"
    r"(?:password|token|api_key)\s*[=:]\s*['\"][^'\"]+['\"])",
    re.IGNORECASE,
)


def check_text(path: Path, text: str) -> None:
    """Reject recognizable sensitive markers without printing the matched value."""
    if FORBIDDEN.search(text):
        raise ValueError(f"Possible private data in {path.name}; review locally before publication")
    for address in re.findall(r"(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])", text):
        try:
            parsed = ipaddress.ip_address(address)
        except ValueError:
            continue
        documentation_address = any(parsed in ipaddress.ip_network(network) for network in
                                    ("192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24"))
        if not parsed.is_global and not documentation_address and address not in {
            "127.0.0.1", "127.0.1.1", "0.0.0.0",
        }:
            raise ValueError(f"Non-public network address in {path.name}")


def verify(root: Path, site: Path | None = None) -> None:
    """Require the reviewed chapter set and check its content and optional rendered output."""
    source = root / "chapters"
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    expected = set(manifest)
    required = {"index.md", *(f"{chapter}/index.md" for chapter in CHAPTERS)}
    if not required <= expected:
        raise ValueError("Public manifest must contain the homepage and all eight chapter indexes")
    entries = list(source.rglob("*"))
    if any(path.is_symlink() for path in entries) or source.is_symlink():
        raise ValueError("Public documentation must not contain symbolic links")
    actual = {path.relative_to(source).as_posix() for path in entries if path.is_file()}
    if actual != expected:
        raise ValueError("Public source manifest changed; review and update the explicit chapter allowlist")
    for name in sorted(expected):
        path = source / name
        if hashlib.sha256(path.read_bytes()).hexdigest() != manifest[name]:
            raise ValueError(f"Public content changed without updating its reviewed manifest: {name}")
        if path.suffix not in {".md", ".png", ".jpg"}:
            raise ValueError(f"Unsupported public source file: {name}")
        if path.suffix != ".md":
            continue
        text = path.read_text(encoding="utf-8")
        check_text(path, text)
        urls = re.findall(r"https?://[^\s)<>\"'`]+", text)
        for value in urls:
            url = urlsplit(value)
            approved = value in PUBLIC_URLS or url.hostname in PUBLIC_HOSTS
            approved = approved or (url.hostname == "github.com" and url.path.startswith("/hailo-ai/"))
            if not approved or url.username or url.password:
                raise ValueError(f"Unapproved external link in {name}: {url.hostname}")
        prose = re.sub(r"```.*?```|`[^`]*`", "", text, flags=re.DOTALL)
        if re.search(r"<\s*(?:script|iframe|img|object|embed)\b", prose, re.IGNORECASE):
            raise ValueError(f"Embedded external content is not allowed in {name}")
    if site is not None:
        required = []
        for name in sorted(expected):
            if name.endswith("/index.md") or name == "index.md":
                required.append(site / name.replace(".md", ".html"))
            elif name.endswith(".md"):
                required.append(site / name.removesuffix(".md") / "index.html")
            else:
                required.append(site / name)
        required.append(site / "search/search_index.json")
        if any(not path.is_file() for path in required):
            raise ValueError("Rendered site is missing a chapter or search index")
        for path in site.rglob("*"):
            if path.is_symlink():
                raise ValueError("Rendered site must not contain symbolic links")
            if path.is_file() and path.suffix in {".html", ".json", ".xml"}:
                check_text(path, path.read_text(encoding="utf-8"))
    print("Public chapter boundary and privacy checks passed")


if __name__ == "__main__":
    verify(Path(__file__).resolve().parent, Path(sys.argv[1]) if len(sys.argv) == 2 else None)
