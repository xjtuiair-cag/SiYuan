## Buttons
set_property -dict {PACKAGE_PIN AV40 IOSTANDARD LVCMOS18} [get_ports cpu_reset]

## UART
set_property -dict {PACKAGE_PIN AU36 IOSTANDARD LVCMOS18} [get_ports tx]
set_property -dict {PACKAGE_PIN AU33 IOSTANDARD LVCMOS18} [get_ports rx]

## LEDs
set_property -dict {PACKAGE_PIN AM39 IOSTANDARD LVCMOS18} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN AN39 IOSTANDARD LVCMOS18} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN AR37 IOSTANDARD LVCMOS18} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN AT37 IOSTANDARD LVCMOS18} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN AR35 IOSTANDARD LVCMOS18} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN AP41 IOSTANDARD LVCMOS18} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN AP42 IOSTANDARD LVCMOS18} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN AU39 IOSTANDARD LVCMOS18} [get_ports {led[7]}]

## Switches
set_property -dict {PACKAGE_PIN AV30 IOSTANDARD LVCMOS18} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN AY33 IOSTANDARD LVCMOS18} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN BA31 IOSTANDARD LVCMOS18} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN BA32 IOSTANDARD LVCMOS18} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN AW30 IOSTANDARD LVCMOS18} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN AY30 IOSTANDARD LVCMOS18} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN BA30 IOSTANDARD LVCMOS18} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN BB31 IOSTANDARD LVCMOS18} [get_ports {sw[7]}]

## Fan Control
set_property -dict {PACKAGE_PIN BA37 IOSTANDARD LVCMOS18} [get_ports fan_pwm]

#############################################
## SD Card (SPI)
#############################################
set_property -dict {PACKAGE_PIN AN30 IOSTANDARD LVCMOS18} [get_ports spi_clk_o]
set_property -dict {PACKAGE_PIN AT30 IOSTANDARD LVCMOS18} [get_ports spi_ss]
set_property -dict {PACKAGE_PIN AR30 IOSTANDARD LVCMOS18} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN AP30 IOSTANDARD LVCMOS18} [get_ports spi_mosi]

## To use FTDI FT2232 JTAG
set_property -dict { PACKAGE_PIN AV39 IOSTANDARD LVCMOS18 } [get_ports trst];
set_property -dict { PACKAGE_PIN M32 IOSTANDARD LVCMOS18 } [get_ports tck ];
set_property -dict { PACKAGE_PIN V29 IOSTANDARD LVCMOS18 } [get_ports tdi ];
set_property -dict { PACKAGE_PIN M28 IOSTANDARD LVCMOS18 } [get_ports tdo ];
set_property -dict { PACKAGE_PIN U31 IOSTANDARD LVCMOS18 } [get_ports tms ];

set_max_delay -to   [get_ports tdo ] 20
set_max_delay -from [get_ports tms ] 20
set_max_delay -from [get_ports tdi ] 20
set_max_delay -from [get_ports trst ] 20
