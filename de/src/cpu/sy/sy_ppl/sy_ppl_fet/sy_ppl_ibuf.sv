// endmodule : sy_ppl_instr_buffer
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_instr_buffer.v
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

module sy_ppl_ibuf
    import sy_pkg::*;
#(
    parameter int unsigned DATA_WIDTH   = 32,   // default data width if the fifo is of type logic
    parameter int unsigned FIFO_DEPTH   = 8,    // depth can be arbitrary from 0 to 2**32
    parameter type dtype                = logic [DATA_WIDTH-1:0],
    parameter int unsigned ADDR_DEPTH   = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1
)(
    // -------------------------------------
    // [clock & reset]
    input   logic                           clk_i,
    input   logic                           rst_i,
    // -------------------------------------
    // [input data]
    input   logic                           clr_i,
    // write two data at most
    input   logic                           push_i,
    input   dtype                           data_i,              
    output  logic                           full_o,                  
    // read one data at a time
    input   logic                           pop_i,                   
    output  dtype                           data_o,                  
    output  logic                           empty_o                     
);

// =====================================================================================================================
// Local parameters

// =====================================================================================================================
// Local variables

logic [ADDR_DEPTH:0]                        ins_idx_d, ins_idx_q;
dtype [FIFO_DEPTH-1:0]                      instr_buf_d,instr_buf_q;
// =====================================================================================================================
// Instances

// ------------------
// Instruction buffer
// -- It is a compressed buffer
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
            instr_buf_q[i] <= `TCQ dtype'(0);
        end
        ins_idx_q <= `TCQ ADDR_DEPTH'(0);
    end else begin
        for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
            instr_buf_q[i] <= `TCQ instr_buf_d[i];
        end
        ins_idx_q <= `TCQ ins_idx_d;
    end
end

always_comb begin : ins_idx
    ins_idx_d = ins_idx_q;
    if (clr_i) begin
        ins_idx_d = ADDR_DEPTH'(0);
    end else if (push_i && pop_i) begin  // both rd_en and wr_en
        ins_idx_d = ins_idx_q;
    end else if (pop_i) begin     // -1
        ins_idx_d = ins_idx_q - 1;
    end else if (push_i) begin
        ins_idx_d = ins_idx_q + 1; // +1
    end
end

always_comb begin : ibuf
    instr_buf_d = instr_buf_q;
    for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
        if (pop_i) begin
            if (i < (ins_idx_q - 1) && i < (FIFO_DEPTH- 1)) begin
                instr_buf_d[i] = instr_buf_q[i+1];  // make buf compressed
            end else if (i == (ins_idx_q - 1) && push_i && i < (FIFO_DEPTH- 1))begin
                instr_buf_d[i] = data_i;
            end
        end else begin
            if (i == ins_idx_q && push_i) begin
                instr_buf_d[i] = data_i;
            end
        end
    end
end

// ibuf output
assign full_o       = ins_idx_q == FIFO_DEPTH;
assign empty_o      = ins_idx_q == 0;
assign data_o       = instr_buf_q[0];

// =====================================================================================================================
// Assertions

// =====================================================================================================================
// Probes

// synopsys translate_off

// synopsys translate_on

endmodule 