// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dcache.v
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

module sy_dcache  
  import sy_pkg::*;
#(
  parameter                             HART_ID_WTH  = 1,
  parameter logic [HART_ID_WTH-1:0]     HART_ID      = 0,
  parameter                             REQ_PORT     = 2            
) (
  input  logic                            clk_i,
  input  logic                            rst_i,
  input  logic                            flush_i,  // from pipeline             
  output logic                            flush_done_o,
  input  logic                            flush_ppl_i,
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
  // A channel
  output logic                            dcache_A_valid_o,
  input  logic                            dcache_A_ready_i,
  output tl_pkg::A_chan_bits_t            dcache_A_bits_o,
  // B channel
  input  logic                            dcache_B_valid_i,
  output logic                            dcache_B_ready_o,
  input  tl_pkg::B_chan_bits_t            dcache_B_bits_i,
  // C channel
  output logic                            dcache_C_valid_o,
  input  logic                            dcache_C_ready_i,
  output tl_pkg::C_chan_bits_t            dcache_C_bits_o,
  // D channel
  output logic                            dcache_D_ready_o,
  input  logic                            dcache_D_valid_i,
  input  tl_pkg::D_chan_bits_t            dcache_D_bits_i,           
  // E channel
  output logic                            dcache_E_valid_o,
  input  logic                            dcache_E_ready_i,
  output tl_pkg::E_chan_bits_t            dcache_E_bits_o

);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  logic                             allow_probe;
  logic                             probe_flight;
  logic                             acquire_flight;

  logic                             miss_req;
  logic                             miss_ack;
  miss_req_bits_t                   miss_req_bits;
  logic                             miss_done;
  logic [DCACHE_DATA_SIZE*8-1:0]    miss_rdata;  
  logic [DCACHE_WAY_WTH-1:0]        miss_rpl_way;

  logic      [1:0]                  data_req;
  logic      [1:0]                  data_gnt;
  data_req_t [1:0]                  data_req_bits;
  data_rsp_t [1:0]                  data_rsp_bits;
  logic      [1:0]                  tag_req;
  logic      [1:0]                  tag_gnt;
  tag_req_t  [1:0]                  tag_req_bits;
  tag_rsp_t  [1:0]                  tag_rsp_bits;

  logic                             flush_dcache_mem;

  logic                             mshr_dcache__vld;
  logic                             dcache_mshr__rdy;
  dcache_req_t                      mshr_dcache__data;
  logic                             mshr_dcache__afull;        
  logic                             mshr_dcache__full;        
  logic                             mshr_dcache__empty;
  req_src_e                         mshr_dcache__req_src;

  logic                             dcache_mshr__vld;
  logic[AWTH-1:0]                   dcache_mshr__addr;
  miss_req_cmd_e                    dcache_mshr__cmd;
  logic[DCACHE_WAY_WTH-1:0]         dcache_mshr__update_way;
  logic                             dcache_mshr__cachable;
  logic                             dcache_mshr__is_store;    
  mshr_entry_t                      dcache_mshr__entry;
  logic                             dcache_mshr__unlock_vld;
  logic                             dcache_mshr__lock_vld;
  logic[DCACHE_SET_WTH-1:0]         dcache_mshr__unlock_idx;
  logic[DCACHE_WAY_WTH-1:0]         dcache_mshr__unlock_way;
  logic                             lrsc_valid;
  logic[DCACHE_SET_WTH-1:0]         lrsc_set_idx;
  logic[DCACHE_WAY_WTH-1:0]         lrsc_way_idx;
  logic[DCACHE_SET_SIZE-1:0][DCACHE_WAY_NUM-1:0] cl_valid;
  logic[DCACHE_SET_SIZE-1:0][DCACHE_WAY_NUM-1:0][MSHR_WTH:0]lock_cl;
  logic                             miss_kill_o;
  logic                             miss_kill_done;
  logic[DCACHE_SET_WTH-1:0]         rpl_idx;
  logic[DCACHE_WAY_WTH-1:0]         rpl_way;
  logic                             rpl_way_is_lock;

