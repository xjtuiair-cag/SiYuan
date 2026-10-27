// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fpu.v
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

module sy_ppl_fpu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,         // 2x 
    input   logic                           clk_fpu_i,     // 1x
    // -- <reset>
    input   logic                           rst_i,                      

    input   logic                           flush_i,

    input   logic                           dec_fpu__valid_i,
    output  logic                           fpu_dec__ready_o,
    input   fpu_opcode_t                    dec_fpu__opcode_i,

    input   logic[DWTH-1:0]                 dec_fpu__rs1_data_i,
    input   logic[DWTH-1:0]                 dec_fpu__rs2_data_i,
    input   logic[DWTH-1:0]                 dec_fpu__rs3_data_i,
    // from decode stage
    input   logic[1:0]                      dec_fpu__fmt_i,
    input   logic[2:0]                      dec_fpu__rm_i,
    // from csr 
    input   logic[2:0]                      csr_fpu__frm_i,
    input   logic[6:0]                      csr_fpu__prec_i,
    // to decode stage
    output  logic[FLEN-1:0]                 fpu_dec__result_o,
    output  logic[4:0]                      fpu_dec__status_o,
    output  logic                           fpu_dec__valid_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================

fu_data_t fpu_data;
exception_t fpu_exception;
//====================================================================================================================== 
// Wire & Reg declaration
//======================================================================================================================

//======================================================================================================================
// Instance
//======================================================================================================================
always_comb begin : gen_fpu_data
    fpu_data.operator = dec_fpu__opcode_i;
    fpu_data.operand_a = dec_fpu__rs1_data_i;
    fpu_data.operand_b = dec_fpu__rs2_data_i;
    fpu_data.imm = dec_fpu__rs3_data_i;
    fpu_data.trans_id = TRANS_ID_BITS'(0);
    fpu_data.fu = FPU;
    if(dec_fpu__opcode_i == FADD) begin
        fpu_data.operand_a = 64'h0;
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FSUB) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FSQRT) begin
        fpu_data.operand_b = 64'h0;
    end
    if(dec_fpu__opcode_i == FMV_X2F ||  dec_fpu__opcode_i == FMV_F2X  || dec_fpu__opcode_i == FCLASS) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FCVT_F2F || dec_fpu__opcode_i == FCVT_F2I || dec_fpu__opcode_i == FCVT_I2F) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
    end

end

logic       fpu_valid_dly;
fu_data_t   fpu_data_dly;
logic[1:0]  fpu_fmt_dly;
logic[2:0]  fpu_rm_dly;
logic[2:0]  fpu_frm_dly;
logic[6:0]  fpu_prec_dly;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        fpu_valid_dly   <= 1'b0;
        fpu_data_dly    <= fu_data_t'(0);
        fpu_fmt_dly     <= 2'b0;
        fpu_rm_dly      <= 3'b0;
        fpu_frm_dly     <= 3'b0;
        fpu_prec_dly    <= 7'b0;
    end else begin
        fpu_valid_dly   <= dec_fpu__valid_i;
        fpu_data_dly    <= fpu_data;
        fpu_fmt_dly     <= dec_fpu__fmt_i;
        fpu_rm_dly      <= dec_fpu__rm_i;
        fpu_frm_dly     <= csr_fpu__frm_i;
        fpu_prec_dly    <= csr_fpu__prec_i;
    end
end

logic fpu_valid_clk1x;
logic fpu_flush_clk1x;
cdc_pulse2pulse valid_pluse2pluse(
    // Clock and reset
    .a_clk_i    (clk_i),          // Clock for domain A (input pulse domain)
    .a_rst_i    (rst_i),          // Reset for domain A
    .b_clk_i    (clk_fpu_i),      // Clock for domain B (output pulse domain)
    .b_rst_i    (rst_i),          // Reset for domain B
    // Port A - Input pulse
    .a_sig_i    (fpu_valid_dly),  // Single-cycle pulse input in domain A
    // Port B - Output pulse
    .b_sig_o    (fpu_valid_clk1x) // Single-cycle pulse output in domain B
);

cdc_pulse2pulse flush_pluse2pluse(
    // Clock and reset
    .a_clk_i    (clk_i),          // Clock for domain A (input pulse domain)
    .a_rst_i    (rst_i),          // Reset for domain A
    .b_clk_i    (clk_fpu_i),      // Clock for domain B (output pulse domain)
    .b_rst_i    (rst_i),          // Reset for domain B
    // Port A - Input pulse
    .a_sig_i    (flush_i),        // Single-cycle pulse input in domain A
    // Port B - Output pulse
    .b_sig_o    (fpu_flush_clk1x) // Single-cycle pulse output in domain B
);

fu_data_t   fpu_data_clk1x;
logic[1:0]  fpu_fmt_clk1x;
logic[2:0]  fpu_rm_clk1x;
logic[2:0]  fpu_frm_clk1x;
logic[6:0]  fpu_prec_clk1x;

