// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_L1_cache.v
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

module sy_L1_cache  
  import sy_pkg::*;
#(
  parameter                             HART_ID_WTH  = 1,
  parameter logic [HART_ID_WTH-1:0]     HART_ID      = 0,
  parameter                             ADDR_WTH     = 64,
  parameter                             REQ_PORT     = 2            
) (
  input  logic                            clk_i,
  input  logic                            rst_i,
  input  logic                            flush_icache_i,  
  output logic                            flush_icache_done_o,
  input  logic                            flush_dcache_i,  
  output logic                            flush_dcache_done_o,
  input  logic                            invalid_dcache_i,

  output logic                            dcache_ctrl_idle_o,
  output logic                            icache_ctrl_idle_o,

  // data requests
  input  logic                            fetch_icache__kill_i,
  input  logic                            fetch_icache__req_i,
  output logic                            icache_fetch__rsp_o,
  input  fetch_req_t                      fetch_icache__req_bits_i,
  output fetch_rsp_t                      icache_fetch__rsp_bits_o,
  // =====================================
  // [D cache req from ppl]
  input  logic                            ppl_dmem__kill_i,
  input  logic                            ppl_dmem__req_i,
  output logic                            dmem_ppl__rsp_o,
  input  dcache_req_t                     ppl_dmem__req_bits_i,
  output dcache_rsp_t                     dmem_ppl__rsp_bits_o,  
  // =====================================
  // [D cache req from mmu]
  input  logic                            mmu_dmem__req_i,
  output logic                            dmem_mmu__rsp_o,
  input  dcache_req_t                     mmu_dmem__req_bits_i,
  output dcache_rsp_t                     dmem_mmu__rsp_bits_o,  
  // TL A
  output logic                            L1_tl_A_valid_o, 
  input  logic                            L1_tl_A_ready_i, 
  output tl_pkg::A_chan_bits_t            L1_tl_A_bits_o,
  // TL B
  input  logic                            L1_tl_B_valid_i, 
  output logic                            L1_tl_B_ready_o, 
  input  tl_pkg::B_chan_bits_t            L1_tl_B_bits_i,
  // TL C
  output logic                            L1_tl_C_valid_o, 
  input  logic                            L1_tl_C_ready_i, 
  output tl_pkg::C_chan_bits_t            L1_tl_C_bits_o,
  // TL D
  input  logic                            L1_tl_D_valid_i, 
  output logic                            L1_tl_D_ready_o, 
  input  tl_pkg::D_chan_bits_t            L1_tl_D_bits_i,
  // TL E
  output logic                            L1_tl_E_valid_o, 
  input  logic                            L1_tl_E_ready_i, 
  output tl_pkg::E_chan_bits_t            L1_tl_E_bits_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

  localparam logic[0:0] ValidRule = 1'b1;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  logic [1:0]                master_A_valid;
  logic [1:0]                master_A_ready;
  tl_pkg::A_chan_bits_t [1:0]master_A_bits;
  logic [1:0]                master_B_valid;
  logic [1:0]                master_B_ready;
  tl_pkg::B_chan_bits_t [1:0]master_B_bits;
  logic [1:0]                master_C_valid;
  logic [1:0]                master_C_ready;
  tl_pkg::C_chan_bits_t [1:0]master_C_bits;
  logic [1:0]                master_D_valid;
  logic [1:0]                master_D_ready;
  tl_pkg::D_chan_bits_t [1:0]master_D_bits;
  logic [1:0]                master_E_valid;
  logic [1:0]                master_E_ready;
  tl_pkg::E_chan_bits_t [1:0]master_E_bits;
  logic                      ic_TL_A_valid;
  logic                      ic_TL_A_ready;
  tl_pkg::A_chan_bits_t      ic_TL_A_bits;
  logic                      ic_TL_B_valid;
  logic                      ic_TL_B_ready;
  tl_pkg::B_chan_bits_t      ic_TL_B_bits;
  logic                      ic_TL_C_valid;
  logic                      ic_TL_C_ready;
  tl_pkg::C_chan_bits_t      ic_TL_C_bits;
  logic                      ic_TL_D_valid;
  logic                      ic_TL_D_ready;
  tl_pkg::D_chan_bits_t      ic_TL_D_bits;
  logic                      ic_TL_E_valid;
  logic                      ic_TL_E_ready;
  tl_pkg::E_chan_bits_t      ic_TL_E_bits;
  logic                      dc_TL_A_valid;
  logic                      dc_TL_A_ready;
  tl_pkg::A_chan_bits_t      dc_TL_A_bits;
  logic                      dc_TL_B_valid;
  logic                      dc_TL_B_ready;
  tl_pkg::B_chan_bits_t      dc_TL_B_bits;
  logic                      dc_TL_C_valid;
  logic                      dc_TL_C_ready;
  tl_pkg::C_chan_bits_t      dc_TL_C_bits;
  logic                      dc_TL_D_valid;
  logic                      dc_TL_D_ready;
  tl_pkg::D_chan_bits_t      dc_TL_D_bits;
  logic                      dc_TL_E_valid;
  logic                      dc_TL_E_ready;
  tl_pkg::E_chan_bits_t      dc_TL_E_bits;

//======================================================================================================================
// Instance
//======================================================================================================================
  assign ic_TL_B_ready = 1'b1;
  assign ic_TL_E_valid = 1'b0;
  assign ic_TL_E_bits  = tl_pkg::E_chan_bits_t'(0);
  assign ic_TL_C_valid = 1'b0;
  assign ic_TL_C_bits  = tl_pkg::C_chan_bits_t'(0);
  sy_icache  #(
    .HART_ID_WTH    (HART_ID_WTH),
    .HART_ID        (HART_ID)
  ) i_cache_inst(
      .clk_i                  (clk_i),              
      .rst_i                  (rst_i),              
      .kill_i                 (fetch_icache__kill_i),
      .flush_i                (flush_icache_i),                              
      .flush_done_o           (flush_icache_done_o),
      .ic_ctrl_idle_o         (icache_ctrl_idle_o),
  
      .fet_icache__req_i      (fetch_icache__req_i),
      .icache_fet__rsp_o      (icache_fetch__rsp_o),
      .fet_icache__req_bits_i (fetch_icache__req_bits_i),
      .icache_fet__rsp_bits_o (icache_fetch__rsp_bits_o),

      .icache_A_valid_o       (ic_TL_A_valid),                         
      .icache_A_ready_i       (ic_TL_A_ready),                         
      .icache_A_bits_o        (ic_TL_A_bits),                        
                               
      .icache_D_valid_i       (ic_TL_D_valid),                         
      .icache_D_ready_o       (ic_TL_D_ready),                         
      .icache_D_bits_i        (ic_TL_D_bits)    
  );

  sy_dcache  #(
      .HART_ID_WTH    (HART_ID_WTH),
      .HART_ID        (HART_ID),
      .REQ_PORT       (REQ_PORT)            
  ) i_dcache_inst(
        .clk_i                  (clk_i),         
        .rst_i                  (rst_i),         
        .flush_i                (flush_dcache_i),             
        .flush_done_o           (flush_dcache_done_o),
        .invalid_i              (invalid_dcache_i),
        .ppl_dmem__kill_i       (ppl_dmem__kill_i),

        .dcache_ctrl_idle_o     (dcache_ctrl_idle_o),

        .ppl_dmem__req_i        (ppl_dmem__req_i     ),     
        .dmem_ppl__rsp_o        (dmem_ppl__rsp_o     ),     
        .ppl_dmem__req_bits_i   (ppl_dmem__req_bits_i),          
        .dmem_ppl__rsp_bits_o   (dmem_ppl__rsp_bits_o),            
                                 
        .mmu_dmem__req_i        (mmu_dmem__req_i     ),     
        .dmem_mmu__rsp_o        (dmem_mmu__rsp_o     ),     
        .mmu_dmem__req_bits_i   (mmu_dmem__req_bits_i),          
        .dmem_mmu__rsp_bits_o   (dmem_mmu__rsp_bits_o),            

        .dcache_A_valid_o       (dc_TL_A_valid),
        .dcache_A_ready_i       (dc_TL_A_ready),                    
        .dcache_A_bits_o        (dc_TL_A_bits ),                   

        .dcache_B_valid_i       (dc_TL_B_valid),                    
        .dcache_B_ready_o       (dc_TL_B_ready),                    
        .dcache_B_bits_i        (dc_TL_B_bits ),                   

        .dcache_C_valid_o       (dc_TL_C_valid),                    
        .dcache_C_ready_i       (dc_TL_C_ready),                    
        .dcache_C_bits_o        (dc_TL_C_bits ),                   

        .dcache_D_valid_i       (dc_TL_D_valid),                    
        .dcache_D_ready_o       (dc_TL_D_ready),                    
        .dcache_D_bits_i        (dc_TL_D_bits ),                              

        .dcache_E_valid_o       (dc_TL_E_valid),                    
        .dcache_E_ready_i       (dc_TL_E_ready),                    
        .dcache_E_bits_o        (dc_TL_E_bits )
  );

