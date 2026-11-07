#!/usr/bin/env python3
"""Generate device tree from SoC YAML config (e.g. config/2_cores.yaml).

Output style follows the reference FPGA DTS (sy.dts): 32.768 kHz timebase,
ns16750 UART, hipu DMA nodes, etc.
"""

import argparse
import os

import yaml

from gen_soc_pkg import collect_peripherals


def split64(val):
    """Split a 64-bit value into (high32, low32) for DT reg cells."""
    return (val >> 32) & 0xFFFFFFFF, val & 0xFFFFFFFF


def fmt_hex(val):
    return f"0x{val:x}"


def reg_cells(base, length):
    bh, bl = split64(base)
    lh, ll = split64(length)
    return f"<{fmt_hex(bh)} {fmt_hex(bl)} {fmt_hex(lh)} {fmt_hex(ll)}>"


def unit_addr(base):
    """Unit-address for node name (lower significant hex, no leading zeros)."""
    return f"{base:x}"


def get_periph(periphs, *names):
    for name in names:
        if name in periphs:
            return periphs[name]
    return None


def generate_dts(cfg):
    core_num = cfg["Core_num"]
    periphs = collect_peripherals(cfg)

    dram = get_periph(periphs, "DRAM")
    clint = get_periph(periphs, "CLINT")
    plic = get_periph(periphs, "PLIC")
    debug = get_periph(periphs, "DBG", "DEBUG")
    uart = get_periph(periphs, "UART")
    dma = get_periph(periphs, "DMA")
    sd = get_periph(periphs, "SD")
    regmap = get_periph(periphs, "REGMAP")
    gpio = get_periph(periphs, "GPIO")
    npu = get_periph(periphs, "NPU")
    eth = get_periph(periphs, "ETHERNET", "Ethernet", "ETH")
    spi = get_periph(periphs, "SPI")

    lines = []
    lines.append("/dts-v1/;")
    lines.append("/ {")
    lines.append("    #address-cells = <2>;")
    lines.append("    #size-cells = <2>;")
    lines.append('    compatible = "cag,sy-bare-dev";')
    lines.append('    model = "cag,sy-bare";')

    if uart:
        # Match Linux stdout node path to the uart@<addr> node below.
        lines.append("    chosen {")
        lines.append(
            f'      stdout-path = "/soc/uart@{unit_addr(uart["base"])}:115200";'
        )
        lines.append("    };")
    lines.append("")

    # CPUs — timebase matches reference FPGA DTS (RTC / CLINT tick).
    lines.append("    cpus {")
    lines.append("        #address-cells = <1>;")
    lines.append("        #size-cells = <0>;")
    lines.append("        timebase-frequency = <32768>; // 32.768KHz")
    lines.append("               ")
    for i in range(core_num):
        lines.append(f"        cpu{i}: cpu@{i} {{")
        lines.append("          clock-frequency = <50000000>; // 50 MHz")
        lines.append('          device_type = "cpu";')
        lines.append(f"          reg = <{i}>;")
        lines.append('          status = "okay";')
        lines.append('          compatible = "cag, sy", "riscv";')
        lines.append('          riscv,isa = "rv64imafdc";')
        lines.append('          mmu-type = "riscv,sv39";')
        lines.append("          tlb-split;")
        lines.append("          // HLIC - hart local interrupt controller")
        lines.append(f"          CPU{i}_intc: interrupt-controller {{")
        lines.append("            #interrupt-cells = <1>;")
        lines.append("            interrupt-controller;")
        lines.append('            compatible = "riscv,cpu-intc";')
        lines.append("          };")
        lines.append("        };")
        if i != core_num - 1:
            lines.append("           ")
    lines.append("    };")
    lines.append("           ")

    # Memory (DRAM)
    if dram:
        lines.append(f"    memory@{unit_addr(dram['base'])} {{")
        lines.append('      device_type = "memory";')
        lines.append(f"      reg = {reg_cells(dram['base'], dram['length'])};")
        lines.append("    };")
        lines.append("    ")

    lines.append("    L26: soc {")
    lines.append("        #address-cells = <2>;")
    lines.append("        #size-cells = <2>;")
    lines.append('        compatible = "cag,sy-bare-soc", "simple-bus";')
    lines.append("        ranges;")
    lines.append("    ")

    if clint:
        irq = " ".join(
            f"&CPU{i}_intc 3 &CPU{i}_intc 7" for i in range(core_num)
        )
        lines.append(f"        clint@{unit_addr(clint['base'])} {{")
        lines.append('          compatible = "riscv,clint0";')
        lines.append(f"          interrupts-extended = <{irq}>;")
        lines.append(f"          reg = {reg_cells(clint['base'], clint['length'])};")
        lines.append('          reg-names = "control";')
        lines.append("        };")
        lines.append("    ")

    if plic:
        irq = " ".join(
            f"&CPU{i}_intc 11 &CPU{i}_intc 9" for i in range(core_num)
        )
        lines.append(f"        PLIC0: interrupt-controller@{unit_addr(plic['base'])} {{")
        lines.append("          #address-cells = <0>;")
        lines.append("          #interrupt-cells = <1>;")
        lines.append('          compatible = "riscv,plic0";')
        lines.append("          interrupt-controller;")
        lines.append(f"          interrupts-extended = <{irq}>;")
        lines.append(f"          reg = {reg_cells(plic['base'], plic['length'])};")
        lines.append("          riscv,max-priority = <7>;")
        lines.append("          riscv,ndev = <3>;")
        lines.append("        };")
        lines.append("    ")

    if debug:
        irq = " ".join(f"&CPU{i}_intc 65535" for i in range(core_num))
        lines.append(f"        debug-controller@{unit_addr(debug['base'])} {{")
        lines.append('          compatible = "riscv,debug-013";')
        lines.append(f"          interrupts-extended = <{irq}>;")
        lines.append(f"          reg = {reg_cells(debug['base'], debug['length'])};")
        lines.append('          reg-names = "control";')
        lines.append("        };")
        lines.append("    ")

    if uart:
        lines.append(f"        uart@{unit_addr(uart['base'])} {{")
        lines.append('          compatible = "ns16750";')
        lines.append(f"          reg = {reg_cells(uart['base'], uart['length'])};")
        lines.append("          clock-frequency = <50000000>;")
        lines.append("          current-speed = <115200>;")
        lines.append("          interrupt-parent = <&PLIC0>;")
        lines.append("          interrupts = <1>;")
        lines.append("          reg-shift = <2>; // regs are spaced on 32 bit boundary")
        lines.append("          reg-io-width = <4>; // only 32-bit access are supported")
        lines.append("        };")
        lines.append("")
        lines.append("        ")

    # Accelerator nodes use @0 unit-address like the reference sy.dts.
    if dma:
        lines.append("        npu_dma: cag-hipu100-dma@0{")
        lines.append('            compatible = "cag-hipu100-dma";')
        lines.append(
            f"            reg = {reg_cells(dma['base'], dma['length'])};    // NPU DMA "
        )
        lines.append('            status = "okay";')
        lines.append("        };")
        lines.append("")

    if sd:
        lines.append(f"        sd@{unit_addr(sd['base'])} {{")
        lines.append('            compatible = "cag,sy-sd";')
        lines.append(f"            reg = {reg_cells(sd['base'], sd['length'])};")
        lines.append('            status = "okay";')
        lines.append("        };")
        lines.append("")

    if regmap:
        lines.append(f"        regmap@{unit_addr(regmap['base'])} {{")
        lines.append('            compatible = "cag,sy-regmap";')
        lines.append(
            f"            reg = {reg_cells(regmap['base'], regmap['length'])};"
        )
        lines.append('            status = "okay";')
        lines.append("        };")
        lines.append("")

    if gpio:
        lines.append(f"        xlnx_gpio: gpio@{unit_addr(gpio['base'])} {{")
        lines.append("          #gpio-cells = <2>;")
        lines.append('          compatible = "xlnx,xps-gpio-1.00.a";')
        lines.append("          gpio-controller ;")
        lines.append(f"          reg = {reg_cells(gpio['base'], gpio['length'])};")
        lines.append("          xlnx,all-inputs = <0x0>;")
        lines.append("          xlnx,all-inputs-2 = <0x0>;")
        lines.append("          xlnx,dout-default = <0x0>;")
        lines.append("          xlnx,dout-default-2 = <0x0>;")
        lines.append("          xlnx,gpio-width = <0x8>;")
        lines.append("          xlnx,gpio2-width = <0x8>;")
        lines.append("          xlnx,interrupt-present = <0x0>;")
        lines.append("          xlnx,is-dual = <0x1>;")
        lines.append("          xlnx,tri-default = <0xffffffff>;")
        lines.append("          xlnx,tri-default-2 = <0xffffffff>;")
        lines.append("        };")
        lines.append("")

    if spi:
        lines.append(f"        xps-spi@{unit_addr(spi['base'])} {{")
        lines.append(
            '          compatible = "xlnx,xps-spi-2.00.b", "xlnx,xps-spi-2.00.a";'
        )
        lines.append("          #address-cells = <1>;")
        lines.append("          #size-cells = <0>;")
        lines.append("          interrupt-parent = <&PLIC0>;")
        lines.append("          interrupts = < 2 2 >;")
        lines.append(f"          reg = {reg_cells(spi['base'], spi['length'])};")
        lines.append('          xlnx,family = "kintex7";')
        lines.append("          xlnx,fifo-exist = <0x1>;")
        lines.append("          xlnx,num-ss-bits = <0x1>;")
        lines.append("          xlnx,num-transfer-bits = <0x8>;")
        lines.append("          xlnx,sck-ratio = <0x4>;")
        lines.append("        };")
        lines.append("")

    if npu:
        lines.append(f"        npu: cag-hipu100@{unit_addr(npu['base'])} {{")
        lines.append('            compatible = "cag-hipu100";')
        lines.append(f"            reg = {reg_cells(npu['base'], npu['length'])};")
        lines.append('            status = "okay";')
        lines.append("        };")
        lines.append("")

    if eth:
        lines.append(f"        eth: lowrisc-eth@{unit_addr(eth['base'])} {{")
        lines.append('         compatible = "lowrisc-eth";')
        lines.append('         device_type = "network";')
        lines.append("         interrupt-parent = <&PLIC0>;")
        lines.append("         interrupts = <3 0>;")
        lines.append(
            "         local-mac-address = [00 18 3e 02 e3 7f];"
        )
        lines.append(f"         reg = {reg_cells(eth['base'], eth['length'])};")
        lines.append("        };")
        lines.append("")

    lines.append("        ")
    lines.append("   };")
    lines.append("};")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate device tree from SoC YAML config"
    )
    parser.add_argument("-f", "--file_path", required=True, help="config YAML path")
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="output dts path (default: <repo>/fpga/bootrom/bootrom_normal/sy.dts)",
    )
    args = parser.parse_args()

    with open(args.file_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    dts = generate_dts(cfg)

    if args.output:
        out_path = args.output
    else:
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
        out_path = os.path.join(
            repo_root, "fpga", "bootrom", "bootrom_normal", "sy.dts"
        )

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(dts)

    print(f"Generated {out_path}")


if __name__ == "__main__":
    main()
