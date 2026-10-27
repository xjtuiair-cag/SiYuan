// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : rptr_empty.v
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

module rptr_empty
    import sy_pkg::*;
#(
    parameter ADDRSIZE = 4
)(
    input  logic                rclk,
    input  logic                rrst,
    input  logic                rinc,
    input  logic [ADDRSIZE  :0] rq2_wptr,
    output logic                rempty,
    output logic                arempty,
    output logic [ADDRSIZE-1:0] raddr,
    output logic [ADDRSIZE  :0] rptr
);

    logic [ADDRSIZE:0] rbin;
    logic [ADDRSIZE:0] rgraynext, rbinnext, rgraynextm1;
    logic              arempty_val, rempty_val;

    //-------------------
    // GRAYSTYLE2 pointer
    //-------------------
    always @(`DFF_CR(rclk,rrst)) begin
        if (`DFF_IS_R(rrst)) begin
            {rbin, rptr} <= 0;
        end else begin
            {rbin, rptr} <= {rbinnext, rgraynext};
        end
    end

    // Memory read-address pointer (okay to use binary to address memory)
    assign raddr     = rbin[ADDRSIZE-1:0];
    assign rbinnext  = rbin + ((rinc & ~rempty) ? 1 : 0);
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;
    assign rgraynextm1 = ((rbinnext + 1'b1) >> 1) ^ (rbinnext + 1'b1);

    //---------------------------------------------------------------
    // FIFO empty when the next rptr == synchronized wptr or on reset
    //---------------------------------------------------------------
    assign rempty_val = (rgraynext == rq2_wptr);
    assign arempty_val = (rgraynextm1 == rq2_wptr);

    always @ (`DFF_CR(rclk,rrst)) begin
        if (`DFF_IS_R(rrst)) begin
            arempty <= 1'b0;
            rempty <= 1'b1;
        end else begin
            arempty <= arempty_val;
            rempty <= rempty_val;
        end
    end

endmodule