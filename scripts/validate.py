#!/usr/bin/env python3
"""Check skill metadata and local reference closure; no network or writes."""

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml

ROOT = Path(__file__).resolve().parents[1]


def validate(root=ROOT):
    errors = []
    folders = sorted(p for p in (root / "skills").iterdir() if p.is_dir())
    if not folders:
        return ["No skills found"], 0

    def report(path, message):
        errors.append(f"{path.relative_to(root)}: {message}")

    root_license = (root / "LICENSE").read_text(encoding="utf-8")
    for folder in folders:
        entry = folder / "SKILL.md"
        if folder.is_symlink():
            report(folder, "symlinks are not portable bundled resources")
            continue
        if not entry.is_file() or entry.is_symlink():
            report(folder, "missing regular SKILL.md")
            continue
        license_path = folder / "LICENSE"
        if not license_path.is_file() or license_path.is_symlink() or license_path.read_text(encoding="utf-8") != root_license:
            report(folder, "LICENSE must match the root MIT notice")
        text = entry.read_text(encoding="utf-8")
        match = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
        if not match:
            report(entry, "missing YAML frontmatter")
            continue
        try:
            meta = yaml.safe_load(match.group(1))
        except yaml.YAMLError as error:
            report(entry, f"invalid YAML: {error}")
            continue
        if not isinstance(meta, dict):
            report(entry, "frontmatter must be a mapping")
            continue
        name = meta.get("name")
        if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) or len(name) > 64:
            report(entry, "invalid skill name")
        elif name != folder.name:
            report(entry, "name must match its directory")
        description = meta.get("description")
        if not isinstance(description, str) or not 1 <= len(description.strip()) <= 1024:
            report(entry, "description must contain 1–1024 characters")
        if meta.get("license") != "MIT":
            report(entry, "license metadata must be MIT")

        for path in sorted(folder.rglob("*")):
            if path.is_symlink():
                report(path, "symlinks are not portable bundled resources")
                continue
            if not path.is_file() or path.suffix != ".md":
                continue
            contents = path.read_text(encoding="utf-8")
            targets = [(path.parent, target.strip("<>")) for target in re.findall(r"\[[^\]]*\]\(([^\s)]+)\)", contents)]
            # Backticked references in these skills are relative to the skill root.
            targets += [(folder, target) for target in re.findall(r"`((?:references|scripts|assets)/[^`\n]+\.(?:md|py|swift|metal|json|yaml))`", contents)]
            for base, target in targets:
                parts = urlsplit(target)
                if parts.scheme or parts.netloc or not parts.path:
                    continue
                resolved = (base / unquote(parts.path)).resolve()
                if not resolved.is_relative_to(folder.resolve()):
                    report(path, f"reference leaves standalone skill: {target}")
                elif not resolved.exists():
                    report(path, f"missing reference: {target}")
    return errors, len(folders)


if __name__ == "__main__":
    errors, count = validate()
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print(f"PASS: {count} skills; metadata, license notices, directory names, and local references checked.")
    print("Swift compilation, runtime behavior, external links, and technical claims were not validated.")
