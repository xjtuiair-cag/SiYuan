#!/usr/bin/env python3
"""Expand a VCS-style -f filelist into absolute source paths."""

from __future__ import annotations

import argparse
import os
import sys


def expand_vc(path: str, seen: set[str] | None = None) -> list[str]:
    seen = seen if seen is not None else set()
    path = os.path.abspath(os.path.expandvars(path))
    if path in seen:
        return []
    if not os.path.isfile(path):
        raise FileNotFoundError(f"filelist not found: {path}")
    seen.add(path)

    files: list[str] = []
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue
            line = os.path.expandvars(line)
            if line.startswith("-f"):
                nested = line[2:].strip()
                if not nested:
                    raise ValueError(f"empty -f entry in {path}")
                files.extend(expand_vc(nested, seen))
            else:
                files.append(os.path.abspath(line))
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filelist", help="Top-level .vc filelist")
    parser.add_argument(
        "-o",
        "--output",
        help="Optional output file (default: stdout)",
    )
    parser.add_argument(
        "--tcl",
        action="store_true",
        help="Emit Vivado read_verilog -sv commands instead of a plain list",
    )
    parser.add_argument(
        "--extra",
        action="append",
        default=[],
        help="Extra source files to append (repeatable)",
    )
    args = parser.parse_args()

    files = expand_vc(args.filelist)
    for extra in args.extra:
        files.append(os.path.abspath(os.path.expandvars(extra)))

    # Preserve order, drop duplicates
    uniq: list[str] = []
    seen_files: set[str] = set()
    for f in files:
        if f not in seen_files:
            uniq.append(f)
            seen_files.add(f)

    if args.tcl:
        lines = [f"read_verilog -sv {{{f}}}" for f in uniq]
        text = "\n".join(lines) + ("\n" if lines else "")
    else:
        text = "\n".join(uniq) + ("\n" if uniq else "")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
