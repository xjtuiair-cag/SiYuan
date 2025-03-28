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
    TL_BUS.Master                               master[MASTER_NUM-1:0],
    TL_BUS.Slave                                slave[SLAVE_NUM-1:0],
    // Memory map
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0] start_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0] end_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                    region_en_i 
);

    TL_BUS tl_slave  [SLAVE_NUM-1:0]();

    TL_BUS tl_master [MASTER_NUM-1:0]();

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
        .clk_i          ( clk_i           ),
        .rst_i          ( rst_i         ),
        .master         ( tl_master    ),
        .slave          ( tl_slave     ),
        .start_addr_i   ( start_addr_i  ),
        .end_addr_i     ( end_addr_i    ),
        .region_en_i    ( region_en_i   )
    );

    for (genvar i = 0; i < SLAVE_NUM; i++) begin : tl_buffer_slave
        tl_buffer #(
            .BUF_DEPTH  ( SLAVE_BUF_DEPTH)
        ) i_tl_slave_buf (
            .clk_i      ( clk_i         ),
            .rst_i      ( rst_i         ),
            .in         ( tl_slave[i]  ), 
            .out        ( slave[i]     )  
        );
    end

    for (genvar i = 0; i < MASTER_NUM; i++) begin : tl_buffer_master
        tl_buffer #(
            .BUF_DEPTH  ( MASTER_BUF_DEPTH)
        ) i_tl_master_buf (
            .clk_i      ( clk_i         ),
            .rst_i      ( rst_i         ),
            .in         ( master[i]      ), 
            .out        ( tl_master[i]   )  
        );
    end
endmodule