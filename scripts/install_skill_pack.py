#!/usr/bin/env python3
"""Install the math-skill-dp skill pack to the Codex skills directory.

Usage:
    # Install all skills (main + 3 sub-skills)
    python install_skill_pack.py

    # Force reinstall (overwrite existing)
    python install_skill_pack.py --force

    # Clean update (remove old before installing)
    python install_skill_pack.py --force --clean-update

    # Specify custom install directory
    python install_skill_pack.py --skills-dir ~/.codex/skills
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


SKILLS = [
    {
        "name": "math-skill-dp",
        "source": ".",  # root of this repo
        "description": "Main solver skill — end-to-end modeling workflow",
    },
    {
        "name": "audit-modeling-evidence",
        "source": "audit-modeling-evidence",
        "description": "Evidence audit skill — data, experiments, claims",
    },
    {
        "name": "build-modeling-figures",
        "source": "build-modeling-figures",
        "description": "Figure building skill — charts, diagrams, QA",
    },
    {
        "name": "deliver-cumcm-paper",
        "source": "deliver-cumcm-paper",
        "description": "CUMCM paper delivery skill — LaTeX, compile, audit",
    },
]

IGNORE_PATTERNS = shutil.ignore_patterns(
    ".git",
    "__pycache__",
    "*.pyc",
    "*.pyo",
    ".DS_Store",
    "Thumbs.db",
    "node_modules",
    ".gitattributes",
    ".gitignore",
    ".skill-watermark.json",
)


def get_repo_root() -> Path:
    """Find the repository root (where this script or SKILL.md lives)."""
    script_dir = Path(__file__).resolve().parent.parent
    if (script_dir / "SKILL.md").exists():
        return script_dir
    cwd = Path.cwd()
    if (cwd / "SKILL.md").exists():
        return cwd
    raise SystemExit(
        "Cannot find repository root. Run this script from the math-skill-dp "
        "repository directory."
    )


def install_skill(
    repo_root: Path,
    skills_dir: Path,
    skill_info: dict,
    force: bool = False,
) -> bool:
    """Install a single skill. Returns True if installed successfully."""
    name = skill_info["name"]
    source = repo_root / skill_info["source"]
    dest = skills_dir / name

    if not source.exists():
        print(f"  SKIP {name}: source not found at {source}")
        return False

    if dest.exists():
        if not force:
            print(f"  SKIP {name}: already exists (use --force to overwrite)")
            return False
        print(f"  CLEAN {name}: removing existing installation")
        shutil.rmtree(dest)

    print(f"  INSTALL {name}: {skill_info['description']}")

    if source == repo_root:
        # Main skill: copy everything except sub-skill dirs
        dest.mkdir(parents=True, exist_ok=True)
        for item in source.iterdir():
            if item.name.startswith(".") and item.name != ".skill-watermark.json":
                continue
            if item.name in {"audit-modeling-evidence", "build-modeling-figures",
                             "deliver-cumcm-paper"}:
                continue  # sub-skills are installed separately
            if item.is_dir():
                shutil.copytree(item, dest / item.name, dirs_exist_ok=True,
                                ignore=IGNORE_PATTERNS)
            else:
                shutil.copy2(item, dest / item.name)
    else:
        # Sub-skill: copy the directory
        shutil.copytree(source, dest, dirs_exist_ok=True, ignore=IGNORE_PATTERNS)

    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install the math-skill-dp skill pack to Codex skills directory."
    )
    parser.add_argument(
        "--skills-dir",
        type=Path,
        default=None,
        help="Codex skills directory (default: ~/.codex/skills or $HOME\\.codex\\skills)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing skill installations",
    )
    parser.add_argument(
        "--clean-update",
        action="store_true",
        help="Remove old skill directories before installing (implies --force)",
    )
    args = parser.parse_args()

    # Resolve skills directory
    if args.skills_dir:
        skills_dir = args.skills_dir.expanduser().resolve()
    else:
        home = Path.home()
        skills_dir = home / ".codex" / "skills"

    force = args.force or args.clean_update

    repo_root = get_repo_root()
    print(f"Repository: {repo_root}")
    print(f"Skills dir: {skills_dir}")
    print()

    if args.clean_update:
        print("Clean update mode: removing old installations first.")
        for skill in SKILLS:
            old = skills_dir / skill["name"]
            if old.exists():
                print(f"  REMOVE {skill['name']}")
                shutil.rmtree(old)
        print()

    skills_dir.mkdir(parents=True, exist_ok=True)

    installed = 0
    for skill in SKILLS:
        if install_skill(repo_root, skills_dir, skill, force=force):
            installed += 1

    print(f"\nDone: {installed}/{len(SKILLS)} skills installed to {skills_dir}")
    print("Restart your Codex session to use: $math-skill-dp")
    return 0 if installed > 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
