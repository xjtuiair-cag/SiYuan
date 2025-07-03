// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_csr.v
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

module sy_ppl_csr
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From Dispatch]
    input   logic                           dis_csr__vld_i,          
    output  logic                           csr_dis__rdy_o,          
    input   csr_packet_t                    dis_csr__packet_i,
    // =====================================
    // [Read GPR Register]
    output  logic[PHY_REG_WTH-1:0]          gpr_rs1_idx_o,
    input   logic[DWTH-1:0]                 gpr_rs1_data_i,
    // =====================================
    // [Write GPR Register] 
    output  logic                           gpr_wr_en_o,
    output  logic[PHY_REG_WTH-1:0]          gpr_wr_idx_o,
    output  logic[DWTH-1:0]                 gpr_wr_data_o,
    // =====================================
    // [Awake From LSU]
    input   logic                           lsu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          lsu_awake_idx_i,
    input   logic                           lsu_awake_is_fp_i,
    input   logic                           alu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          alu_awake_idx_i,
    input   logic                           mdu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_awake_idx_i,
    input   logic                           fpu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_awake_idx_i,
    input   logic                           fpu_awake_is_fp_i,
    // =====================================
    // [Awake TO ]
    output  logic                           csr_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          csr_awake_idx_o,
    // =====================================
    // [To CSR]
    output  csr_bus_req_t                   csr_regfile_req_o,
    output  csr_bus_wr_t                    csr_regfile_wr_o,
    input   csr_bus_rsp_t                   csr_regfile_rsp_i,
    // =====================================
    // [Commit to ROB] 
    input   logic                           rob_csr__retire_i,
    output  csr_commit_t                    csr_rob__commit_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           issue_vld;
    logic[CSR_IQ_WTH-1:0]           issue_idx;  
    logic                           issue_rdy;  
    csr_packet_t                    issue_packet;
    csr_packet_t                    issue_packet_st1;
    logic[CSR_IQ_WTH-1:0]           issue_idx_st1;  
    logic                           reg_rd_stall;
    logic                           reg_rd_act_unkilled;
    logic                           reg_rd_act;
    logic                           reg_rd_avail;
    logic                           reg_rd_accpt;
    logic[DWTH-1:0]                 rs1_reg_byp;
    csr_opcode_e                    csr_op_st2;
    logic                           csr_en_st2;
    logic                           csr_wr_en_st2;   
    logic                           csr_rd_en_st2;   
    logic[ROB_WTH-1:0]              csr_rob_idx_st2;
    logic                           csr_excp_en_st2;
    logic[DWTH-1:0]                 csr_wdata_raw_st2;
    logic[DWTH-1:0]                 csr_rdata_st2;
    logic[CSR_IQ_WTH-1:0]           csr_iq_idx_st2;
    logic[PHY_REG_WTH-1:0]          csr_rdst_idx_st2;

    logic                           csr_wr_en;
    logic[DWTH-1:0]                 csr_wdata;            
    logic[CSR_IQ_WTH-1:0]           csr_wr_iq_idx;
//======================================================================================================================
// Stage0 : Issue Queen
//======================================================================================================================
    // Stage 0 : Issue Queen
    sy_ppl_csr_iq csr_iq_inst(
        .clk_i                  (clk_i),                           
        .rst_i                  (rst_i),                           
        .flush_i                (flush_i),       

        .dis_csr__vld_i         (dis_csr__vld_i),                        
        .csr_dis__rdy_o         (csr_dis__rdy_o),                        
        .dis_csr__packet_i      (dis_csr__packet_i),                 

        .issue_vld_o            (issue_vld   ),           
        .issue_idx_o            (issue_idx   ),
        .issue_rdy_i            (issue_rdy   ),           
        .issue_packet_o         (issue_packet),              

        .csr_wr_en_i            (csr_wr_en),        
        .csr_wr_idx_i           (csr_wr_iq_idx),         
        .csr_wdata_i            (csr_wdata),        
        .csr_regfile_wr_o       (csr_regfile_wr_o),
        .rob_csr__retire_i      (rob_csr__retire_i),
        // awake from alu
        .alu_awake_vld_i        (alu_awake_vld_i  ),               
        .alu_awake_idx_i        (alu_awake_idx_i  ),               
        // awake from csr
        .csr_awake_vld_i        (csr_awake_vld_o  ),               
        .csr_awake_idx_i        (csr_awake_idx_o  ),               
        // awake from lsu
        .lsu_awake_vld_i        (lsu_awake_vld_i  ),               
        .lsu_awake_idx_i        (lsu_awake_idx_i  ),               
        .lsu_awake_is_fp_i      (lsu_awake_is_fp_i),                 
        // awake from mdu
        .mdu_awake_vld_i        (mdu_awake_vld_i  ),               
        .mdu_awake_idx_i        (mdu_awake_idx_i  ),               
        // awake from fpu
        .fpu_awake_vld_i        (fpu_awake_vld_i  ),               
        .fpu_awake_idx_i        (fpu_awake_idx_i  ),               
        .fpu_awake_is_fp_i      (fpu_awake_is_fp_i)
    );
