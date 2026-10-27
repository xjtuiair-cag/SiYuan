// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_sd.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : 
// -----------------------------------------------------------------------------
// PURPOSE    :
// -----------------------------------------------------------------------------
// PARAMETERS :
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Strategy   :
// Clock Domains    :
// Critical Timing  :
// Test Features    :
// Asynchronous I/F :
// Scan Methodology : N
// Instantiations   : N
// Synthesizable    : Y
// Other :
// -FHDR------------------------------------------------------------------------

module sy_sd
    import sy_pkg::*;
# (
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64
)(
    input  logic                            clk_i,
    input  logic                            rst_i,

    output logic                            irq_o,

    input  wire                             sd_detect,
    output logic                            sd_clk, 
    output reg                              sd_reset,
    input  logic [3:0]                      sd_dat_i,
    output logic [3:0]                      sd_dat_o,
    output logic                            sd_dat_oe_o,
    input  logic                            sd_cmd_i,
    output logic                            sd_cmd_o,
    output logic                            sd_cmd_oe_o,

    // used to read/write register
    // A Channel
    input  logic                            inp_tl_A_valid_i,
    output logic                            inp_tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t            inp_tl_A_bits_i,
    // B Channel
    output logic                            inp_tl_B_valid_o,
    input  logic                            inp_tl_B_ready_i,
    output tl_pkg::B_chan_bits_t            inp_tl_B_bits_o,
    // C Channel
    input  logic                            inp_tl_C_valid_i,
    output logic                            inp_tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t            inp_tl_C_bits_i,
    // D Channel
    output logic                            inp_tl_D_valid_o,
    input  logic                            inp_tl_D_ready_i,
    output tl_pkg::D_chan_bits_t            inp_tl_D_bits_o,
    // E Channel
    input  logic                            inp_tl_E_valid_i,
    output logic                            inp_tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t            inp_tl_E_bits_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   sd_en;
    logic                                   sd_we;
    logic [63:0]                            sd_addr;
    logic [7:0]                             sd_be;
    logic [63:0]                            sd_rdata;
    logic [63:0]                            sd_wdata;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;

    TL2Reg_be #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       (inp_tl_A_valid_i),              
        .TL_A_ready_o       (inp_tl_A_ready_o),              
        .TL_A_bits_i        (inp_tl_A_bits_i ),            

        .TL_D_valid_o       (inp_tl_D_valid_o),              
        .TL_D_ready_i       (inp_tl_D_ready_i),              
        .TL_D_bits_o        (inp_tl_D_bits_o ),            

        .addr_o             ( sd_addr      ),
        .en_o               ( sd_en        ),
        .we_o               ( sd_we        ),
        .wdata_o            ( sd_wdata     ),
        .be_o               ( sd_be        ),
        .rdata_i            ( sd_rdata     )
    );

    sd_controller_top sd_top_inst(
        .clk_i              ( clk_i     ),
        .rst_i              ( rst_i     ),

        .spisd_en           ( sd_en     ),
        .spisd_we           ( sd_we     ),
        .spisd_addr         ( sd_addr[15:0]   ),
        .spisd_be           ( sd_be     ),
        .spisd_wrdata       ( sd_wdata  ),
        .spisd_rddata       ( sd_rdata  ),

        .sd_detect          ( sd_detect ),
        .sd_reset           ( sd_reset  ),
        .sd_clk             ( sd_clk    ),

        .sd_dat_i           (sd_dat_i   ),
        .sd_dat_o           (sd_dat_o   ),
        .sd_dat_oe_o        (sd_dat_oe_o),
        .sd_cmd_i           (sd_cmd_i   ),
        .sd_cmd_o           (sd_cmd_o   ),
        .sd_cmd_oe_o        (sd_cmd_oe_o),

        .sd_irq             ( irq_o                  )
   );

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

// (* mark_debug = "true" *) logic         prb_sd_en;
// (* mark_debug = "true" *) logic         prb_sd_we;
// (* mark_debug = "true" *) logic[31:0]   prb_sd_addr;
// (* mark_debug = "true" *) logic[63:0]   prb_sd_wdata;
// (* mark_debug = "true" *) logic[63:0]   prb_sd_rdata;

// assign prb_sd_en     = sd_en;
// assign prb_sd_we     = sd_we;
// assign prb_sd_addr   = sd_addr[31:0];
// assign prb_sd_wdata  = sd_wdata;
// assign prb_sd_rdata  = sd_rdata;

endmodule