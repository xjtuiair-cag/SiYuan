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
  input  logic                            flush_ppl_i,
  input  logic                            flush_icache_i,  
  output logic                            flush_icache_done_o,
  input  logic                            flush_dcache_i,  
  output logic                            flush_dcache_done_o,

  output logic                            icache_miss_o,               
  // output logic                            dcache_miss_o,               

  output icache_mmu_req_t                 icache_mmu__req_o,
  input  mmu_icache_rsp_t                 mmu_icache__rsp_i,
  // data requests
  input  fetch_req_t                      fetch_icache__req_i,
  output fetch_rsp_t                      icache_fetch__rsp_o,
  // =====================================
  // [From MMU]
  input  logic                            mmu_dcache__vld_i,
  output logic                            dcache_mmu__rdy_o,      
  input  dcache_req_t                     mmu_dcache__data_i,
  output logic                            dcache_mmu__rvld_o,  
  output logic [DWTH-1:0]                 dcache_mmu__rdata_o,
  // =====================================
  // [From LSU]
  input  logic                            lsu_dcache__vld_i,
  output logic                            dcache_lsu__rdy_o,
  input  dcache_req_t                     lsu_dcache__data_i,
  output dcache_rsp_t                     dcache_lsu__data_o,
 
  TL_BUS.Slave                            slave
);

//======================================================================================================================
// Parameters
//======================================================================================================================

  localparam logic[0:0] ValidRule = 1'b1;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  TL_BUS                     master[1:0] ();
  TL_BUS                     tilebus_slave[0:0] ();

  logic                      icache_A_valid;
  logic                      icache_A_ready;
  tl_pkg::A_chan_bits_t      icache_A_bits;

  logic                      icache_D_ready;
  logic                      icache_D_valid;
  tl_pkg::D_chan_bits_t      icache_D_bits;          

  logic                      dcache_A_valid;
  logic                      dcache_A_ready;
  tl_pkg::A_chan_bits_t      dcache_A_bits;

  logic                      dcache_B_valid;
  logic                      dcache_B_ready;
  tl_pkg::B_chan_bits_t      dcache_B_bits;

  logic                      dcache_C_valid;
  logic                      dcache_C_ready;
  tl_pkg::C_chan_bits_t      dcache_C_bits;

  logic                      dcache_D_ready;
  logic                      dcache_D_valid;
  tl_pkg::D_chan_bits_t      dcache_D_bits;           

  logic                      dcache_E_valid;
  logic                      dcache_E_ready;
  tl_pkg::E_chan_bits_t      dcache_E_bits;

