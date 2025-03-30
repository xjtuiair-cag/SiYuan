# Introduction
SiYuan is a RISC-V Symmetric Multiprocessor(SMP) based on TileLink. It implements RV64GC and M/S/U Privilege Level and can to run Linux OS on Xilinx VC707 Board.

# Requirement
To build SiYuan, you need to install the following tools:

1. `vivado 2018.2` 

2. `python3` : make sure `python` refers to python3 in your computer

3. `riscv-none-elf-gcc` : follow this to build `riscv-none-elf-gcc`

4. xilinx vc707 board

# Quick Start
This is a quick start to build SiYuan. Please make sure you have installed the above tools in requirement.

1. Download SiYuan from github.
```sh
git https://github.com/xjtuiair-cag/SiYuan.git 
cd SiYuan
git submodule update --init --recursive
```
2. Generate source files
```sh
make gen_src
```
3. Generate bitstream

Generate bitstream need vivado, so please make sure you have installed vivado and source the setting64.sh of vivado. 

If you are familiar with vivado GUI, you can run the following command to create SiYuan project. Then you will see the project in vivado GUI, and you need to run sythesis and implementation and generate bitstream by yourself.
```sh
make fpga_gui
```
or you can run the following command to generate bitstream directly. When the process done, you will find bitstream `sy_soc_fpga.bit` in `fpga/build/`
```sh
make fpga
```
4. Prepare SD card

Follow this to build linux image and prepare SD card.

5. Run SiYuan 

```sh
sudo screen /your/uart 115200
```

# Dirctory Structure
- config
- de
- doc   
- fpga

