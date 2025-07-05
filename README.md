# Introduction
SiYuan is a RISC-V Symmetric Multiprocessor(SMP) based on TileLink. 

Each core in SiYuan is classic 5-stage in-order RISC-V core which implements RV64GC. We use `TileLink` to connect all the cores and the memory controller so that cache consistency is guaranteed. SiYuan also has the ability to run linux OS and we successfully boot linux on Xilinx VC707 board.

SiYuan support flexible configuration. You can modify the number of cores, add or delete peripheral device on your own. All the source files are written by System verilog.

# Requirement
To build SiYuan, you need to install the following tools:

1. `vivado 2018.2` 

2. `python3` : make sure `python` refers to python3 in your computer

3. `riscv64-unknown-elf-gcc` 

4. `Xilinx VC707 FPGA board`  or `Genesys 2 Kintex-7 FPGA Development Board`

If you don't want to install `python3` or `riscv-none-elf-gcc`, that's ok. You can use default source file to build SiYuan. But if you want to change default configuration, you need to install `python3` and `riscv-none-elf-gcc`.

# Quick Start
This is a quick start to build SiYuan. Please make sure you have installed the above tools in `Requirement`.

1. Download SiYuan from github.
```sh
git https://github.com/xjtuiair-cag/SiYuan.git 
cd SiYuan
git submodule update --init --recursive
```
2. Generate source files

If you don't install `python3` or `riscv-none-elf-gcc`, please skip this step.
```sh
make gen_src
```
3. Generate bitstream

Generate bitstream need vivado, so please make sure you have installed vivado. We recommend to use vivado 2018.2, but other version is acceptable. If you have any problems in generating bitstream, please put it in the `Issue`.

If you are familiar with vivado GUI, you can run the following command to create SiYuan project. Then you will see the project in vivado GUI, and you need to run sythesis and implementation and generate bitstream by yourself.
```sh
make fpga_gui
```
or you can run the following command to generate bitstream directly. When the process done, you will find bitstream `sy_soc_fpga.bit` in `fpga/build/`
```sh
make fpga
```
4. Prepare SD card

Follow [this](https://github.com/xjtuiair-cag/SiYuan-sdk) to build linux image and prepare SD card.

5. Run SiYuan 

Using a program such as Minicom or Screen on Linux, or Teraterm on Windows, open a terminal connection from the host computer to the `Xilinx VC707 Board` and set the baud rate to 115200. 

For example, you can run the following command in linux.
```sh
sudo screen /dev/your_uart 115200
```

Once the bitstream is burned into the FPGA, you will see linux booting message on the screen. Log in with `root` and no password required.

# Simulation

Follow the steps in [doc/simulation](https://github.com/xjtuiair-cag/SiYuan/blob/master/doc/sim_user_guide.md) to run simulation.

# Dirctory Structure
- config : configuration files for SiYuan.

  - scripts : scripts to generate some source files
- de
  - inc     : head files of SiYuan.
  - src     : source files of SiYuan. It contain cache system, tilelink bus, pipeline and so on.
  - ip      : plic/fpu/uart from other repositories.
  - utils   : common files, include fifo, arbiter and so on. some of them are from ariane.
- doc   
- fpga

  - xilinx_constraint : constraint files for vivado implementation.
  - xilinx_ip         : vivado ip.  
  - xilinx_scripts    : Tcl scripts to generate bitstream.

# Change configuration
If you want to change default configuration, please make sure you have install `python3` and `riscv-none-elf-gcc`. 

1. Prepare your configuration file and put it in `config/`.

2. Run `make gen_src CONFIG=file_name.yaml` to generate source files. `file_name` is the name of your configuration file. 

`base.yaml` is the default configuration file. We suggest only change the `Core_num` in configuration file, and the core number is no more than 4 due to the limitation of the resource in `Xilinx VC707`.

# Future plan

1. Support more FPGA boards, such as `xilinx vc709 board`.

2. Transform SiYuan into a out-of-order RISC-V core.

3. Add the [NPU](https://github.com/xjtuiair-cag/XJTU-Tripler) to SiYuan as a coprocessor 
