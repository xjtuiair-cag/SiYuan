// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_ras.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : quick decoder 
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

module sy_ppl_ras
    import sy_pkg::*;
#(
    parameter DEPTH = 4
)(
    // =====================================
    // [clock & reset & flush]
    input  logic                        clk_i,
    input  logic                        rst_i,
    input  logic                        flush_i,
    // =====================================
    // [from fronted]
    input  logic                        push_i,
    input  logic                        pop_i,
    input  logic [AWTH-1:0]             data_i,
    // =====================================
    // [to fronted]
    output ras_t                        data_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    ras_t[DEPTH-1:0]        ras_stack_d, ras_stack_q;
//======================================================================================================================
// Instance
//======================================================================================================================

    assign data_o = ras_stack_q[0];

    always_comb begin
        ras_stack_d = ras_stack_q;
        // push on the ras_stack
        if (push_i) begin
            ras_stack_d[0].ra = data_i;
            // mark the new return address as valid
            ras_stack_d[0].vld = 1'b1;
            ras_stack_d[DEPTH-1:1] = ras_stack_q[DEPTH-2:0];
        end

        if (pop_i) begin
            ras_stack_d[DEPTH-2:0] = ras_stack_q[DEPTH-1:1];
            // we popped the value so invalidate the end of the ras_stack
            ras_stack_d[DEPTH-1].vld = 1'b0;
            ras_stack_d[DEPTH-1].ra = 'b0;
        end
        // leave everything untouched and just push the latest value to the
        // top of the ras_stack
        if (pop_i && push_i) begin
           ras_stack_d = ras_stack_q;
           ras_stack_d[0].ra  = data_i;
           ras_stack_d[0].vld = 1'b1;
        end

        if (flush_i) begin
          ras_stack_d = '0;
        end
    end
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            ras_stack_q <= '0;
        end else begin
            ras_stack_q <= ras_stack_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule
