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
    input   logic                           clk_i,                      
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
    fpu_data.trans_id = '0;
    fpu_data.fu = FPU;
    if(dec_fpu__opcode_i == FADD) begin
        fpu_data.operand_a = '0;
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FSUB) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FSQRT) begin
        fpu_data.operand_b = '0;
    end
    if(dec_fpu__opcode_i == FMV_X2F ||  dec_fpu__opcode_i == FMV_F2X  || dec_fpu__opcode_i == FCLASS) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
        fpu_data.imm = dec_fpu__rs2_data_i;
    end
    if(dec_fpu__opcode_i == FCVT_F2F || dec_fpu__opcode_i == FCVT_F2I || dec_fpu__opcode_i == FCVT_I2F) begin
        fpu_data.operand_b = dec_fpu__rs1_data_i;
    end

end

assign fpu_dec__status_o = fpu_exception.cause[4:0];

fpu_wrap fpu(
   .clk_i                  (clk_i),   
   .rst_ni                 (rst_i),    
   .flush_i                (flush_i),     
   .fpu_valid_i            (dec_fpu__valid_i),         
   .fpu_ready_o            (fpu_dec__ready_o),         
   .fu_data_i              (fpu_data),       

   .fpu_fmt_i              (dec_fpu__fmt_i),       
   .fpu_rm_i               (dec_fpu__rm_i),      
   .fpu_frm_i              (csr_fpu__frm_i),       
   .fpu_prec_i             (csr_fpu__prec_i),        
   .fpu_trans_id_o         ('0),            
   .result_o               (fpu_dec__result_o),      
   .fpu_valid_o            (fpu_dec__valid_o),         
   .fpu_exception_o        (fpu_exception)         
);


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_fpu
