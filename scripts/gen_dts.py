#!/usr/bin/env python3
"""Generate FPGA bootrom device tree.

Only the core-count-dependent sections vary (cpus + interrupt wiring for
CLINT / PLIC / debug). Address map and peripheral nodes are fixed.
"""

import argparse
import os


def cpu_node(i: int) -> str:
    return f"""        cpu{i}: cpu@{i} {{
          clock-frequency = <50000000>; // 50 MHz
          device_type = "cpu";
          reg = <{i}>;
          status = "okay";
          compatible = "cag, sy", "riscv";
          riscv,isa = "rv64imafdc";
          mmu-type = "riscv,sv39";
          tlb-split;
          // HLIC - hart local interrupt controller
          CPU{i}_intc: interrupt-controller {{
            #interrupt-cells = <1>;
            interrupt-controller;
            compatible = "riscv,cpu-intc";
          }};
        }};"""


def join_irq(refs) -> str:
    return " ".join(refs)


def generate_dts(core_num: int) -> str:
    if core_num < 1:
        raise ValueError(f"CORE_NUM must be >= 1, got {core_num}")

    cpus = ("\n           \n".join(cpu_node(i) for i in range(core_num)))

    clint_irq = join_irq(
        [f"&CPU{i}_intc 3 &CPU{i}_intc 7" for i in range(core_num)]
    )
    plic_irq = join_irq(
        [f"&CPU{i}_intc 11 &CPU{i}_intc 9" for i in range(core_num)]
    )
    debug_irq = join_irq([f"&CPU{i}_intc 65535" for i in range(core_num)])

    # Fixed address map / peripherals; only cpus + IRQ wiring depend on CORE_NUM.
    return f"""/dts-v1/;
/ {{
    #address-cells = <2>;
    #size-cells = <2>;
    compatible = "cag,sy-bare-dev";
    model = "cag,sy-bare";
    chosen {{
      stdout-path = "/soc/uart@41810000:115200";
    }};

    cpus {{
        #address-cells = <1>;
        #size-cells = <0>;
        timebase-frequency = <32768>; // 32.768KHz
               
{cpus}
    }};
           
    memory@80000000 {{
      device_type = "memory";
      reg = <0x0 0x80000000 0x0 0x80000000>;
    }};
    
    L26: soc {{
        #address-cells = <2>;
        #size-cells = <2>;
        compatible = "cag,sy-bare-soc", "simple-bus";
        ranges;
    
        clint@2000000 {{
          compatible = "riscv,clint0";
          interrupts-extended = <{clint_irq}>;
          reg = <0x0 0x2000000 0x0 0xc0000>;
          reg-names = "control";
        }};
    
        PLIC0: interrupt-controller@c000000 {{
          #address-cells = <0>;
          #interrupt-cells = <1>;
          compatible = "riscv,plic0";
          interrupt-controller;
          interrupts-extended = <{plic_irq}>;
          reg = <0x0 0xc000000 0x0 0x4000000>;
          riscv,max-priority = <7>;
          riscv,ndev = <3>;
        }};
    
        debug-controller@0 {{
          compatible = "riscv,debug-013";
          interrupts-extended = <{debug_irq}>;
          reg = <0x0 0x0 0x0 0x1000>;
          reg-names = "control";
        }};
    
        uart@41810000 {{
          compatible = "ns16750";
          reg = <0x0 0x41810000 0x0 0x1000>;
          clock-frequency = <50000000>;
          current-speed = <115200>;
          interrupt-parent = <&PLIC0>;
          interrupts = <1>;
          reg-shift = <2>; // regs are spaced on 32 bit boundary
          reg-io-width = <4>; // only 32-bit access are supported
        }};

        
        npu_dma: cag-hipu100-dma@0{{
            compatible = "cag-hipu100-dma";
            reg = <0x0 0x41820000 0x0 0x1000>;    // NPU DMA 
            status = "okay";
        }};

        sd@41850000 {{
            compatible = "cag,sy-sd";
            reg = <0x0 0x41850000 0x0 0x7b0000>;
            status = "okay";
        }};

        regmap@41840000 {{
            compatible = "cag,sy-regmap";
            reg = <0x0 0x41840000 0x0 0x10000>;
            status = "okay";
        }};

        
   }};
}};
"""


def main():
    parser = argparse.ArgumentParser(
        description="Generate device tree (CORE_NUM varies; address map fixed)"
    )
    parser.add_argument(
        "-n",
        "--cores",
        type=int,
        required=True,
        help="number of harts / cores (SY_CORE_NUM)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="output dts path (default: fpga/bootrom/bootrom_normal/sy.dts)",
    )
    args = parser.parse_args()

    dts = generate_dts(args.cores)

    if args.output:
        out_path = args.output
    else:
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        out_path = os.path.join(
            repo_root, "fpga", "bootrom", "bootrom_normal", "sy.dts"
        )

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(dts)

    print(f"Generated {out_path} (CORE_NUM={args.cores})")


if __name__ == "__main__":
    main()