//clk 1x
always_ff @(`DFF_CR(clk_fpu_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        fpu_data_clk1x <= `TCQ fu_data_t'(0);
        fpu_fmt_clk1x  <= `TCQ 2'b0;
        fpu_rm_clk1x   <= `TCQ 3'b0;
        fpu_frm_clk1x  <= `TCQ 3'b0;
        fpu_prec_clk1x <= `TCQ 7'b0;
    end else begin
        fpu_data_clk1x <= `TCQ fpu_data_dly;
        fpu_fmt_clk1x  <= `TCQ fpu_fmt_dly;
        fpu_rm_clk1x   <= `TCQ fpu_rm_dly;
        fpu_frm_clk1x  <= `TCQ fpu_frm_dly;
        fpu_prec_clk1x <= `TCQ fpu_prec_dly;
    end
end

logic               fpu_res_valid_clk1x;
logic[4:0]          fpu_status_clk1x;
logic[FLEN-1:0]     fpu_res_clk1x;
logic               fpu_ready_clk1x;
fpu_wrap fpu(
   .clk_i                  (clk_fpu_i),   
   .rst_ni                 (rst_i),    
   .flush_i                (fpu_flush_clk1x),     
   .fpu_valid_i            (fpu_valid_clk1x),         
   .fpu_ready_o            (fpu_ready_clk1x),         
   .fu_data_i              (fpu_data_clk1x),       

   .fpu_fmt_i              (fpu_fmt_clk1x),       
   .fpu_rm_i               (fpu_rm_clk1x),      
   .fpu_frm_i              (fpu_frm_clk1x),       
   .fpu_prec_i             (fpu_prec_clk1x),        
   .fpu_trans_id_o         (),            
   .result_o               (fpu_res_clk1x),      
   .fpu_valid_o            (fpu_res_valid_clk1x),         
   .fpu_status_o           (fpu_status_clk1x)         
);
// output 
logic tff_q; 
logic tff_q_dly;
logic tff_q_dly0,tff_q_dly1,tff_q_dly2;
logic fpu_res_mask;
logic fpu_ready_0;
logic fpu_ready_1;
//clk 1x
always_ff @(`DFF_CR(clk_fpu_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        tff_q <= `TCQ 1'b0;
    end else begin
        tff_q <= `TCQ ~tff_q;
    end
end
// clk 2x
always_ff @(posedge clk_fpu_i) begin
    tff_q_dly <= tff_q;
end

always_ff @(posedge clk_i) begin
    tff_q_dly0 <= tff_q_dly;
    tff_q_dly1 <= tff_q_dly0;
    tff_q_dly2 <= tff_q_dly1;
end

always_ff @(posedge clk_i) begin
    fpu_res_mask <= ~(tff_q_dly0 ^ tff_q_dly1);
end

// result to clk 2x
always_ff @(posedge clk_i) begin
    fpu_dec__valid_o    <= fpu_res_valid_clk1x & fpu_res_mask;
    fpu_dec__result_o   <= fpu_res_clk1x & {FLEN{fpu_res_mask}};
    fpu_dec__status_o   <= fpu_status_clk1x & {5{fpu_res_mask}};
    fpu_ready_0         <= fpu_ready_clk1x;
    fpu_ready_1         <= fpu_ready_0;
end
assign fpu_dec__ready_o = fpu_ready_1;

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
// (* mark_debug = "true" *) logic         prb_fpu_valid_1x;
// (* mark_debug = "true" *) logic[63:0]   prb_fpu_opa_1x;
// (* mark_debug = "true" *) logic[63:0]   prb_fpu_opb_1x;
// (* mark_debug = "true" *) logic         prb_fpu_res_valid_1x;
// (* mark_debug = "true" *) logic[63:0]   prb_fpu_res_1x;
// assign prb_fpu_valid_1x     = fpu_valid_clk1x;
// assign prb_fpu_opa_1x       = fpu_data_clk1x.operand_a;
// assign prb_fpu_opb_1x       = fpu_data_clk1x.operand_b;
// assign prb_fpu_res_valid_1x = fpu_res_valid_clk1x;
// assign prb_fpu_res_1x       = fpu_res_clk1x;

// (* mark_debug = "true" *) logic         prb_fpu_clk1x;
// (* mark_debug = "true" *) logic         prb_fpu_clk2x;
// (* mark_debug = "true" *) logic         prb_fpu_mask;
// (* mark_debug = "true" *) logic         prb_fpu_res_valid_2x;
// (* mark_debug = "true" *) logic[63:0]   prb_fpu_res_2x;

// assign prb_fpu_clk1x    = clk_fpu_i;
// assign prb_fpu_clk2x    = clk_i;
// assign prb_fpu_res_valid_2x = fpu_dec__valid_o;
// assign prb_fpu_res_2x   = fpu_dec__result_o;      
// assign prb_fpu_mask     = fpu_res_mask;

endmodule : sy_ppl_fpu