//======================================================================================================================
// Stage1 : Read GPR reg
//======================================================================================================================
    // Stage 1 : Read Register
    assign reg_rd_stall = 1'b0; // TODO
    assign reg_rd_kill  = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            reg_rd_act_unkilled <= `TCQ 1'b0;
        end else begin
            reg_rd_act_unkilled <= `TCQ reg_rd_accpt ? issue_vld : reg_rd_act;
        end
    end

    assign reg_rd_act   = reg_rd_act_unkilled && !reg_rd_kill;
    assign reg_rd_avail = reg_rd_act && !reg_rd_stall;
    assign reg_rd_accpt = !reg_rd_act || reg_rd_avail;
    assign issue_rdy = reg_rd_accpt;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            issue_packet_st1 <= '0;
            issue_idx_st1    <= '0;
        end else begin
            if (reg_rd_accpt) begin
                issue_packet_st1 <= issue_packet;
                issue_idx_st1    <= issue_idx;
            end
        end
    end

    assign gpr_rs1_idx_o = issue_packet_st1.phy_rs1_idx;
    // TODO : add bypass network
    assign rs1_reg_byp = gpr_rs1_data_i;
    // query csr regfile and read data
    assign csr_regfile_req_o.csr_query_en = reg_rd_avail;
    assign csr_regfile_req_o.rd_en        = reg_rd_avail && issue_packet_st1.csr_cmd.csr_rd_en;    
    assign csr_regfile_req_o.raddr        = issue_packet_st1.csr_cmd.csr_addr;
    assign csr_regfile_req_o.is_wr        = issue_packet_st1.csr_cmd.csr_wr_en;
    assign csr_regfile_req_o.is_rd        = issue_packet_st1.csr_cmd.csr_rd_en;
//======================================================================================================================
// Stage2 : Write data to CSR Issue Queen and commit to ROB and write back to GPR  
//======================================================================================================================
     always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            csr_op_st2           <= `TCQ csr_opcode_e'('0);     
            csr_en_st2           <= `TCQ '0;    
            csr_wr_en_st2        <= `TCQ '0;          
            csr_rd_en_st2        <= `TCQ '0;          
            csr_rob_idx_st2      <= `TCQ '0;         
            csr_wdata_raw_st2    <= `TCQ '0;           
            csr_iq_idx_st2       <= `TCQ '0;
            csr_rdst_idx_st2     <= `TCQ '0;
        end else begin
            csr_op_st2           <= `TCQ issue_packet_st1.csr_cmd.csr_op;     
            csr_en_st2           <= `TCQ reg_rd_avail;    
            csr_wr_en_st2        <= `TCQ reg_rd_avail && issue_packet_st1.csr_cmd.csr_wr_en;          
            csr_rd_en_st2        <= `TCQ reg_rd_avail && issue_packet_st1.csr_cmd.csr_rd_en;          
            csr_rob_idx_st2      <= `TCQ issue_packet_st1.rob_idx;         
            csr_wdata_raw_st2    <= `TCQ issue_packet_st1.csr_cmd.with_imm ? {59'b0,issue_packet_st1.csr_cmd.csr_imm} : rs1_reg_byp;           
            csr_iq_idx_st2       <= `TCQ issue_idx_st1;
            csr_rdst_idx_st2     <= `TCQ issue_packet_st1.phy_rdst_idx;
        end
    end


    assign csr_rdata_st2 = csr_regfile_rsp_i.rdata;
    // commit to ROB
    assign csr_rob__commit_o.vld      = csr_en_st2;
    assign csr_rob__commit_o.rob_idx  = csr_rob_idx_st2;
    assign csr_rob__commit_o.excp_en  = csr_regfile_rsp_i.excp_en;
    assign csr_rob__commit_o.flush_en = csr_regfile_rsp_i.need_flush;
    // write back to CSR Issue Queen
    assign csr_wr_en = csr_wr_en_st2;
    assign csr_wr_iq_idx = csr_iq_idx_st2;
    always_comb begin
        csr_wdata = '0;
        case (csr_op_st2)
            CSR_RW : begin
                csr_wdata = csr_wdata_raw_st2;     
            end
            CSR_RS:begin
                // this is very ensential
                csr_wdata = csr_wdata_raw_st2 | csr_rdata_st2;                   
            end 
            CSR_RC: begin
                csr_wdata = ~csr_wdata_raw_st2 & csr_rdata_st2;                   
            end
            default: ;
        endcase
    end
    // write back to GPR
    assign gpr_wr_en_o   = csr_rd_en_st2;
    assign gpr_wr_data_o = csr_rdata_st2;
    assign gpr_wr_idx_o  = csr_rdst_idx_st2;
    // awake
    assign csr_awake_vld_o = gpr_wr_en_o;
    assign csr_awake_idx_o = gpr_wr_idx_o;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_csr