//======================================================================================================================
// Instance
//======================================================================================================================
  sy_icache  #(
    .HART_ID_WTH    (HART_ID_WTH),
    .HART_ID        (HART_ID)
  ) i_cache_inst(
      .clk_i                  (clk_i),              
      .rst_i                  (rst_i),              
      .flush_i                (flush_icache_i),                              
      .flush_done_o           (flush_icache_done_o),
      .cache_miss_o           (icache_miss_o),                                    
  
      .mmu_icache__rsp_i      (mmu_icache__rsp_i),                          
      .icache_mmu__req_o      (icache_mmu__req_o),                          
  
      .fetch_icache__req_i    (fetch_icache__req_i),                            
      .icache_fetch__rsp_o    (icache_fetch__rsp_o),                            
  
      .icache_A_valid_o       (icache_A_valid ),                         
      .icache_A_ready_i       (icache_A_ready ),                         
      .icache_A_bits_o        (icache_A_bits  ),                        
                               
      .icache_D_ready_o       (icache_D_ready ),                         
      .icache_D_valid_i       (icache_D_valid ),                         
      .icache_D_bits_i        (icache_D_bits  )    
  );

  sy_dcache  #(
      .HART_ID_WTH    (HART_ID_WTH),
      .HART_ID        (HART_ID),
      .REQ_PORT       (REQ_PORT)            
  ) i_dcache_inst(
        .clk_i                  (clk_i),         
        .rst_i                  (rst_i),         
        .flush_ppl_i            (flush_ppl_i),
        .flush_i                (flush_dcache_i),             
        .flush_done_o           (flush_dcache_done_o),

        // .cache_miss_o           (dcache_miss_o),                               
        .mmu_dcache__vld_i      (mmu_dcache__vld_i  ),         
        .dcache_mmu__rdy_o      (dcache_mmu__rdy_o  ),               
        .mmu_dcache__data_i     (mmu_dcache__data_i ),          
        .dcache_mmu__rvld_o     (dcache_mmu__rvld_o ),            
        .dcache_mmu__rdata_o    (dcache_mmu__rdata_o),           

        .lsu_dcache__vld_i      (lsu_dcache__vld_i ),         
        .dcache_lsu__rdy_o      (dcache_lsu__rdy_o ),         
        .lsu_dcache__data_i     (lsu_dcache__data_i),          
        .dcache_lsu__data_o     (dcache_lsu__data_o),          

        .dcache_A_valid_o       (dcache_A_valid),                    
        .dcache_A_ready_i       (dcache_A_ready),                    
        .dcache_A_bits_o        (dcache_A_bits ),                   

        .dcache_B_valid_i       (dcache_B_valid),                    
        .dcache_B_ready_o       (dcache_B_ready),                    
        .dcache_B_bits_i        (dcache_B_bits ),                   

        .dcache_C_valid_o       (dcache_C_valid),                    
        .dcache_C_ready_i       (dcache_C_ready),                    
        .dcache_C_bits_o        (dcache_C_bits ),                   

        .dcache_D_ready_o       (dcache_D_ready),                    
        .dcache_D_valid_i       (dcache_D_valid),                    
        .dcache_D_bits_i        (dcache_D_bits ),                              

        .dcache_E_valid_o       (dcache_E_valid),                    
        .dcache_E_ready_i       (dcache_E_ready),                    
        .dcache_E_bits_o        (dcache_E_bits )
  );

  tl_master_connect icache_connect (
        .A_valid_i            (icache_A_valid),            
        .A_ready_o            (icache_A_ready),            
        .A_bits_i             (icache_A_bits ),           
      
        .B_valid_o            (              ),            
        .B_ready_i            (1'b0          ),            
        .B_bits_o             (              ),           
      
        .C_valid_i            (1'b0          ),            
        .C_ready_o            (              ),            
        .C_bits_i             ('0            ),           
      
        .D_valid_o            (icache_D_valid),            
        .D_ready_i            (icache_D_ready),            
        .D_bits_o             (icache_D_bits ),                      
      
        .E_valid_i            (1'b0          ),            
        .E_ready_o            (              ),            
        .E_bits_i             ('0            ),         

        .master               (master[0])           
  );

  tl_master_connect dcache_connect (
        .A_valid_i            (dcache_A_valid),            
        .A_ready_o            (dcache_A_ready),            
        .A_bits_i             (dcache_A_bits ),           
      
        .B_valid_o            (dcache_B_valid),            
        .B_ready_i            (dcache_B_ready),            
        .B_bits_o             (dcache_B_bits ),           
      
        .C_valid_i            (dcache_C_valid),            
        .C_ready_o            (dcache_C_ready),            
        .C_bits_i             (dcache_C_bits ),           
      
        .D_valid_o            (dcache_D_valid),            
        .D_ready_i            (dcache_D_ready),            
        .D_bits_o             (dcache_D_bits ),                      
      
        .E_valid_i            (dcache_E_valid),            
        .E_ready_o            (dcache_E_ready),            
        .E_bits_i             (dcache_E_bits ),         

        .master               (master[1])           
  );

//======================================================================================================================
// TileBus to merge I$ and D$ request
//======================================================================================================================
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
      .master           ( master),
      .slave            ( tilebus_slave),
      .start_addr_i     ( '0            ),
      .end_addr_i       ({ADDR_WTH{1'b1}}),
      .region_en_i      (ValidRule)
  );

  tl_slave2master trans(.slave(tilebus_slave[0]), .master(slave));

endmodule