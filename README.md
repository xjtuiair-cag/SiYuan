# Introduction
SiYuan is a RISC-V Symmetric Multiprocessor(SMP) based on TileLink. 

Each core in SiYuan is classic 5-stage in-order RISC-V core which implements RV64GC. We use `TileLink` to connect all the cores and the memory controller so that cache consistency is guaranteed. SiYuan also has the ability to run linux OS and we successfully boot linux on Xilinx VC707 board.

SiYuan support flexible configuration. You can modify the number of cores, add or delete peripheral device on your own. All the source files are written by System verilog.

# Quick Start

Select a specific version of SiYuan from the [Release](https://github.com/xjtuiair-cag/SiYuan/releases) to download the pre-compiled bitstream file and the Linux image file `bbl.bin`. Then, follow the [SiYuan FPGA User Guide](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/SiYuan_FPGA_User_Guide.pdf) to start SiYuan on the FPGA and run Linux.

# FPGA bitstream generation
If you want to build SiYuan from scratch, please follow the steps in [fpga_build_user_guide](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/fpga_build_user_guide.md).

# Simulation

Follow the steps in [simulation user guide](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/sim_user_guide.md) to run simulation.

# Dirctory Structure
- scripts : helper scripts (`gen_dts.py`, `expand_vc.py`, …)
- de  : design files
  - inc     : head files of SiYuan.
  - src     : source files of SiYuan. It contain cache system, tilelink bus, pipeline and so on.
  - ip      : plic/fpu/uart from other repositories.
  - utils   : common files, include fifo, arbiter and so on. some of them are from `ariane`.
  - vc      : RTL file lists
- dv : simulation files
  - simulation : simulation work directory
  - tb : testbench
  - tests : test cases for SiYuan, containing `riscv-tests`, `benos test`, `dma test` and `linux test`.
  - vc : simulation file list
- doc : documentaion about simulation and fpga.  
- fpga
  - xilinx_constraint : constraint files for vivado implementation.
  - xilinx_ip         : vivado ip.  
  - xilinx_scripts    : Tcl scripts to generate bitstream.

# Change configuration
Core count is selected at compile time (shared by simulation and FPGA):

```sh
make gen_src CORE_NUM=4    # refresh per-config bootrom DTS
make sim CORE_NUM=4
make fpga CORE_NUM=4       # -> fpga/build/<BOARD>/normal_4cores/
```

`SY_CORE_NUM` is passed as a Verilog define into `de/inc/sy_pkg.sv` (`parameter CORE_NUM`). The peripheral address map in that file is fixed. Each FPGA config is isolated under `fpga/build/<BOARD>/<BOOTROM_TYPE>_<N>cores/` (local `bootrom/` + `ip/`), so different `CORE_NUM` / bootrom builds can run in parallel.

# Future plan

1. Support more FPGA boards, such as `xilinx vc709 board`.

2. Add the [NPU](https://github.com/xjtuiair-cag/XJTU-Tripler) to SiYuan as a coprocessor 