//======================================================================================================================
// TileBus to merge I$ and D$ request
//======================================================================================================================
  tl_buf tl_ic_buf (
    .clk_i                    ( clk_i  ),
    .rst_i                    ( rst_i  ),
    .inp_tl_A_valid_i         (ic_TL_A_valid), 
    .inp_tl_A_ready_o         (ic_TL_A_ready), 
    .inp_tl_A_bits_i          (ic_TL_A_bits ),
    .inp_tl_B_valid_o         (ic_TL_B_valid), 
    .inp_tl_B_ready_i         (ic_TL_B_ready), 
    .inp_tl_B_bits_o          (ic_TL_B_bits ),
    .inp_tl_C_valid_i         (ic_TL_C_valid), 
    .inp_tl_C_ready_o         (ic_TL_C_ready), 
    .inp_tl_C_bits_i          (ic_TL_C_bits ),
    .inp_tl_D_valid_o         (ic_TL_D_valid), 
    .inp_tl_D_ready_i         (ic_TL_D_ready), 
    .inp_tl_D_bits_o          (ic_TL_D_bits ),
    .inp_tl_E_valid_i         (ic_TL_E_valid), 
    .inp_tl_E_ready_o         (ic_TL_E_ready), 
    .inp_tl_E_bits_i          (ic_TL_E_bits ),
    .oup_tl_A_valid_o         (master_A_valid[0]), 
    .oup_tl_A_ready_i         (master_A_ready[0]), 
    .oup_tl_A_bits_o          (master_A_bits [0]),
    .oup_tl_B_valid_i         (master_B_valid[0]), 
    .oup_tl_B_ready_o         (master_B_ready[0]), 
    .oup_tl_B_bits_i          (master_B_bits [0]),
    .oup_tl_C_valid_o         (master_C_valid[0]), 
    .oup_tl_C_ready_i         (master_C_ready[0]), 
    .oup_tl_C_bits_o          (master_C_bits [0]),
    .oup_tl_D_valid_i         (master_D_valid[0]), 
    .oup_tl_D_ready_o         (master_D_ready[0]), 
    .oup_tl_D_bits_i          (master_D_bits [0]),
    .oup_tl_E_valid_o         (master_E_valid[0]), 
    .oup_tl_E_ready_i         (master_E_ready[0]), 
    .oup_tl_E_bits_o          (master_E_bits [0])
  );

  tl_buf tl_dc_buf (
    .clk_i                    ( clk_i  ),
    .rst_i                    ( rst_i  ),
    .inp_tl_A_valid_i         (dc_TL_A_valid), 
    .inp_tl_A_ready_o         (dc_TL_A_ready), 
    .inp_tl_A_bits_i          (dc_TL_A_bits ),
    .inp_tl_B_valid_o         (dc_TL_B_valid), 
    .inp_tl_B_ready_i         (dc_TL_B_ready), 
    .inp_tl_B_bits_o          (dc_TL_B_bits ),
    .inp_tl_C_valid_i         (dc_TL_C_valid), 
    .inp_tl_C_ready_o         (dc_TL_C_ready), 
    .inp_tl_C_bits_i          (dc_TL_C_bits ),
    .inp_tl_D_valid_o         (dc_TL_D_valid), 
    .inp_tl_D_ready_i         (dc_TL_D_ready), 
    .inp_tl_D_bits_o          (dc_TL_D_bits ),
    .inp_tl_E_valid_i         (dc_TL_E_valid), 
    .inp_tl_E_ready_o         (dc_TL_E_ready), 
    .inp_tl_E_bits_i          (dc_TL_E_bits ),
    .oup_tl_A_valid_o         (master_A_valid[1]), 
    .oup_tl_A_ready_i         (master_A_ready[1]), 
    .oup_tl_A_bits_o          (master_A_bits [1]),
    .oup_tl_B_valid_i         (master_B_valid[1]), 
    .oup_tl_B_ready_o         (master_B_ready[1]), 
    .oup_tl_B_bits_i          (master_B_bits [1]),
    .oup_tl_C_valid_o         (master_C_valid[1]), 
    .oup_tl_C_ready_i         (master_C_ready[1]), 
    .oup_tl_C_bits_o          (master_C_bits [1]),
    .oup_tl_D_valid_i         (master_D_valid[1]), 
    .oup_tl_D_ready_o         (master_D_ready[1]), 
    .oup_tl_D_bits_i          (master_D_bits [1]),
    .oup_tl_E_valid_o         (master_E_valid[1]), 
    .oup_tl_E_ready_i         (master_E_ready[1]), 
    .oup_tl_E_bits_o          (master_E_bits [1])
  );

  tl_xbar #(
      .MASTER_NUM       (2),
      .SLAVE_NUM        (1),
      .REGION_NUM       (1),
      .SOURCE_LSB       (0),
      .SOURCE_MSB       (1),
      .SINK_LSB         (0),
      .SINK_MSB         (1),
      .TL_ADDR_WIDTH    (ADDR_WTH)
  ) TileBus(
      .clk_i            ( clk_i         ),
      .rst_i            ( rst_i         ),
      // Master A Channel
      .master_A_valid_i (master_A_valid),
      .master_A_ready_o (master_A_ready),
      .master_A_bits_i  (master_A_bits),
      // Master B Channel
      .master_B_valid_o (master_B_valid),
      .master_B_ready_i (master_B_ready),
      .master_B_bits_o  (master_B_bits ),
      // Master C Channel
      .master_C_valid_i (master_C_valid),
      .master_C_ready_o (master_C_ready),
      .master_C_bits_i  (master_C_bits ),
      // Master D Channel
      .master_D_valid_o (master_D_valid),
      .master_D_ready_i (master_D_ready),
      .master_D_bits_o  (master_D_bits ),
      // Master E Channel
      .master_E_valid_i (master_E_valid),
      .master_E_ready_o (master_E_ready),
      .master_E_bits_i  (master_E_bits ),
      // Slave A Channel
      .slave_A_valid_o  (L1_tl_A_valid_o),
      .slave_A_ready_i  (L1_tl_A_ready_i),
      .slave_A_bits_o   (L1_tl_A_bits_o),
      // Slave B Channel
      .slave_B_valid_i  (L1_tl_B_valid_i),
      .slave_B_ready_o  (L1_tl_B_ready_o),
      .slave_B_bits_i   (L1_tl_B_bits_i),
      // Slave C Channel
      .slave_C_valid_o  (L1_tl_C_valid_o),
      .slave_C_ready_i  (L1_tl_C_ready_i),
      .slave_C_bits_o   (L1_tl_C_bits_o),
      // Slave D Channel
      .slave_D_valid_i  (L1_tl_D_valid_i),
      .slave_D_ready_o  (L1_tl_D_ready_o),
      .slave_D_bits_i   (L1_tl_D_bits_i),
      // Slave E Channel
      .slave_E_valid_o  (L1_tl_E_valid_o),
      .slave_E_ready_i  (L1_tl_E_ready_i),
      .slave_E_bits_o   (L1_tl_E_bits_o ),

      .start_addr_i     ( '0            ),
      .end_addr_i       ({ADDR_WTH{1'b1}}),
      .region_en_i      (ValidRule)
  );

endmodule