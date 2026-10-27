// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sync_ptr.v
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

module sync_ptr
    import sy_pkg::*;
#(
    parameter ASIZE = 4
)(
    input  wire           dest_clk,
    input  wire           dest_rst,
    input  wire [ASIZE:0] src_ptr,
    output reg  [ASIZE:0] dest_ptr
);

    reg [ASIZE:0] ptr_x;

    always @(`DFF_CR(dest_clk,dest_rst)) begin
        if (`DFF_IS_R(dest_rst)) begin
            {dest_ptr,ptr_x} <= 0;
        end else begin
            {dest_ptr,ptr_x} <= {ptr_x,src_ptr};
        end
    end

endmodule