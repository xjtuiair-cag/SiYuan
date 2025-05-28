// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_npu.v
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


module sy_npu #(
    parameter int unsigned ADDR_WIDTH   = 64,
    parameter int unsigned DATA_WIDTH   = 64,
    // Number of cores therefore also the number of timecmp registers and timer interrupts
    parameter int unsigned CORES_NUM    = 1 
) (
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // AXI4 TO DDR 
    output  logic                       axi_aw_valid_o,
    input   logic                       axi_aw_ready_i,         
    output  axi_pkg::aw_chan_t          axi_aw_bits_o,
    output  logic                       axi_ar_valid_o,
    input   logic                       axi_ar_ready_i,         
    output  axi_pkg::ar_chan_t          axi_ar_bits_o,
    output  logic                       axi_w_valid_o,
    input   logic                       axi_w_ready_i,         
    output  axi_pkg::w_chan_t           axi_w_bits_o,
    input   logic                       axi_r_valid_i,
    output  logic                       axi_r_ready_o,
    input   axi_pkg::r_chan_t           axi_r_bits_i, 
    input   logic                       axi_b_valid_i,
    output  logic                       axi_b_ready_o,
    input   axi_pkg::b_chan_t           axi_b_bits_i,

    TL_BUS.Master                       npu_mem,
    TL_BUS.Master                       npu_reg 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    parameter logic[15:0] ID_REG                   = 16'h2000;
    parameter logic[15:0] TIME_REG                 = 16'h2008; 
    parameter logic[15:0] MAILBOX                  = 16'h2010;
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================

    // signals from AXI 4 Lite
    logic [ADDR_WIDTH-1:0]      address;
    logic                       en;
    logic                       we;
    logic [DATA_WIDTH-1:0]      wdata;
    logic [DATA_WIDTH-1:0]      rdata;

    // bit 11 and 10 are determining the address offset
    logic [15:0] register_address;
    assign register_address = address[15:0];
    // actual registers
    logic[DATA_WIDTH-1:0]       mailbox_d, mailbox_q;

    TL_BUS                      npu_mem_trans ();

    logic                [1:0]  npu_mem_axi_aw_valid     ;       
    logic                [1:0]  npu_mem_axi_aw_ready     ;                
    axi_pkg::aw_chan_t   [1:0]  npu_mem_axi_aw_bits     ;       
    logic                [1:0]  npu_mem_axi_ar_valid     ;       
    logic                [1:0]  npu_mem_axi_ar_ready     ;                
    axi_pkg::ar_chan_t   [1:0]  npu_mem_axi_ar_bits     ;       
    logic                [1:0]  npu_mem_axi_w_valid     ;       
    logic                [1:0]  npu_mem_axi_w_ready     ;                
    axi_pkg::w_chan_t    [1:0]  npu_mem_axi_w_bits     ;       
    logic                [1:0]  npu_mem_axi_r_valid     ;       
    logic                [1:0]  npu_mem_axi_r_ready     ;       
    axi_pkg::r_chan_t    [1:0]  npu_mem_axi_r_bits     ;        
    logic                [1:0]  npu_mem_axi_b_valid     ;       
    logic                [1:0]  npu_mem_axi_b_ready     ;       
    axi_pkg::b_chan_t    [1:0]  npu_mem_axi_b_bits     ;       

//======================================================================================================================
// Instance
//======================================================================================================================
   tl_c_trans_a c_trans_a_inst(
        .in         (npu_mem),
        .out        (npu_mem_trans)
   ); 

    sy_npu_mem npu_mem_inst(
        .clk_i                  (clk_i),      
        .rst_i                  (rst_i),      

        .axi_aw_valid_o         (npu_mem_axi_aw_valid[0] ),               
        .axi_aw_ready_i         (npu_mem_axi_aw_ready[0] ),                        
        .axi_aw_bits_o          (npu_mem_axi_aw_bits [0] ),              
        .axi_ar_valid_o         (npu_mem_axi_ar_valid[0] ),               
        .axi_ar_ready_i         (npu_mem_axi_ar_ready[0] ),                        
        .axi_ar_bits_o          (npu_mem_axi_ar_bits [0] ),              
        .axi_w_valid_o          (npu_mem_axi_w_valid [0] ),              
        .axi_w_ready_i          (npu_mem_axi_w_ready [0] ),                       
        .axi_w_bits_o           (npu_mem_axi_w_bits  [0] ),             
        .axi_r_valid_i          (npu_mem_axi_r_valid [0] ),              
        .axi_r_ready_o          (npu_mem_axi_r_ready [0] ),              
        .axi_r_bits_i           (npu_mem_axi_r_bits  [0] ),              
        .axi_b_valid_i          (npu_mem_axi_b_valid [0] ),              
        .axi_b_ready_o          (npu_mem_axi_b_ready [0] ),              
        .axi_b_bits_i           (npu_mem_axi_b_bits  [0] ),             

        .master                 (npu_mem_trans)
    );

    sy_npu_core npu_core_inst(
        .clk_i                  (clk_i),             
        .rst_i                  (rst_i),            

        .axi_aw_valid_o         (npu_mem_axi_aw_valid[1] ),               
        .axi_aw_ready_i         (npu_mem_axi_aw_ready[1] ),                        
        .axi_aw_bits_o          (npu_mem_axi_aw_bits [1] ),              
        .axi_ar_valid_o         (npu_mem_axi_ar_valid[1] ),               
        .axi_ar_ready_i         (npu_mem_axi_ar_ready[1] ),                        
        .axi_ar_bits_o          (npu_mem_axi_ar_bits [1] ),              
        .axi_w_valid_o          (npu_mem_axi_w_valid [1] ),              
        .axi_w_ready_i          (npu_mem_axi_w_ready [1] ),                       
        .axi_w_bits_o           (npu_mem_axi_w_bits  [1] ),             
        .axi_r_valid_i          (npu_mem_axi_r_valid [1] ),              
        .axi_r_ready_o          (npu_mem_axi_r_ready [1] ),              
        .axi_r_bits_i           (npu_mem_axi_r_bits  [1] ),              
        .axi_b_valid_i          (npu_mem_axi_b_valid [1] ),              
        .axi_b_ready_o          (npu_mem_axi_b_ready [1] ),              
        .axi_b_bits_i           (npu_mem_axi_b_bits  [1] ),             

        .npu_reg                (npu_reg)
    );

    sy_axi4_arbiter #(
        .PORT_NUM  (2)
    ) arbiter_inst(
        .clk_i                  (clk_i), 
        .rst_i                  (rst_i), 
    
        .inp_axi_aw_valid_i     (npu_mem_axi_aw_valid),              
        .inp_axi_aw_ready_o     (npu_mem_axi_aw_ready),                       
        .inp_axi_aw_bits_i      (npu_mem_axi_aw_bits ),             
        .inp_axi_ar_valid_i     (npu_mem_axi_ar_valid),              
        .inp_axi_ar_ready_o     (npu_mem_axi_ar_ready),                       
        .inp_axi_ar_bits_i      (npu_mem_axi_ar_bits ),             
        .inp_axi_w_valid_i      (npu_mem_axi_w_valid ),             
        .inp_axi_w_ready_o      (npu_mem_axi_w_ready ),                      
        .inp_axi_w_bits_i       (npu_mem_axi_w_bits  ),            
        .inp_axi_r_valid_o      (npu_mem_axi_r_valid ),             
        .inp_axi_r_ready_i      (npu_mem_axi_r_ready ),             
        .inp_axi_r_bits_o       (npu_mem_axi_r_bits  ),             
        .inp_axi_b_valid_o      (npu_mem_axi_b_valid ),             
        .inp_axi_b_ready_i      (npu_mem_axi_b_ready ),             
        .inp_axi_b_bits_o       (npu_mem_axi_b_bits  ),            
    
        .oup_axi_aw_valid_o     (axi_aw_valid_o),              
        .oup_axi_aw_ready_i     (axi_aw_ready_i),                       
        .oup_axi_aw_bits_o      (axi_aw_bits_o ),             
        .oup_axi_ar_valid_o     (axi_ar_valid_o),              
        .oup_axi_ar_ready_i     (axi_ar_ready_i),                       
        .oup_axi_ar_bits_o      (axi_ar_bits_o ),             
        .oup_axi_w_valid_o      (axi_w_valid_o ),             
        .oup_axi_w_ready_i      (axi_w_ready_i ),                      
        .oup_axi_w_bits_o       (axi_w_bits_o  ),            
        .oup_axi_r_valid_i      (axi_r_valid_i ),             
        .oup_axi_r_ready_o      (axi_r_ready_o ),             
        .oup_axi_r_bits_i       (axi_r_bits_i  ),             
        .oup_axi_b_valid_i      (axi_b_valid_i ),             
        .oup_axi_b_ready_o      (axi_b_ready_o ),             
        .oup_axi_b_bits_i       (axi_b_bits_i  )
    );


endmodule
