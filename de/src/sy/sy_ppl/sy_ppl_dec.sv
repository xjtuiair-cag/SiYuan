// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_dec.v
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

module sy_ppl_dec
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset $ flush]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [irq signals]
    input   intr_ctrl_t                     intr_ctrl_i,
    // ====================================
    // [from csr]
    input   priv_lvl_t                      csr_dec__priv_lvl_i,
    input   xs_t                            csr_dec__fs_i,
    input   logic[2:0]                      csr_dec__frm_i,
    input   logic                           csr_dec__tvm_i,
    input   logic                           csr_dec__tw_i,
    input   logic                           csr_dec__tsr_i, 
    input   logic                           csr_dec__debug_mode_i,    
    // =====================================
    // [from fronted]
    input   logic                           fet_dec__vld_i,
    output  logic                           dec_fet__rdy_o,

    input   logic[AWTH-1:0]                 fet_dec__npc_i,
    input   logic[AWTH-1:0]                 fet_dec__pc_i,
    input   logic[IWTH-1:0]                 fet_dec__instr_i,
    input   logic                           fet_dec__is_compressed_i,
    input   excp_t                          fet_dec__excp_i,
    // ====================================
    // [from ROB]
    input   logic                           rob_update_arat_en_i,    
    input   logic                           rob_update_fp_reg_i,
    input   logic[4:0]                      rob_update_arat_arc_i,
    input   logic[PHY_REG_WTH-1:0]          rob_update_arat_phy_i,
    input   logic[PHY_REG_WTH-1:0]          rob_update_arat_old_phy_i,
    // ====================================
    // [To Dispatch]
    output  logic                           dec_dis__vld_o,
    input   logic                           dis_dec__rdy_i,
    output  dispatch_t                      dec_dis__data_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                            decode_act;        
    logic                            decode_act_dly;    
    issue_type_e                     issue_type;
    instr_cls_e                      instr_cls;
    logic[4:0]                       arc_rs1_idx;
    logic[4:0]                       arc_rs2_idx;
    logic[4:0]                       arc_rs3_idx;
    logic[4:0]                       arc_rdst_idx;

    logic[PHY_REG_WTH-1:0]           phy_rs1_idx;
    logic[PHY_REG_WTH-1:0]           phy_rs2_idx;
    logic[PHY_REG_WTH-1:0]           phy_rs3_idx;
    logic[PHY_REG_WTH-1:0]           phy_rdst_idx;
    logic[PHY_REG_WTH-1:0]           phy_old_rdst_idx;

    logic                            rs1_is_en;
    logic                            rs2_is_en;
    logic                            rs3_is_en;
    logic                            rdst_is_en;    
    logic                            rs1_is_fp;             
    logic                            rs2_is_fp;
    logic                            rdst_is_fp;
    exu_cmd_t                        exu_cmd;
    lsu_cmd_t                        lsu_cmd;
    csr_cmd_t                        csr_cmd;
    sys_cmd_t                        sys_cmd;
    excp_t                           excp;
    dispatch_t                       dispatch_data,dispatch_data_dly;
    logic                            fl_stall;
    logic                            completed;      
    logic                            excp_is_intr;  
    logic                            dec_stall;
    logic                            dec_act_unkilled;
    logic                            dec_act;
    logic                            dec_avail;
    logic                            dec_accpt;
    logic[IWTH-1:0]                  dec_instr;
    logic[AWTH-1:0]                  dec_pc;
    logic[AWTH-1:0]                  dec_npc;
    logic                            dec_is_c;
    excp_t                           dec_excp;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign dec_stall = fl_stall;
    assign dec_kill = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            dec_act_unkilled <= `TCQ 1'b0;
        end else begin
            dec_act_unkilled <= `TCQ dec_accpt ? fet_dec__vld_i : dec_act;
        end
    end
    assign dec_act   = dec_act_unkilled && !dec_kill;
    assign dec_avail = dec_act && !dec_stall && dis_dec__rdy_i;
    assign dec_accpt = !dec_act || dec_avail;

    assign dec_fet__rdy_o = dec_accpt;
    // send valid signal to dispatch stage
    assign dec_dis__vld_o = dec_avail;

    // save instr from fet stage
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            dec_instr     <= `TCQ '0;        
            dec_pc        <= `TCQ '0;     
            dec_npc       <= `TCQ '0;      
            dec_is_c      <= `TCQ '0;       
            dec_excp      <= `TCQ '0;       
        end else begin
            if (dec_fet__rdy_o) begin
                dec_instr     <= `TCQ fet_dec__instr_i;        
                dec_pc        <= `TCQ fet_dec__pc_i;     
                dec_npc       <= `TCQ fet_dec__npc_i;      
                dec_is_c      <= `TCQ fet_dec__is_compressed_i;       
                dec_excp      <= `TCQ fet_dec__excp_i;       
            end
        end
    end

    // Stage0 : decode instr and rename registers
    sy_ppl_decoder decoder_inst(
        .clk_i                       (clk_i),                      
        .rst_i                       (rst_i),                      

        .intr_ctrl_i                 (intr_ctrl_i),      

        .csr_dec__priv_lvl_i         (csr_dec__priv_lvl_i   ),              
        .csr_dec__fs_i               (csr_dec__fs_i         ),        
        .csr_dec__frm_i              (csr_dec__frm_i        ),         
        .csr_dec__tvm_i              (csr_dec__tvm_i        ),         
        .csr_dec__tw_i               (csr_dec__tw_i         ),        
        .csr_dec__tsr_i              (csr_dec__tsr_i        ),          
        .csr_dec__debug_mode_i       (csr_dec__debug_mode_i ),                    

        .fet_dec__instr_i            (dec_instr             ),           
        .fet_dec__excp_i             (dec_excp              ),          
        .fet_dec__is_c_i             (dec_is_c              ),

        .arc_rs1_idx_o               (arc_rs1_idx       ),        
        .arc_rs2_idx_o               (arc_rs2_idx       ),        
        .arc_rs3_idx_o               (arc_rs3_idx       ),          
        .arc_rdst_idx_o              (arc_rdst_idx      ),         

        .arc_rs1_en_o                (rs1_is_en),       
        .arc_rs2_en_o                (rs2_is_en),       
        .arc_rs3_en_o                (rs3_is_en),         
        .arc_rdst_en_o               (rdst_is_en),        
        .rs1_is_fp_o                 (rs1_is_fp),    
        .rs2_is_fp_o                 (rs2_is_fp),    
        .rdst_is_fp_o                (rdst_is_fp),     
        .completed_o                 (completed),
        .excp_is_intr_o              (excp_is_intr),

        .issue_type_o                (issue_type),          
        .instr_cls_o                 (instr_cls),       

        .exu_cmd_o                   (exu_cmd),       
        .lsu_cmd_o                   (lsu_cmd),
        .csr_cmd_o                   (csr_cmd),
        .sys_cmd_o                   (sys_cmd),       

        .excp_o                      (excp) 
    );

    sy_ppl_rename rename_inst(
        .clk_i                       (clk_i),                         
        .rst_i                       (rst_i),                         

        .flush_i                     (flush_i),     
        .fl_stall_o                  (fl_stall),
        .instr_act_i                 (dec_avail),    
        .arc_rs1_idx_i               (arc_rs1_idx),            
        .arc_rs2_idx_i               (arc_rs2_idx),            
        .arc_rs3_idx_i               (arc_rs3_idx),            
        .arc_rdst_idx_i              (arc_rdst_idx),             

        .rs1_is_en_i                 (rs1_is_en),
        .rs2_is_en_i                 (rs2_is_en),
        .rs3_is_en_i                 (rs3_is_en),
        .rdst_is_en_i                (rdst_is_en),         

        .rs1_is_fp_i                 (rs1_is_fp),           
        .rs2_is_fp_i                 (rs2_is_fp),           
        .rdst_is_fp_i                (rdst_is_fp),          

        .phy_rs1_idx_o               (phy_rs1_idx),           
        .phy_rs2_idx_o               (phy_rs2_idx),           
        .phy_rs3_idx_o               (phy_rs3_idx),           
        .phy_rdst_idx_o              (phy_rdst_idx),            
        .phy_old_rdst_idx_o          (phy_old_rdst_idx),                

        .rob_update_arat_en_i        (rob_update_arat_en_i     ),                      
        .rob_update_fp_reg_i         (rob_update_fp_reg_i     ),
        .rob_update_arat_arc_i       (rob_update_arat_arc_i    ),                   
        .rob_update_arat_phy_i       (rob_update_arat_phy_i    ),                   
        .rob_update_arat_old_phy_i   (rob_update_arat_old_phy_i)
    );

    assign dispatch_data.issue_type       = issue_type; 
    assign dispatch_data.instr_cls        = instr_cls; 
    assign dispatch_data.exu_cmd          = exu_cmd; 
    assign dispatch_data.csr_cmd          = csr_cmd;
    assign dispatch_data.lsu_cmd          = lsu_cmd; 
    assign dispatch_data.sys_cmd          = sys_cmd; 
    assign dispatch_data.phy_rs1_idx      = phy_rs1_idx; 
    assign dispatch_data.phy_rs2_idx      = phy_rs2_idx; 
    assign dispatch_data.phy_rs3_idx      = phy_rs3_idx; 
    assign dispatch_data.phy_rdst_idx     = phy_rdst_idx; 
    assign dispatch_data.arc_rdst_idx     = arc_rdst_idx; 
    assign dispatch_data.phy_old_rdst_idx = phy_old_rdst_idx; 
    assign dispatch_data.rs1_en           = rs1_is_en; 
    assign dispatch_data.rs2_en           = rs2_is_en; 
    assign dispatch_data.rs3_en           = rs3_is_en; 
    assign dispatch_data.rdst_en          = rdst_is_en; 
    assign dispatch_data.rs1_is_fp        = rs1_is_fp; 
    assign dispatch_data.rs2_is_fp        = rs2_is_fp; 
    assign dispatch_data.rdst_is_fp       = rdst_is_fp; 
    assign dispatch_data.pc               = dec_pc; 
    assign dispatch_data.npc              = dec_npc; 
    assign dispatch_data.excp             = excp; 
    assign dispatch_data.is_c             = dec_is_c;   // is compressed
    assign dispatch_data.is_intr          = excp_is_intr;
    assign dispatch_data.completed        = completed;
    assign dispatch_data.instr            = dec_instr;

    assign dec_dis__data_o = dispatch_data;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
