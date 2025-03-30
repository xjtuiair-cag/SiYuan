// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_bootrom.v
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

module sy_bootrom
    import sy_pkg::*;
# (
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64
)(
  input  logic                            clk_i,
  input  logic                            rst_i,
  
  TL_BUS.Master                           master
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   rom_req;
    logic [63:0]                            rom_addr;
    logic [63:0]                            rom_rdata;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign master.b_valid = 1'b0;
    TL2Reg #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       (master.a_valid ),              
        .TL_A_ready_o       (master.a_ready ),              
        .TL_A_bits_i        (master.a_bits  ),            

        .TL_D_valid_o       (master.d_valid ),              
        .TL_D_ready_i       (master.d_ready ),              
        .TL_D_bits_o        (master.d_bits  ),            

        .addr_o             ( rom_addr      ),
        .en_o               ( rom_req       ),
        .we_o               (               ),
        .wdata_o            (               ),
        .rdata_i            ( rom_rdata     )
    );

    // ---------------
    // ROM
    // ---------------
    bootrom i_bootrom (
        .clk_i   ( clk_i     ),
        .req_i   ( rom_req   ),
        .addr_i  ( rom_addr  ),
        .rdata_o ( rom_rdata )
    ); 

endmodule