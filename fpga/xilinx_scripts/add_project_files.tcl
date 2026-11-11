# Add board constraints, prebuilt Xilinx IP, and RTL sources.
# Invoked from the per-config project directory. IP lives under this config
# ($IP_BUILD_DIR = build/<BOARD>/<config>/ip/), not in fpga/xilinx_ip.

foreach var {FPGA_ROOT IP_BUILD_DIR ADD_SOURCES_TCL BOARD} {
    if {![info exists ::env($var)] || $::env($var) eq ""} {
        puts "ERROR: environment variable $var is not set"
        exit 1
    }
}

set fpga_root $::env(FPGA_ROOT)
set ip_root   $::env(IP_BUILD_DIR)
set board     $::env(BOARD)

# Keep any project-local IP cache / user files inside this config directory.
set_property ip_output_repo [file normalize [file join [pwd] SiYuan.cache ip]] [current_project]
set_property ip.user_files_dir [file normalize [file join [pwd] SiYuan.ip_user_files]] [current_project]

if {$board eq "genesys2"} {
    add_files -fileset constrs_1 -norecurse [file join $fpga_root xilinx_constraint genesys2.xdc]
} elseif {$board eq "vc707"} {
    add_files -fileset constrs_1 -norecurse [file join $fpga_root xilinx_constraint vc707.xdc]
} else {
    puts "ERROR: Unknown BOARD=$board"
    exit 1
}

# Read XCIs from each IP's own Vivado .srcs tree. That keeps RUNTIME_PARAM.OUTPUTDIR
# (.gen) under build/<BOARD>/<config>/ip/<ip>/ instead of leaking into fpga/build/*.gen.
foreach ip {xlnx_mig_7_ddr3 xlnx_axi_clock_converter xlnx_clk_gen div64x64_d20_s div64x64_d20_us} {
    set xci [file join $ip_root $ip ${ip}.srcs sources_1 ip $ip ${ip}.xci]
    if {![file exists $xci]} {
        puts "ERROR: missing IP $xci"
        exit 1
    }
    puts "Reading IP $xci"
    read_ip $xci
}

set add_sources $::env(ADD_SOURCES_TCL)
if {![file exists $add_sources]} {
    puts "ERROR: missing sources script $add_sources"
    exit 1
}
source $add_sources

# Global Verilog defines (e.g. VC707/GENESYS2 PLATFORM_XILINX NORMAL/LOWRISC)
if {[info exists ::env(VIVADO_DEFINES)] && $::env(VIVADO_DEFINES) ne ""} {
    set_property verilog_define [split $::env(VIVADO_DEFINES)] [current_fileset]
}

if {[info exists ::env(FPGA_TOP)] && $::env(FPGA_TOP) ne ""} {
    set_property top $::env(FPGA_TOP) [current_fileset]
} else {
    set_property top cpu_vc707_top [current_fileset]
}

update_compile_order -fileset sources_1