logic               prb_dec_act;
logic               prb_dec_avail;
dispatch_t          prb_dispatch_data;

assign prb_dec_act  = dec_act;
assign prb_dec_avail = dec_avail;
assign prb_dispatch_data = dispatch_data;

// synopsys translate_on

(* mark_debug = "true" *) logic         prb_fet_dec_vld;
(* mark_debug = "true" *) logic         prb_fet_dec_rdy;
(* mark_debug = "true" *) logic[31:0]   prb_fet_dec_instr;
(* mark_debug = "true" *) logic[63:0]   prb_fet_dec_pc;

assign prb_fet_dec_vld = fet_dec__vld_i;
assign prb_fet_dec_rdy = dec_fet__rdy_o;
assign prb_fet_dec_instr = fet_dec__instr_i;
assign prb_fet_dec_pc = fet_dec__pc_i;

(* mark_debug = "true" *) logic         prb_dec_vld;
(* mark_debug = "true" *) logic[4:0]    prb_dec_rs1_idx;
(* mark_debug = "true" *) logic[4:0]    prb_dec_rs2_idx;
(* mark_debug = "true" *) logic[4:0]    prb_dec_rdst_idx;
(* mark_debug = "true" *) logic[63:0]   prb_dec_pc;

assign prb_dec_vld          = dec_act;
assign prb_dec_rs1_idx      = arc_rs1_idx;
assign prb_dec_rs2_idx      = arc_rs2_idx;
assign prb_dec_rdst_idx     = arc_rdst_idx;
assign prb_dec_pc           = dec_pc;

endmodule : sy_ppl_dec