//======================================================================================================================
// Instance
//======================================================================================================================
  sy_dcache_ctrl dcache_ctrl_inst(
      .clk_i                      (clk_i             ),       
      .rst_i                      (rst_i             ),       
  
      .allow_probe_o              (allow_probe       ),               

      .mmu_dcache__vld_i          (mmu_dcache__vld_i  ),              
      .dcache_mmu__rdy_o          (dcache_mmu__rdy_o  ),                    
      .mmu_dcache__data_i         (mmu_dcache__data_i ),               
      .dcache_mmu__rvld_o         (dcache_mmu__rvld_o ),                 
      .dcache_mmu__rdata_o        (dcache_mmu__rdata_o),                

      .lsu_dcache__vld_i          (lsu_dcache__vld_i  ),              
      .dcache_lsu__rdy_o          (dcache_lsu__rdy_o  ),              
      .lsu_dcache__data_i         (lsu_dcache__data_i ),               
      .dcache_lsu__data_o         (dcache_lsu__data_o ),               

      .mshr_dcache__vld_i         (mshr_dcache__vld    ),               
      .dcache_mshr__rdy_o         (dcache_mshr__rdy    ),               
      .mshr_dcache__data_i        (mshr_dcache__data   ),                
      .mshr_dcache__afull_i       (mshr_dcache__afull  ),                         
      .mshr_dcache__full_i        (mshr_dcache__full  ),                         
      .mshr_dcache__empty_i       (mshr_dcache__empty),                         
      .mshr_dcache__req_src_i     (mshr_dcache__req_src),                   

      .dcache_mshr__vld_o         (dcache_mshr__vld         ),               
      .dcache_mshr__addr_o        (dcache_mshr__addr        ),                
      .dcache_mshr__cmd_o         (dcache_mshr__cmd         ),               
      .dcache_mshr__update_way_o  (dcache_mshr__update_way  ),                      
      .dcache_mshr__cachable_o    (dcache_mshr__cachable    ),                    
      .dcache_mshr__is_store_o    (dcache_mshr__is_store    ),                        
      .dcache_mshr__entry_o       (dcache_mshr__entry       ),                 

      .dcache_mshr__unlock_vld_o  (dcache_mshr__unlock_vld),                      
      .dcache_mshr__lock_vld_o    (dcache_mshr__lock_vld),                      
      .dcache_mshr__unlock_idx_o  (dcache_mshr__unlock_idx),                      
      .dcache_mshr__unlock_way_o  (dcache_mshr__unlock_way),                      

      .lrsc_valid_o               (lrsc_valid  ),          
      .lrsc_set_idx_o             (lrsc_set_idx),           
      .lrsc_way_idx_o             (lrsc_way_idx),           
      
      .data_req_o                 (data_req[1]     ),            
      .data_gnt_i                 (data_gnt[1]     ),            
      .data_req_bits_o            (data_req_bits[1]),                 
      .data_rsp_bits_i            (data_rsp_bits[1]),                 

      .tag_req_o                  (tag_req[1]      ),           
      .tag_gnt_i                  (tag_gnt[1]      ),           
      .tag_req_bits_o             (tag_req_bits[1] ),                
      .tag_rsp_bits_i             (tag_rsp_bits[1] )
  );

  sy_dcache_mshr mshr_inst(
      .clk_i                      (clk_i),                           
      .rst_i                      (rst_i),                           
      .flush_i                    (flush_ppl_i),      
      .mshr_full_o                (mshr_dcache__full),             
      .mshr_afull_o               (mshr_dcache__afull),             
      .mshr_empty_o               (mshr_dcache__empty),

      .lock_cl_o                  (lock_cl),

      .mshr_wr_en_i               (dcache_mshr__vld       ),            
      .mshr_paddr_i               (dcache_mshr__addr[31:0]),                    
      .mshr_cmd_i                 (dcache_mshr__cmd       ),          
      .mshr_update_way_i          (dcache_mshr__update_way),                     
      .mshr_cacheable_i           (dcache_mshr__cachable  ),                
      .mshr_is_store_i            (dcache_mshr__is_store  ),               
      .mshr_wr_entry_i            (dcache_mshr__entry     ),               

      .mshr_unlock_vld_i          (dcache_mshr__unlock_vld),                 
      .mshr_lock_vld_i            (dcache_mshr__lock_vld),                 
      .mshr_unlock_idx_i          (dcache_mshr__unlock_idx),                 
      .mshr_unlock_way_i          (dcache_mshr__unlock_way),                 

      .miss_req_o                 (miss_req     ),          
      .miss_ack_i                 (miss_ack     ),          
      .miss_kill_o                (miss_kill      ),           
      .miss_kill_done_i           (miss_kill_done ),                
      .miss_req_bits_o            (miss_req_bits   ),               
      .miss_done_i                (miss_done),           
      .miss_rdata_i               (miss_rdata),               
      .miss_rpl_way_i             (miss_rpl_way),

      .mshr_dcache__vld_o         (mshr_dcache__vld ),                  
      .dcache_mshr__rdy_i         (dcache_mshr__rdy ),                        
      .mshr_dcache__data_o        (mshr_dcache__data),                   
      .mshr_dcache__req_src_o     (mshr_dcache__req_src)          
  );


  sy_dcache_mem  dcache_mem_inst(
      .clk_i                      (clk_i             ),          
      .rst_i                      (rst_i             ),          
  
      .flush_i                    (flush_dcache_mem  ),                          
      .cl_valid_o                 (cl_valid          ),      
    
      .tag_req_i                  (tag_req         ),              
      .tag_gnt_o                  (tag_gnt         ),              
      .tag_req_bits_i             (tag_req_bits    ),                   
      .tag_rsp_bits_o             (tag_rsp_bits    ),                   
                                   
      .data_req_i                 (data_req          ),               
      .data_gnt_o                 (data_gnt          ),               
      .data_req_bits_i            (data_req_bits     ),                    
      .data_rsp_bits_o            (data_rsp_bits     )
  );

  sy_dcache_missunit  #(
      .HART_ID_WTH  (HART_ID_WTH),
      .HART_ID      (HART_ID)
  ) dcache_miss_unit_inst(
      .clk_i                      (clk_i             ),           
      .rst_i                      (rst_i             ),           
      .flush_i                    (flush_i           ),               

      .cl_valid_i                 (cl_valid          ),
      .lock_cl_i                  (lock_cl           ),
  
      .flush_dcache_mem_o         (flush_dcache_mem  ),                         
      .flush_done_o               (flush_done_o      ),   
      .allow_probe_i              (allow_probe       ),                   
      .probe_flight_o             (probe_flight      ),                    
      .acquire_flight_o           (acquire_flight    ),
    
      .miss_req_i                 (miss_req          ),                
      .miss_ack_o                 (miss_ack          ),                
      .miss_kill_i                (miss_kill        ),
      .miss_kill_done_o           (miss_kill_done    )  ,
      .miss_req_bits_i            (miss_req_bits     ),                     
      .miss_done_o                (miss_done         ),                 
      .miss_rdata_o               (miss_rdata        ),
      .miss_rpl_way_o             (miss_rpl_way      ),
    
      .lrsc_valid_i               (lrsc_valid  ),   
      .lrsc_set_idx_i             (lrsc_set_idx),     
      .lrsc_way_idx_i             (lrsc_way_idx),     

      .ctrl_cl_unlock_vld_i       (dcache_mshr__unlock_vld),
      .ctrl_cl_unlock_idx_i       (dcache_mshr__unlock_idx),
      .ctrl_cl_unlock_way_i       (dcache_mshr__unlock_way),

      .data_req_o                 (data_req[0]     ),                                
      .data_gnt_i                 (data_gnt[0]     ),                
      .data_req_bits_o            (data_req_bits[0]),                     
      .data_rsp_bits_i            (data_rsp_bits[0]),                     
                                   
      .tag_req_o                  (tag_req[0]      ),               
      .tag_gnt_i                  (tag_gnt[0]      ),               
      .tag_req_bits_o             (tag_req_bits[0] ),                    
      .tag_rsp_bits_i             (tag_rsp_bits[0] ),
  
      .dcache_A_valid_o           (dcache_A_valid_o),                      
      .dcache_A_ready_i           (dcache_A_ready_i),                      
      .dcache_A_bits_o            (dcache_A_bits_o ),                     
                                   
      .dcache_B_valid_i           (dcache_B_valid_i),                      
      .dcache_B_ready_o           (dcache_B_ready_o),                      
      .dcache_B_bits_i            (dcache_B_bits_i ),                     
                                   
      .dcache_C_valid_o           (dcache_C_valid_o),                      
      .dcache_C_ready_i           (dcache_C_ready_i),                      
      .dcache_C_bits_o            (dcache_C_bits_o ),                     
                                   
      .dcache_D_ready_o           (dcache_D_ready_o),                      
      .dcache_D_valid_i           (dcache_D_valid_i),                      
      .dcache_D_bits_i            (dcache_D_bits_i ),                                
                                   
      .dcache_E_valid_o           (dcache_E_valid_o),                      
      .dcache_E_ready_i           (dcache_E_ready_i),                      
      .dcache_E_bits_o            (dcache_E_bits_o )
  );

endmodule