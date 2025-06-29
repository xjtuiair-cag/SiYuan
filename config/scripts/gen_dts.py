import yaml
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file_path", help="config file path")
    parser.add_argument("-o", "--output", help="output file name")
    args = parser.parse_args()

    file_path = args.file_path
    # Read YAML file
    with open(file_path, "r", encoding="utf-8") as file:
        cfg = yaml.safe_load(file)

    core_num = cfg["Core_num"]

    output = "/dts-v1/;\n"
    output += '''/ {
    #address-cells = <2>;
    #size-cells = <2>;
    compatible = "cag,sy-bare-dev";
    model = "cag,sy-bare";
    chosen {
      stdout-path = "/soc/uart@10000000:115200";
    };\n'''

    # add cpu to device tree
    output += '''
    cpus {
        #address-cells = <1>;
        #size-cells = <0>;
        timebase-frequency = <15000000>; // 15 MHz
    '''
    for i in range(core_num):
        cpu = '''           
        cpu{}: cpu@{} {{
          clock-frequency = <50000000>; // 50 MHz
          device_type = "cpu";
          reg = <{}>;
          status = "okay";
          compatible = "cag, sy", "riscv";
          riscv,isa = "rv64imafdc";
          mmu-type = "riscv,sv39";
          tlb-split;
          // HLIC - hart local interrupt controller
          CPU{}_intc: interrupt-controller {{
            #interrupt-cells = <1>;
            interrupt-controller;
            compatible = "riscv,cpu-intc";
          }};
        }};\n'''.format(i, i, i, i)
        output += cpu
    output += "     };\n"
    # add memmory to device tree
    output += '''
    memory@80000000 {
      device_type = "memory";
      reg = <0x0 0x80000000 0x0 0x20000000>;
    };
    '''
    # soc 
    output += '''
    L26: soc {
        #address-cells = <2>;
        #size-cells = <2>;
        compatible = "cag,sy-bare-soc", "simple-bus";
        ranges;
    '''
    # add clint to device tree
    interrupt = "interrupts-extended = <"
    for i in range(core_num):
        interrupt += "&CPU{}_intc 3 &CPU{}_intc 7 ".format(i,i)
    interrupt += ">;"
    output += '''
        clint@2000000 {{
          compatible = "riscv,clint0";
          {}
          reg = <0x0 0x2000000 0x0 0xc0000>;
          reg-names = "control";
        }};
    '''.format(interrupt)
    # add PLIC to device tree
    interrupt = "interrupts-extended = <"
    for i in range(core_num):
        interrupt += "&CPU{}_intc 11 &CPU{}_intc 9 ".format(i,i)
    interrupt += ">;"
    output += '''
        PLIC0: interrupt-controller@c000000 {{
          #address-cells = <0>;
          #interrupt-cells = <1>;
          compatible = "riscv,plic0";
          interrupt-controller;
          {}
          reg = <0x0 0xc000000 0x0 0x4000000>;
          riscv,max-priority = <7>;
          riscv,ndev = <3>;
        }};
    '''.format(interrupt)
    # add debug control to device tree
    interrupt = "interrupts-extended = <"
    for i in range(core_num):
        interrupt += "&CPU{}_intc 65535 ".format(i,i)
    interrupt += ">;"
    output += '''
        debug-controller@0 {{
          compatible = "riscv,debug-013";
          {}
          reg = <0x0 0x0 0x0 0x1000>;
          reg-names = "control";
        }};
    '''.format(interrupt)
    # add uart to device tree
    if cfg["Uart"] :
        output += '''
        uart@10000000 {
          compatible = "ns16750";
          reg = <0x0 0x10000000 0x0 0x1000>;
          clock-frequency = <50000000>;
          current-speed = <115200>;
          interrupt-parent = <&PLIC0>;
          interrupts = <1>;
          reg-shift = <2>; // regs are spaced on 32 bit boundary
          reg-io-width = <4>; // only 32-bit access are supported
        };\n
        '''
    # add spi to device tree
    if cfg["SPI"] :
        output += '''
        xps-spi@20000000 {
          compatible = "xlnx,xps-spi-2.00.b", "xlnx,xps-spi-2.00.a";
          #address-cells = <1>;
          #size-cells = <0>;
          interrupt-parent = <&PLIC0>;
          interrupts = < 2 2 >;
          reg = < 0x0 0x20000000 0x0 0x1000 >;
          xlnx,family = "kintex7";
          xlnx,fifo-exist = <0x1>;
          xlnx,num-ss-bits = <0x1>;
          xlnx,num-transfer-bits = <0x8>;
          xlnx,sck-ratio = <0x4>;

          mmc@0 {
            compatible = "mmc-spi-slot";
            reg = <0>;
            spi-max-frequency = <12500000>;
            voltage-ranges = <3300 3300>;
            disable-wp;
          };
        };\n
        '''
    if cfg["GPIO"] :
        output += '''
        xlnx_gpio: gpio@40000000 {
          #gpio-cells = <2>;
          compatible = "xlnx,xps-gpio-1.00.a";
          gpio-controller ;
          reg = <0x0 0x40000000 0x0 0x10000 >;
          xlnx,all-inputs = <0x0>;
          xlnx,all-inputs-2 = <0x0>;
          xlnx,dout-default = <0x0>;
          xlnx,dout-default-2 = <0x0>;
          xlnx,gpio-width = <0x8>;
          xlnx,gpio2-width = <0x8>;
          xlnx,interrupt-present = <0x0>;
          xlnx,is-dual = <0x1>;
          xlnx,tri-default = <0xffffffff>;
          xlnx,tri-default-2 = <0xffffffff>;
        };\n
        '''
    if cfg["DMA"] :
        output += '''
        npu_dma: cag-hipu100-dma@0{
            compatible = "cag-hipu100-dma";
            reg = <0x0 0x30000 0x0 0x1000>;    // NPU DMA 
            status = "okay";
        };\n
        '''
    if cfg["NPU"] :
        output += '''
        npu: cag-hipu100@2000{
            compatible = "cag-hipu100";
            reg = <0x0 0x2000 0x0 0x1000>;    // NPU 
            status = "okay";
        };\n
        '''
    if cfg["Ethernet"] : 
        output += '''
        eth: lowrisc-eth@30000000 {
         compatible = "lowrisc-eth";
         device_type = "network";
         interrupt-parent = <&PLIC0>;
         interrupts = <3 0>;
         local-mac-address = [00 18 3e 02 e3 7f]; // This needs to change if more than one GenesysII on a VLAN
         reg = <0x0 0x30000000 0x0 0x8000>;
        };\n 
       '''
    output += "\n   };\n};\n"
    with open(args.output, "w") as file:
        file.writelines(output)
    # print(output)