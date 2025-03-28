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

  output logic                            cache_miss_o,               

  input  dcache_req_t [REQ_PORT-1:0]      dcache_req_i,
  output dcache_rsp_t [REQ_PORT-1:0]      dcache_rsp_o,
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

  logic      [1:0]                  data_req;
  logic      [1:0]                  data_gnt;
  data_req_t [1:0]                  data_req_bits;
  data_rsp_t [1:0]                  data_rsp_bits;
  logic      [1:0]                  tag_req;
  logic      [1:0]                  tag_gnt;
  tag_req_t  [1:0]                  tag_req_bits;
  tag_rsp_t  [1:0]                  tag_rsp_bits;

  logic                             flush_dcache_mem;
//======================================================================================================================
// Instance
//======================================================================================================================
  sy_dcache_ctrl  #(
      .REQ_PORT   (REQ_PORT)
  ) dcache_ctrl_inst(
      .clk_i                      (clk_i             ),       
      .rst_i                      (rst_i             ),       
  
      .cache_miss_o               (cache_miss_o      ),                             
      .allow_probe_o              (allow_probe       ),               
      .probe_flight_i             (probe_flight      ),                 
      .acquire_flight_i           (acquire_flight    ),
      
      .dcache_req_i               (dcache_req_i      ),              
      .dcache_rsp_o               (dcache_rsp_o      ),              
      
      .miss_req_o                 (miss_req          ),            
      .miss_ack_i                 (miss_ack          ),            
      .miss_req_bits_o            (miss_req_bits     ),                 
      .miss_done_i                (miss_done         ),             
      .miss_rdata_i               (miss_rdata        ),                 

      .data_req_o                 (data_req[1]     ),            
      .data_gnt_i                 (data_gnt[1]     ),            
      .data_req_bits_o            (data_req_bits[1]),                 
      .data_rsp_bits_i            (data_rsp_bits[1]),                 

      .tag_req_o                  (tag_req[1]      ),           
      .tag_gnt_i                  (tag_gnt[1]      ),           
      .tag_req_bits_o             (tag_req_bits[1] ),                
      .tag_rsp_bits_i             (tag_rsp_bits[1] )
  );

  sy_dcache_mem  dcache_mem_inst(
      .clk_i                      (clk_i             ),          
      .rst_i                      (rst_i             ),          
  
      .flush_i                    (flush_dcache_mem  ),                          
    
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
  
      .flush_dcache_mem_o         (flush_dcache_mem  ),                         
      .flush_done_o               (flush_done_o      ),   
      .allow_probe_i              (allow_probe       ),                   
      .probe_flight_o             (probe_flight      ),                    
      .acquire_flight_o           (acquire_flight    ),
    
      .miss_req_i                 (miss_req          ),                
      .miss_ack_o                 (miss_ack          ),                
      .miss_req_bits_i            (miss_req_bits     ),                     
      .miss_done_o                (miss_done         ),                 
      .miss_rdata_o               (miss_rdata        ),
    
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