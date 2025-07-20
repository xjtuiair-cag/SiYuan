# Introduction
SiYuan is a RISC-V Symmetric Multiprocessor(SMP) based on TileLink. 

Each core in SiYuan is classic 5-stage in-order RISC-V core which implements RV64GC. We use `TileLink` to connect all the cores and the memory controller so that cache consistency is guaranteed. SiYuan also has the ability to run linux OS and we successfully boot linux on Xilinx VC707 board.

SiYuan support flexible configuration. You can modify the number of cores, add or delete peripheral device on your own. All the source files are written by System verilog.

# Quick Start

Select a specific version of SiYuan from the [Release](https://github.com/xjtuiair-cag/SiYuan/releases) to download the pre-compiled bitstream file and the Linux image file `bbl.bin`. Then, follow the [SiYuan FPGA User Guide](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/SiYuan_FPGA_User_Guide.pdf) to start SiYuan on the FPGA and run Linux.

# Simulation

Follow the steps in [doc/simulation](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/sim_user_guide.md) to run simulation.

# Dirctory Structure
- config : configuration files for SiYuan.
  - scripts : scripts to generate source files
- de  : design files
  - inc     : head files of SiYuan.
  - src     : source files of SiYuan. It contain cache system, tilelink bus, pipeline and so on.
  - ip      : plic/fpu/uart from other repositories.
  - utils   : common files, include fifo, arbiter and so on. some of them are from `ariane`.
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
If you want to change default configuration, please make sure you have install `python3` and `riscv64-unknown-elf-gcc`. 

1. Prepare your configuration file and put it in `config/`.

2. Run `make gen_src CONFIG=file_name.yaml` to generate source files. `file_name` is the name of your configuration file. 

`base.yaml` is the default configuration file. We suggest only change the `Core_num` in configuration file, and the core number is no more than 4 due to the limitation of the resource in FPGA.

# Future plan

1. Support more FPGA boards, such as `xilinx vc709 board`.

2. Add the [NPU](https://github.com/xjtuiair-cag/XJTU-Tripler) to SiYuan as a coprocessor 
