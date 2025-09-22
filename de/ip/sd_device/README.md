# sd_device
SD device emulator from [ProjectVault](https://github.com/ProjectVault/orp)

This implements a synthesisable model of the device side of the SD spec in verilog which can simulate a SD card.
It was first implemented in ProjectVault and has added SPI support from [flipsyfat](https://github.com/scanlime/flipsyfat)

The interface towards the SoC consists of a Wishbone master that reads and writes against memory using DMA

This core is compatible with [FuseSoC](https://github.com/olofk/fusesoc)
