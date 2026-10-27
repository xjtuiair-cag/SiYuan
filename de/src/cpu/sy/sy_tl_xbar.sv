// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_tl_xbar.v
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


module sy_tl_xbar
    import tl_pkg::*;
#(
    parameter MASTER_NUM            = 4,
    parameter SLAVE_NUM             = 4,
    parameter REGION_NUM            = 1,
    parameter SOURCE_LSB            = 0,
    parameter SOURCE_MSB            = 1,
    parameter SINK_LSB              = 0,
    parameter SINK_MSB              = 1,
    parameter TL_ADDR_WIDTH         = 64,
    parameter MASTER_BUF_DEPTH      = 1,
    parameter SLAVE_BUF_DEPTH       = 1
)(
    input logic                                 clk_i,
    input logic                                 rst_i,
    // Master A Channel
    input  logic [MASTER_NUM-1:0]               master_A_valid_i,
    output logic [MASTER_NUM-1:0]               master_A_ready_o,
    input  A_chan_bits_t [MASTER_NUM-1:0]       master_A_bits_i,
    // Master B Channel
    output logic [MASTER_NUM-1:0]               master_B_valid_o,
    input  logic [MASTER_NUM-1:0]               master_B_ready_i,
    output B_chan_bits_t [MASTER_NUM-1:0]       master_B_bits_o,
    // Master C Channel
    input  logic [MASTER_NUM-1:0]               master_C_valid_i,
    output logic [MASTER_NUM-1:0]               master_C_ready_o,
    input  C_chan_bits_t [MASTER_NUM-1:0]       master_C_bits_i,
    // Master D Channel
    output logic [MASTER_NUM-1:0]               master_D_valid_o,
    input  logic [MASTER_NUM-1:0]               master_D_ready_i,
    output D_chan_bits_t [MASTER_NUM-1:0]       master_D_bits_o,
    // Master E Channel
    input  logic [MASTER_NUM-1:0]               master_E_valid_i,
    output logic [MASTER_NUM-1:0]               master_E_ready_o,
    input  E_chan_bits_t [MASTER_NUM-1:0]       master_E_bits_i,
    // Slave A Channel
    output logic [SLAVE_NUM-1:0]                slave_A_valid_o,
    input  logic [SLAVE_NUM-1:0]                slave_A_ready_i,
    output A_chan_bits_t [SLAVE_NUM-1:0]        slave_A_bits_o,
    // Slave B Channel
    input  logic [SLAVE_NUM-1:0]                slave_B_valid_i,
    output logic [SLAVE_NUM-1:0]                slave_B_ready_o,
    input  B_chan_bits_t [SLAVE_NUM-1:0]        slave_B_bits_i,
    // Slave C Channel
    output logic [SLAVE_NUM-1:0]                slave_C_valid_o,
    input  logic [SLAVE_NUM-1:0]                slave_C_ready_i,
    output C_chan_bits_t [SLAVE_NUM-1:0]        slave_C_bits_o,
    // Slave D Channel
    input  logic [SLAVE_NUM-1:0]                slave_D_valid_i,
    output logic [SLAVE_NUM-1:0]                slave_D_ready_o,
    input  D_chan_bits_t [SLAVE_NUM-1:0]        slave_D_bits_i,
    // Slave E Channel
    output logic [SLAVE_NUM-1:0]                slave_E_valid_o,
    input  logic [SLAVE_NUM-1:0]                slave_E_ready_i,
    output E_chan_bits_t [SLAVE_NUM-1:0]        slave_E_bits_o,
    // Memory map
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0] start_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0] end_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                    region_en_i 
);

    logic [MASTER_NUM-1:0]               master_A_valid;
    logic [MASTER_NUM-1:0]               master_A_ready;
    A_chan_bits_t [MASTER_NUM-1:0]       master_A_bits;
    logic [MASTER_NUM-1:0]               master_B_valid;
    logic [MASTER_NUM-1:0]               master_B_ready;
    B_chan_bits_t [MASTER_NUM-1:0]       master_B_bits;
    logic [MASTER_NUM-1:0]               master_C_valid;
    logic [MASTER_NUM-1:0]               master_C_ready;
    C_chan_bits_t [MASTER_NUM-1:0]       master_C_bits;
    logic [MASTER_NUM-1:0]               master_D_valid;
    logic [MASTER_NUM-1:0]               master_D_ready;
    D_chan_bits_t [MASTER_NUM-1:0]       master_D_bits;
    logic [MASTER_NUM-1:0]               master_E_valid;
    logic [MASTER_NUM-1:0]               master_E_ready;
    E_chan_bits_t [MASTER_NUM-1:0]       master_E_bits;
    logic [SLAVE_NUM-1:0]                slave_A_valid;
    logic [SLAVE_NUM-1:0]                slave_A_ready;
    A_chan_bits_t [SLAVE_NUM-1:0]        slave_A_bits;
    logic [SLAVE_NUM-1:0]                slave_B_valid;
    logic [SLAVE_NUM-1:0]                slave_B_ready;
    B_chan_bits_t [SLAVE_NUM-1:0]        slave_B_bits;
    logic [SLAVE_NUM-1:0]                slave_C_valid;
    logic [SLAVE_NUM-1:0]                slave_C_ready;
    C_chan_bits_t [SLAVE_NUM-1:0]        slave_C_bits;
    logic [SLAVE_NUM-1:0]                slave_D_valid;
    logic [SLAVE_NUM-1:0]                slave_D_ready;
    D_chan_bits_t [SLAVE_NUM-1:0]        slave_D_bits;
    logic [SLAVE_NUM-1:0]                slave_E_valid;
    logic [SLAVE_NUM-1:0]                slave_E_ready;
    E_chan_bits_t [SLAVE_NUM-1:0]        slave_E_bits;

    tl_xbar #(
        .MASTER_NUM      ( MASTER_NUM      ),
        .SLAVE_NUM       ( SLAVE_NUM       ),
        .REGION_NUM      ( REGION_NUM      ),
        .SOURCE_LSB      ( SOURCE_LSB      ),
        .SOURCE_MSB      ( SOURCE_MSB      ),
        .SINK_LSB        ( SINK_LSB        ),
        .SINK_MSB        ( SINK_MSB        ),
        .TL_ADDR_WIDTH   ( TL_ADDR_WIDTH   )
    ) i_xbar (
        .clk_i              ( clk_i           ),
        .rst_i              ( rst_i         ),
        .master_A_valid_i   (master_A_valid),     
        .master_A_ready_o   (master_A_ready),     
        .master_A_bits_i    (master_A_bits ),    
        .master_B_valid_o   (master_B_valid),     
        .master_B_ready_i   (master_B_ready),     
        .master_B_bits_o    (master_B_bits ),    
        .master_C_valid_i   (master_C_valid),     
        .master_C_ready_o   (master_C_ready),     
        .master_C_bits_i    (master_C_bits ),    
        .master_D_valid_o   (master_D_valid),     
        .master_D_ready_i   (master_D_ready),     
        .master_D_bits_o    (master_D_bits ),    
        .master_E_valid_i   (master_E_valid),     
        .master_E_ready_o   (master_E_ready),     
        .master_E_bits_i    (master_E_bits ),    

        .slave_A_valid_o    (slave_A_valid),    
        .slave_A_ready_i    (slave_A_ready),    
        .slave_A_bits_o     (slave_A_bits ),   
        .slave_B_valid_i    (slave_B_valid),    
        .slave_B_ready_o    (slave_B_ready),    
        .slave_B_bits_i     (slave_B_bits ),   
        .slave_C_valid_o    (slave_C_valid),    
        .slave_C_ready_i    (slave_C_ready),    
        .slave_C_bits_o     (slave_C_bits ),   
        .slave_D_valid_i    (slave_D_valid),    
        .slave_D_ready_o    (slave_D_ready),    
        .slave_D_bits_i     (slave_D_bits ),   
        .slave_E_valid_o    (slave_E_valid),    
        .slave_E_ready_i    (slave_E_ready),    
        .slave_E_bits_o     (slave_E_bits ),   

        .start_addr_i       ( start_addr_i  ),       
        .end_addr_i         ( end_addr_i    ),
        .region_en_i        ( region_en_i   )
    );

    for (genvar i = 0; i < SLAVE_NUM; i++) begin : tl_buffer_slave
        tl_buffer #(
            .BUF_DEPTH  ( SLAVE_BUF_DEPTH)
        ) i_tl_slave_buf (
            .clk_i              ( clk_i         ),
            .rst_i              ( rst_i         ),
            .inp_tl_A_valid_i   (slave_A_valid[i]),    
            .inp_tl_A_ready_o   (slave_A_ready[i]),    
            .inp_tl_A_bits_i    (slave_A_bits [i]),   
            .inp_tl_B_valid_o   (slave_B_valid[i]),    
            .inp_tl_B_ready_i   (slave_B_ready[i]),    
            .inp_tl_B_bits_o    (slave_B_bits [i]),   
            .inp_tl_C_valid_i   (slave_C_valid[i]),    
            .inp_tl_C_ready_o   (slave_C_ready[i]),    
            .inp_tl_C_bits_i    (slave_C_bits [i]),   
            .inp_tl_D_valid_o   (slave_D_valid[i]),    
            .inp_tl_D_ready_i   (slave_D_ready[i]),    
            .inp_tl_D_bits_o    (slave_D_bits [i]),   
            .inp_tl_E_valid_i   (slave_E_valid[i]),    
            .inp_tl_E_ready_o   (slave_E_ready[i]),    
            .inp_tl_E_bits_i    (slave_E_bits [i]),   
            .oup_tl_A_valid_o   (slave_A_valid_o[i]),    
            .oup_tl_A_ready_i   (slave_A_ready_i[i]),    
            .oup_tl_A_bits_o    (slave_A_bits_o [i]),   
            .oup_tl_B_valid_i   (slave_B_valid_i[i]),    
            .oup_tl_B_ready_o   (slave_B_ready_o[i]),    
            .oup_tl_B_bits_i    (slave_B_bits_i [i]),   
            .oup_tl_C_valid_o   (slave_C_valid_o[i]),    
            .oup_tl_C_ready_i   (slave_C_ready_i[i]),    
            .oup_tl_C_bits_o    (slave_C_bits_o [i]),   
            .oup_tl_D_valid_i   (slave_D_valid_i[i]),    
            .oup_tl_D_ready_o   (slave_D_ready_o[i]),    
            .oup_tl_D_bits_i    (slave_D_bits_i [i]),   
            .oup_tl_E_valid_o   (slave_E_valid_o[i]),    
            .oup_tl_E_ready_i   (slave_E_ready_i[i]),    
            .oup_tl_E_bits_o    (slave_E_bits_o [i])
        );
    end

    for (genvar i = 0; i < MASTER_NUM; i++) begin : tl_buffer_master
        tl_buffer #(
            .BUF_DEPTH  ( MASTER_BUF_DEPTH)
        ) i_tl_master_buf (
            .clk_i              ( clk_i         ),
            .rst_i              ( rst_i         ),
            .inp_tl_A_valid_i   (master_A_valid_i[i]),    
            .inp_tl_A_ready_o   (master_A_ready_o[i]),    
            .inp_tl_A_bits_i    (master_A_bits_i [i]),   
            .inp_tl_B_valid_o   (master_B_valid_o[i]),    
            .inp_tl_B_ready_i   (master_B_ready_i[i]),    
            .inp_tl_B_bits_o    (master_B_bits_o [i]),   
            .inp_tl_C_valid_i   (master_C_valid_i[i]),    
            .inp_tl_C_ready_o   (master_C_ready_o[i]),    
            .inp_tl_C_bits_i    (master_C_bits_i [i]),   
            .inp_tl_D_valid_o   (master_D_valid_o[i]),    
            .inp_tl_D_ready_i   (master_D_ready_i[i]),    
            .inp_tl_D_bits_o    (master_D_bits_o [i]),   
            .inp_tl_E_valid_i   (master_E_valid_i[i]),    
            .inp_tl_E_ready_o   (master_E_ready_o[i]),    
            .inp_tl_E_bits_i    (master_E_bits_i [i]),   
            .oup_tl_A_valid_o   (master_A_valid[i]),    
            .oup_tl_A_ready_i   (master_A_ready[i]),    
            .oup_tl_A_bits_o    (master_A_bits [i]),   
            .oup_tl_B_valid_i   (master_B_valid[i]),    
            .oup_tl_B_ready_o   (master_B_ready[i]),    
            .oup_tl_B_bits_i    (master_B_bits [i]),   
            .oup_tl_C_valid_o   (master_C_valid[i]),    
            .oup_tl_C_ready_i   (master_C_ready[i]),    
            .oup_tl_C_bits_o    (master_C_bits [i]),   
            .oup_tl_D_valid_i   (master_D_valid[i]),    
            .oup_tl_D_ready_o   (master_D_ready[i]),    
            .oup_tl_D_bits_i    (master_D_bits [i]),   
            .oup_tl_E_valid_o   (master_E_valid[i]),    
            .oup_tl_E_ready_i   (master_E_ready[i]),    
            .oup_tl_E_bits_o    (master_E_bits [i])
        );
    end
endmodule