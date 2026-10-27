// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : cdc_sync.sv
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

module cdc_sync # (
    parameter type DTYPE = logic,
    parameter integer DLY = 2,
    parameter RST_VAL = 0
) (
    // clock & reset
    input   logic                           clk_i,
    input   logic                           rst_i,
    // data need to be synchronized
    input   DTYPE                           data_i,
    output  DTYPE                           data_o
);

// =====================================================================================================================
// Local parameters

localparam DWTH = $bits(DTYPE);

// =====================================================================================================================
// Local variables

(* dont_touch = "true" *) (* async_reg = "true" *)
logic[DLY-1:0][DWTH-1:0]        data_sync;

// =====================================================================================================================
// Instances

// Alternative implementation
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        for(integer i=0; i<DLY; i++) begin
            data_sync[i] <= `TCQ DTYPE'(RST_VAL);
        end
    end else begin
        data_sync <= `TCQ {data_sync, DWTH'(data_i)};
    end
end
assign data_o = DTYPE'(data_sync[DLY-1]);

// =====================================================================================================================
// Assertions

// =====================================================================================================================
// Probes

// synopsys translate_off

// synopsys translate_on

endmodule : cdc_sync
