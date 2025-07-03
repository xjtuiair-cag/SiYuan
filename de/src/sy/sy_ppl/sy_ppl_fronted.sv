// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fronted.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--04--03 initial version.
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

module sy_ppl_fronted
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    input   logic                           flush_bp_i,
    // =====================================
    input   logic                           ctrl_fet__set_en_i,
    input   logic[AWTH-1:0]                 ctrl_fet__set_npc_i,
    //! Current stage works only if CTRL module sends act signal to FETCH module. If act is zero, FETCH module stop
    input   logic                           ctrl_fet__act_i,
    // =====================================
    // [to I$]
    output  fetch_req_t                     fet_icache__dreq_o,
    input   fetch_rsp_t                     icache_fet__drsp_i,
    // =====================================
    // [From ROB]
    input   bht_update_t                    rob_fet__bht_update_i,
    input   btb_update_t                    rob_fet__btb_update_i,
    // =====================================
    // [to decode stage]
    //! FETCH module should send PC, NPC, instruction content, and stage status to the succedded module.
    // using valid/ready handshake with decode stage
    output  logic                           fet_dec__vld_o,
    input   logic                           dec_fet__rdy_i,

    output  logic[AWTH-1:0]                 fet_dec__npc_o,
    output  logic[AWTH-1:0]                 fet_dec__pc_o,
    output  logic[IWTH-1:0]                 fet_dec__instr_o,
    output  logic                           fet_dec__is_compressed_o,
    output  excp_t                          fet_dec__excp_o      // exception happen in fronted
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           can_fetch_instr;
    logic                           fet_req_dly;
    logic[AWTH-1:0]                 fet_addr_d, fet_addr_q;
    logic                           icache_hit;
    logic                           fetch_valid;
    logic [1:0]                     instr_valid;
    logic [1:0][AWTH-1:0]           instr_addr;
    logic [1:0][IWTH-1:0]           instr_data;                     
    logic                           buffer_is_not_full;
    logic                           buffer_instr_valid;
    logic [AWTH-1:0]                buffer_instr_pc;
    logic [AWTH-1:0]                buffer_instr_npc;
    logic [IWTH-1:0]                buffer_instr;
    logic                           buffer_is_compressed;
    excp_t                          buffer_ex;
    logic                           flush_buffer;
    logic                           shamt;
    logic [IWTH-1:0]                fetch_data;   
    logic                           flush_fronted;
    logic                           fet_stall;                
    logic                           fet_kill;
    logic                           fet_act;
    logic                           fet_act_unkilled;
    logic                           fet_avail;
    logic                           fet_accpt;
    excp_t                          fet_excp;
    logic                           bp_valid;
    logic[AWTH-1:0]                 bp_addr;
    logic[1:0]                      fet_valid;
    logic[1:0][AWTH-1:0]            fet_pc;
    logic[1:0][AWTH-1:0]            fet_npc;
    logic[1:0]                      fet_instr_is_c;
    logic[1:0][IWTH-1:0]            fet_instr;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign flush_fronted = flush_i;

    assign fet_stall = 1'b0;
    assign fet_kill = flush_fronted || (!buffer_is_not_full) || (!icache_hit && fet_req_dly);

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            fet_act_unkilled <= `TCQ 1'b0;
        end else begin
            fet_act_unkilled <= `TCQ fet_accpt ? can_fetch_instr : fet_act;
        end
    end
    assign fet_act = fet_act_unkilled && !fet_kill;
    assign fet_avail = fet_act && !fet_stall && buffer_is_not_full;
    assign fet_accpt = !fet_act || fet_avail;

    // if control allow fetch instr and instr buffer is not full, we can send fetch request
    assign can_fetch_instr = ctrl_fet__act_i && fet_accpt && buffer_is_not_full;
    // to icache
    assign fet_icache__dreq_o.req       = can_fetch_instr && icache_fet__drsp_i.ready;  // wait for icache ready
    assign fet_icache__dreq_o.vaddr     = fet_addr_d;   // fetch address
    assign fet_icache__dreq_o.kill      = flush_fronted; // kill the current fetch 

    assign icache_hit = icache_fet__drsp_i.valid;   // icache return valid data
    assign fet_excp = icache_fet__drsp_i.ex;  // exception from I cache

    // change next pc
    always_comb begin
        // control module can set pc
        if (ctrl_fet__set_en_i) begin
            fet_addr_d = ctrl_fet__set_npc_i;
        end else if (bp_valid) begin
            fet_addr_d = bp_addr;   
        // pc will be hold if icache don't return valid data
        end else if(!fet_act) begin
            fet_addr_d = fet_addr_q;
        end else begin
            fet_addr_d = {fet_addr_q[AWTH-1:2],2'b0} + 4;
        end
    end

    assign fetch_valid = fet_req_dly && icache_hit && fet_avail;
    assign flush_buffer = flush_fronted;  // flush instr buffer
    assign shamt = fet_addr_q[1];   // offset
    assign fetch_data = icache_fet__drsp_i.data >> {shamt,4'b0};

    sy_ppl_instr_realign instr_align_inst(
        .clk_i                         (clk_i),  
        .rst_ni                        (rst_i),   
        .flush_i                       (flush_buffer || bp_valid),    
        .valid_i                       (fetch_valid),    
        .serving_unaligned_o           (),                 // we have an unaligned instruction in [0]
        .address_i                     (fet_addr_q),      
        .data_i                        (fetch_data),   
        .valid_o                       (instr_valid),    
        .addr_o                        (instr_addr),   
        .instr_o                       (instr_data) 
    );

    sy_ppl_br_pred br_pred_inst(
        .clk_i                         (clk_i),                    
        .rst_i                         (rst_i),                    
        .flush_i                       (flush_bp_i),

        .instr_vld_i                   (instr_valid),    
        .instr_i                       (instr_data),
        .vaddr_i                       (instr_addr),

        .fet_pc_i                      (fet_addr_d),

        .bp_vld_o                      (bp_valid),    
        .bp_addr_o                     (bp_addr),  

        .fet_valid_o                   (fet_valid),       
        .fet_pc_o                      (fet_pc),    
        .fet_npc_o                     (fet_npc),  
        // .fet_instr_is_c_o              (fet_instr_is_c),
        // .fet_instr_o                   (fet_instr),

        .bht_update_i                  (rob_fet__bht_update_i),     
        .btb_update_i                  (rob_fet__btb_update_i)
    );

    sy_ppl_instr_buffer instr_buffer_inst(
        .clk_i                          (clk_i),  
        .rst_ni                         (rst_i),   
        .flush_i                        (flush_buffer),    
        .fet_valid_i                    (fet_valid),        
        .fet_pc_i                       (fet_pc),       
        .fet_npc_i                      (fet_npc),       
        .fet_instr_i                    (instr_data),        
        // .fet_instr_is_c_i               (fet_instr_is_c),
        .fet_ex_i                       (fet_excp.valid && !flush_i),       // exception    
        .ready_o                        (buffer_is_not_full),   // buffer is not full   
        // handshake between fronted and decode
        .dec_ready_i                    (dec_fet__rdy_i),        
        .dec_valid_o                    (buffer_instr_valid),        
        // data to decode
        .dec_pc_o                       (buffer_instr_pc),     
        .dec_npc_o                      (buffer_instr_npc),      
        .dec_instr_o                    (buffer_instr),        
        .dec_is_compressed_o            (buffer_is_compressed),
        .dec_ex_o                       (buffer_ex)                 
    );
    // send instr and pc to decode stage
    assign fet_dec__vld_o           = buffer_instr_valid;
    assign fet_dec__npc_o           = buffer_instr_npc;
    assign fet_dec__pc_o            = buffer_instr_pc;
    assign fet_dec__instr_o         = buffer_instr;
    assign fet_dec__is_compressed_o = buffer_is_compressed;
    assign fet_dec__excp_o          = buffer_ex;   

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            fet_req_dly <= `TCQ 1'b0;
            // fet_addr_q  <= `TCQ '0;
        end else begin
            fet_req_dly <= `TCQ can_fetch_instr;
            // fet_addr_q  <= `TCQ fet_addr_d;
        end
    end

    always_ff @(posedge clk_i) begin
        if(fet_accpt) begin
            fet_addr_q <= `TCQ fet_addr_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
logic               prb_fet_act;
logic               prb_fet_req;
logic[AWTH-1:0]     prb_fet_vaddr;
logic               prb_fet_dec_vld;   
logic               prb_fet_dec_rdy;   
logic[IWTH-1:0]     prb_fet_dec_instr;
logic[AWTH-1:0]     prb_fet_dec_pc;

assign prb_fet_act = fet_act;
assign prb_fet_req = fet_icache__dreq_o.req;
assign prb_fet_vaddr = fet_icache__dreq_o.vaddr;
assign prb_fet_dec_vld = fet_dec__vld_o;
assign prb_fet_dec_rdy = dec_fet__rdy_i;
assign prb_fet_dec_instr = fet_dec__instr_o;
assign prb_fet_dec_pc = fet_dec__pc_o;


// synopsys translate_on



endmodule : sy_ppl_fronted
