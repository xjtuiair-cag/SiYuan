## Buttons
set_property -dict {PACKAGE_PIN AV40 IOSTANDARD LVCMOS18} [get_ports cpu_reset]

## UART
set_property -dict {PACKAGE_PIN AU36 IOSTANDARD LVCMOS18} [get_ports tx]
set_property -dict {PACKAGE_PIN AU33 IOSTANDARD LVCMOS18} [get_ports rx]
#############################################
## SD Card (SPI)
#############################################
set_property -dict {PACKAGE_PIN AN30 IOSTANDARD LVCMOS18} [get_ports sd_sclk]
set_property -dict {PACKAGE_PIN AR30 IOSTANDARD LVCMOS18} [get_ports {sd_dat[0]}]
set_property -dict {PACKAGE_PIN AU31 IOSTANDARD LVCMOS18} [get_ports {sd_dat[1]}]
set_property -dict {PACKAGE_PIN AV31 IOSTANDARD LVCMOS18} [get_ports {sd_dat[2]}]
set_property -dict {PACKAGE_PIN AT30 IOSTANDARD LVCMOS18} [get_ports {sd_dat[3]}]
set_property -dict {PACKAGE_PIN AP30 IOSTANDARD LVCMOS18} [get_ports sd_cmd]
set_property -dict {PACKAGE_PIN AP32 IOSTANDARD LVCMOS18} [get_ports sd_detect]

# set_property IOSTANDARD LVCMOS18 [get_ports sd_sclk]
set_property DRIVE 12 [get_ports sd_sclk]
set_property SLEW SLOW [get_ports sd_sclk]

set_property PULLUP true [get_ports {sd_dat[0]}]
set_property PULLUP true [get_ports {sd_dat[1]}]
set_property PULLUP true [get_ports {sd_dat[2]}]
set_property PULLUP true [get_ports {sd_dat[3]}]
set_property PULLUP true [get_ports sd_cmd]
set_property DRIVE 12 [get_ports {sd_dat[0]}]
set_property DRIVE 12 [get_ports {sd_dat[1]}]
set_property DRIVE 12 [get_ports {sd_dat[2]}]
set_property DRIVE 12 [get_ports {sd_dat[3]}]
set_property DRIVE 12 [get_ports sd_cmd]
set_property SLEW SLOW [get_ports {sd_dat[0]}]
set_property SLEW SLOW [get_ports {sd_dat[1]}]
set_property SLEW SLOW [get_ports {sd_dat[2]}]
set_property SLEW SLOW [get_ports {sd_dat[3]}]
set_property SLEW SLOW [get_ports sd_cmd]

# set_property IOSTANDARD LVCMOS18 [get_ports sd_detect]
# set_property PULLUP true [get_ports sd_detect]

## To use FTDI FT2232 JTAG
# set_property -dict { PACKAGE_PIN AV39 IOSTANDARD LVCMOS18 } [get_ports trst_n];
# set_property -dict { PACKAGE_PIN P10 IOSTANDARD LVCMOS18 } [get_ports tck ];
# set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS18 } [get_ports tdi ];
# set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS18 } [get_ports tdo ];
# set_property -dict { PACKAGE_PIN P11 IOSTANDARD LVCMOS18 } [get_ports tms ];
# To use LCD ports as JTAG
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck]
set_property PACKAGE_PIN AT42 [get_ports tck]
set_property IOSTANDARD LVCMOS18 [get_ports tck]
set_property PULLUP true [get_ports tck]
set_property PACKAGE_PIN AR38 [get_ports tms]
set_property IOSTANDARD LVCMOS18 [get_ports tms]
set_property PULLUP true [get_ports tms]
set_property PACKAGE_PIN AR39 [get_ports tdi]
set_property IOSTANDARD LVCMOS18 [get_ports tdi]
set_property PULLUP true [get_ports tdi]
set_property PACKAGE_PIN AT40 [get_ports tdo]
set_property IOSTANDARD LVCMOS18 [get_ports tdo]
set_property PULLUP true [get_ports tdo]
create_clock -period 100.000 -name JTCK -waveform {0.000 50.000} -add [get_ports tck]

# set_max_delay -to   [get_ports tdo ] 20
# set_max_delay -from [get_ports tms ] 20
# set_max_delay -from [get_ports tdi ] 20
# set_max_delay -from [get_ports trst ] 20

create_generated_clock -name clk_fpu -source [get_pins i_xlnx_clk_gen0/clk_out1] -divide_by 2 [get_pins cpu_inst/SiYuan_top_inst/clk_fpu_reg/Q]
