#!/usr/bin/env python3
"""Generate de/inc/sy_soc_pkg.sv from a SoC YAML config (e.g. config/1_core.yaml)."""

import argparse
import os
import re
import sys

import yaml

# YAML key -> SystemVerilog parameter prefix (XxxBase / XxxLength)
NAME_MAP = {
    "DEBUG": "DBG",
    "DBG": "DBG",
    "DRAM": "DRAM",
    "PLIC": "PLIC",
    "CLINT": "CLINT",
    "UART": "UART",
    "Uart": "UART",
    "DMA": "DMA",
    "REGMAP": "REGMAP",
    "SD": "SD",
    "BOOTROM": "BOOTROM",
}

# Emission order matching de/inc/sy_soc_pkg.sv
PERIPH_ORDER = [
    "DBG",
    "DRAM",
    "PLIC",
    "CLINT",
    "UART",
    "DMA",
    "REGMAP",
    "SD",
    "BOOTROM",
]

ADDR_WIDTH = 64
SKIP_KEYS = {"Core_num", "core_num", "CORE_NUM"}


def to_sv_hex(val, width=ADDR_WIDTH):
    """Format integer as SystemVerilog hex literal with '_' every 4 digits."""
    if val == 0:
        return f"{width}'h0000_0000"
    hex_str = f"{val:X}"
    groups = []
    while hex_str:
        groups.append(hex_str[-4:])
        hex_str = hex_str[:-4]
    return f"{width}'h{'_'.join(reversed(groups))}"


def _normalize_key(key):
    return re.sub(r"[\s_\-]+", "", str(key).lower())


def parse_periph_fields(raw):
    """
    Accept either:
      base addr: 0x...
      length: 0x...
    or list form:
      - base addr: 0x...
      - length: 0x...
    Also tolerate legacy keys like '-base addr' / '-length'.
    """
    fields = {}
    if isinstance(raw, dict):
        items = raw.items()
    elif isinstance(raw, list):
        items = []
        for entry in raw:
            if isinstance(entry, dict):
                items.extend(entry.items())
            else:
                raise ValueError(f"Unexpected peripheral list entry: {entry!r}")
    elif raw is True:
        raise ValueError("Peripheral enabled without base addr / length")
    elif raw is False or raw is None:
        return None
    else:
        raise ValueError(f"Unsupported peripheral value: {raw!r}")

    for key, val in items:
        nk = _normalize_key(key)
        if nk in ("baseaddr", "base", "addr", "start"):
            fields["base"] = int(val)
        elif nk in ("length", "len", "size"):
            fields["length"] = int(val)

    if "base" not in fields or "length" not in fields:
        raise ValueError(f"Missing base addr / length in {raw!r}")
    return fields


def collect_peripherals(cfg):
    periphs = {}
    for key, raw in cfg.items():
        if key in SKIP_KEYS:
            continue
        sv_name = NAME_MAP.get(key, key.upper())
        fields = parse_periph_fields(raw)
        if fields is None:
            continue
        periphs[sv_name] = fields
    return periphs


def generate_sv(cfg):
    if "Core_num" in cfg:
        core_num = cfg["Core_num"]
    elif "core" in cfg and isinstance(cfg["core"], dict):
        core_num = cfg["core"]["num"]
    else:
        raise KeyError("Core_num not found in config")

    periphs = collect_peripherals(cfg)

    lines = []
    sep = "//" + "-" * 118
    lines.append("// Auto Generated, don't modify!!!")
    lines.append("package sy_soc_pkg;")
    lines.append(sep)
    lines.append("// SOC parameters")
    lines.append(sep)
    lines.append(f"parameter integer CORE_NUM = {core_num};")
    lines.append("")

    # Prefer fixed order, then any extra peripherals from YAML
    ordered = [n for n in PERIPH_ORDER if n in periphs]
    extras = [n for n in periphs if n not in PERIPH_ORDER]
    name_width = max(len(n) for n in ordered + extras)
    for name in ordered + extras:
        info = periphs[name]
        pad = " " * (name_width - len(name))
        lines.append(f"parameter {name}Base{pad}   = {to_sv_hex(info['base'])};")
        lines.append(f"parameter {name}Length{pad} = {to_sv_hex(info['length'])};")

    lines.append("")
    lines.append(f"parameter ReservedBase   = {{{ADDR_WIDTH}{{1'b1}}}};")
    lines.append("parameter ReservedLength = 1;")
    lines.append("")
    lines.append("endpackage")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate sy_soc_pkg.sv from SoC YAML config"
    )
    parser.add_argument("-f", "--file_path", required=True, help="config YAML path")
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="output SystemVerilog path (default: <repo>/de/inc/sy_soc_pkg.sv)",
    )
    args = parser.parse_args()

    with open(args.file_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    sv = generate_sv(cfg)

    if args.output:
        out_path = args.output
    else:
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
        out_path = os.path.join(repo_root, "de", "inc", "sy_soc_pkg.sv")

    os.makedirs(os.path.dirname(os.path.abspath(out_path)) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(sv)

    print(f"Generated {out_path}")


if __name__ == "__main__":
    main()
