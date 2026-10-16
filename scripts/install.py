#!/usr/bin/env python3
"""Copy selected, self-contained skills without replacing existing installations."""

import argparse
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def install(source, destination, names, dry_run=False):
    source = Path(source).resolve()
    destination = Path(destination).expanduser().resolve()
    available = {p.name: p for p in source.iterdir() if p.is_dir()}
    selected = list(dict.fromkeys(names))
    if not selected:
        raise ValueError("Select at least one skill, or use --all.")
    for name in selected:
        if name not in available:
            raise ValueError(f"Unknown skill: {name}")
        folder = available[name]
        if folder.is_symlink() or not (folder / "SKILL.md").is_file():
            raise ValueError(f"Invalid skill folder: {name}")
        if any(p.is_symlink() for p in folder.rglob("*")):
            raise ValueError(f"Skill contains a symlink: {name}")
        if destination == folder or folder in destination.parents:
            raise ValueError("The destination must be outside the source skill folders.")
        target = destination / name
        if target.exists() or target.is_symlink():
            raise FileExistsError(f"Already exists: {target}. Back it up or choose another destination.")
    targets = [destination / name for name in selected]
    if dry_run:
        return targets
    destination.mkdir(parents=True, exist_ok=True)
    created = []
    try:
        for name, target in zip(selected, targets):
            # Reserve the name before copying; never merge with an existing folder.
            target.mkdir()
            created.append(target)
            shutil.copytree(available[name], target, dirs_exist_ok=True)
    except Exception:
        for target in reversed(created):
            shutil.rmtree(target)
        raise
    return targets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skills", nargs="*", help="Skill folder names to install")
    parser.add_argument("--all", action="store_true", help="Install every skill")
    parser.add_argument("--list", action="store_true", help="List available skills and exit")
    parser.add_argument("--dest", type=Path, default=Path.home() / ".agents" / "skills",
                        help="Destination skill directory (default: ~/.agents/skills)")
    parser.add_argument("--dry-run", action="store_true", help="Show destinations without writing")
    args = parser.parse_args()
    source = ROOT / "skills"
    available = sorted(p.name for p in source.iterdir() if (p / "SKILL.md").is_file())
    if args.list:
        print("\n".join(available))
        return 0
    if args.all and args.skills:
        parser.error("Choose skill names or --all, not both.")
    try:
        targets = install(source, args.dest, available if args.all else args.skills, args.dry_run)
    except (OSError, ValueError) as error:
        print(f"Install failed: {error}", file=sys.stderr)
        return 1
    for target in targets:
        print(f"{'Would install' if args.dry_run else 'Installed'}: {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
