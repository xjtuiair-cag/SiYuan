// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sync_rstgen.v
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

module sync_rstgen#(
    parameter RESET_VALUE = "LOW",
    parameter NumRegs = 2
) (
    input  logic clk_i,
    input  logic rst_i,
    output logic rst_o
);

    if (RESET_VALUE == "LOW") begin
        // internal reset
        logic rst_n;
        logic [NumRegs-1:0] synch_regs_q;

        // bypass mode
        assign rst_n   = rst_i;
        assign rst_o  = synch_regs_q[NumRegs-1];

        always_ff @(posedge clk_i or negedge rst_n) begin
            if (~rst_n) begin
                synch_regs_q <= 0;
            end else begin
                synch_regs_q <= {synch_regs_q[NumRegs-2:0], 1'b1};
            end
        end
    end else begin // active high
         // internal reset
        logic rst;
        logic [NumRegs-1:0] synch_regs_q;

        // bypass mode
        assign rst   = rst_i;
        assign rst_o = synch_regs_q[NumRegs-1];

        always_ff @(posedge clk_i or posedge rst) begin
            if (rst) begin
                synch_regs_q <= 2'b11;
            end else begin
                synch_regs_q <= {synch_regs_q[NumRegs-2:0], 1'b0};
            end
        end
       
    end

endmodule
