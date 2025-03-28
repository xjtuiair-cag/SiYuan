// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_xbar.v
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


module tl_xbar 
  import tl_pkg::*;
#(
    parameter MASTER_NUM    = 4,
    parameter SLAVE_NUM     = 4,
    parameter REGION_NUM    = 1,
    parameter SOURCE_LSB    = 0,
    parameter SOURCE_MSB    = 1,
    parameter SINK_LSB      = 0,
    parameter SINK_MSB      = 1,
    parameter TL_ADDR_WIDTH = 64
  )(
    // Clock and Reset
    input logic                                                         clk_i,
    input logic                                                         rst_i,
    TL_BUS.Master                                                       master[MASTER_NUM-1:0],
    TL_BUS.Slave                                                        slave[SLAVE_NUM-1:0],
    // Memory map
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0]    start_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][TL_ADDR_WIDTH-1:0]    end_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                       region_en_i
  );
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [MASTER_NUM-1:0]                                                master_a_valid; 
    logic [MASTER_NUM-1:0]                                                master_a_ready;
    A_chan_bits_t [MASTER_NUM-1:0]                                        master_a_bits;

    logic [MASTER_NUM-1:0]                                                master_b_valid; 
    logic [MASTER_NUM-1:0]                                                master_b_ready;
    B_chan_bits_t [MASTER_NUM-1:0]                                        master_b_bits;

    logic [MASTER_NUM-1:0]                                                master_c_valid; 
    logic [MASTER_NUM-1:0]                                                master_c_ready;
    C_chan_bits_t [MASTER_NUM-1:0]                                        master_c_bits;

    logic [MASTER_NUM-1:0]                                                master_d_valid; 
    logic [MASTER_NUM-1:0]                                                master_d_ready;
    D_chan_bits_t [MASTER_NUM-1:0]                                        master_d_bits;

    logic [MASTER_NUM-1:0]                                                master_e_valid; 
    logic [MASTER_NUM-1:0]                                                master_e_ready;
    E_chan_bits_t [MASTER_NUM-1:0]                                        master_e_bits;

    logic [SLAVE_NUM-1:0]                                                 slave_a_valid; 
    logic [SLAVE_NUM-1:0]                                                 slave_a_ready;
    A_chan_bits_t [SLAVE_NUM-1:0]                                         slave_a_bits;

    logic [SLAVE_NUM-1:0]                                                 slave_b_valid; 
    logic [SLAVE_NUM-1:0]                                                 slave_b_ready;
    B_chan_bits_t [SLAVE_NUM-1:0]                                         slave_b_bits;

    logic [SLAVE_NUM-1:0]                                                 slave_c_valid; 
    logic [SLAVE_NUM-1:0]                                                 slave_c_ready;
    C_chan_bits_t [SLAVE_NUM-1:0]                                         slave_c_bits;

    logic [SLAVE_NUM-1:0]                                                 slave_d_valid; 
    logic [SLAVE_NUM-1:0]                                                 slave_d_ready;
    D_chan_bits_t [SLAVE_NUM-1:0]                                         slave_d_bits;

    logic [SLAVE_NUM-1:0]                                                 slave_e_valid; 
    logic [SLAVE_NUM-1:0]                                                 slave_e_ready;
    E_chan_bits_t [SLAVE_NUM-1:0]                                         slave_e_bits;

    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                a_valid_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                a_ready_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                a_valid_int_reverse;
    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                a_ready_int_reverse;

    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                c_valid_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                c_ready_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                c_valid_int_reverse;
    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                c_ready_int_reverse;

    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                e_valid_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                e_ready_int;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                e_valid_int_reverse;
    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                e_ready_int_reverse;

    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                b_valid_int_reverse;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                b_ready_int_reverse;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                b_valid_int;
    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                b_ready_int;

    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                d_valid_int_reverse;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                d_ready_int_reverse;
    logic  [SLAVE_NUM-1:0][MASTER_NUM-1:0]                                d_valid_int;
    logic  [MASTER_NUM-1:0][SLAVE_NUM-1:0]                                d_ready_int;
//======================================================================================================================
// Instance
//======================================================================================================================
    genvar i;
    genvar j;
    generate
      for(i = 0; i < MASTER_NUM; i++) begin
        assign master_a_valid[i]  = master[i].a_valid;
        assign master_a_bits[i]   = master[i].a_bits;
        assign                      master[i].a_ready   = master_a_ready[i];

        assign master_c_valid[i]  = master[i].c_valid;
        assign master_c_bits[i]   = master[i].c_bits;
        assign                      master[i].c_ready   = master_c_ready[i];

        assign master_e_valid[i]  = master[i].e_valid;
        assign master_e_bits[i]   = master[i].e_bits;
        assign                      master[i].e_ready   = master_e_ready[i];

        assign                      master[i].b_valid   = master_b_valid[i];
        assign                      master[i].b_bits    = master_b_bits[i];
        assign master_b_ready[i]  = master[i].b_ready;

        assign                      master[i].d_valid   = master_d_valid[i];
        assign                      master[i].d_bits    = master_d_bits[i];
        assign master_d_ready[i]  = master[i].d_ready;
      end
    endgenerate

    generate
      for(i = 0; i < SLAVE_NUM; i++) begin
        assign                    slave[i].a_valid = slave_a_valid[i];
        assign                    slave[i].a_bits  = slave_a_bits[i];
        assign slave_a_ready[i] = slave[i].a_ready;

        assign                    slave[i].c_valid = slave_c_valid[i];
        assign                    slave[i].c_bits  = slave_c_bits[i];
        assign slave_c_ready[i] = slave[i].c_ready;

        assign                    slave[i].e_valid = slave_e_valid[i];
        assign                    slave[i].e_bits  = slave_e_bits[i];
        assign slave_e_ready[i] = slave[i].e_ready;

        assign slave_b_valid[i] = slave[i].b_valid;
        assign slave_b_bits[i]  = slave[i].b_bits;
        assign                    slave[i].b_ready = slave_b_ready[i];

        assign slave_d_valid[i] = slave[i].d_valid;
        assign slave_d_bits[i]  = slave[i].d_bits;
        assign                    slave[i].d_ready = slave_d_ready[i];
      end
    endgenerate

    // 2D REQ AND GRANT MATRIX REVERSING (TRANSPOSE)
    for(i=0;i<SLAVE_NUM;i++) begin 
        for(j=0;j<MASTER_NUM;j++) begin 
          assign a_valid_int_reverse[i][j] = a_valid_int[j][i];
          assign c_valid_int_reverse[i][j] = c_valid_int[j][i];
          assign e_valid_int_reverse[i][j] = e_valid_int[j][i];
          assign b_valid_int_reverse[j][i] = b_valid_int[i][j];
          assign d_valid_int_reverse[j][i] = d_valid_int[i][j];

          assign a_ready_int_reverse[j][i] = a_ready_int[i][j];
          assign c_ready_int_reverse[j][i] = c_ready_int[i][j];
          assign e_ready_int_reverse[j][i] = e_ready_int[i][j];
          assign b_ready_int_reverse[i][j] = b_ready_int[j][i];
          assign d_ready_int_reverse[i][j] = d_ready_int[j][i];
        end
    end

    for(i=0; i<SLAVE_NUM; i++) begin : slave2master 
       tl_xbar_s2m #(
          .MASTER_NUM     (MASTER_NUM),
          .SOURCE_LSB     (SOURCE_LSB),
          .SOURCE_MSB     (SOURCE_MSB),
          .SINK_LSB       (SINK_LSB),
          .SINK_MSB       (SINK_MSB)
       ) s2m_inst(
          .clk_i                    (clk_i                       ),       
          .rst_i                    (rst_i                       ),       

          .a_valid_i                (a_valid_int_reverse[i]      ),                              
          .a_ready_o                (a_ready_int[i]              ),                      
          .a_bits_i                 (master_a_bits                ),                     
          .a_valid_o                (slave_a_valid[i]           ),                       
          .a_ready_i                (slave_a_ready[i]           ),                             
          .a_bits_o                 (slave_a_bits[i]            ),                     

          .c_valid_i                (c_valid_int_reverse[i]      ),                                
          .c_ready_o                (c_ready_int[i]              ),                                
          .c_bits_i                 (master_c_bits                ),                                 
          .c_valid_o                (slave_c_valid[i]           ),                              
          .c_ready_i                (slave_c_ready[i]           ),                                    
          .c_bits_o                 (slave_c_bits[i]            ),                             

          .e_valid_i                (e_valid_int_reverse[i]      ),                                
          .e_ready_o                (e_ready_int[i]              ),                                
          .e_bits_i                 (master_e_bits                ),                                 
          .e_valid_o                (slave_e_valid[i]           ),                              
          .e_ready_i                (slave_e_ready[i]           ),                                    
          .e_bits_o                 (slave_e_bits[i]            ),              

          .b_valid_i                (slave_b_valid[i]           ),                         
          .b_ready_o                (slave_b_ready[i]           ),                         
          .b_source_i               (slave_b_bits[i].source     ),                            
          .b_valid_o                (b_valid_int[i]              ),                     
          .b_ready_i                (b_ready_int_reverse[i]      ),                            

          .d_valid_i                (slave_d_valid[i]           ),                                 
          .d_ready_o                (slave_d_ready[i]           ),                                 
          .d_source_i               (slave_d_bits[i].source     ),                              
          .d_valid_o                (d_valid_int[i]              ),                                
          .d_ready_i                (d_ready_int_reverse[i]      )                  
      );
    end

    for (i=0; i<MASTER_NUM; i++) begin : master2slave
       tl_xbar_m2s #(
          .ADDR_WIDTH     (TL_ADDR_WIDTH),
          .REGION_NUM     (REGION_NUM),
          .SLAVE_NUM      (SLAVE_NUM),
          .SOURCE_LSB     (SOURCE_LSB),
          .SOURCE_MSB     (SOURCE_MSB),
          .SINK_LSB       (SINK_LSB),
          .SINK_MSB       (SINK_MSB)
       ) m2s_inst(
          .clk_i                    (clk_i                    ),                        
          .rst_i                    (rst_i                    ),                        

          .a_valid_i                (master_a_valid[i]         ),                                         
          .a_ready_o                (master_a_ready[i]         ),                                         
          .a_addr_i                 (master_a_bits[i].address  ),                                                 
          .a_valid_o                (a_valid_int[i]           ),                                     
          .a_ready_i                (a_ready_int_reverse[i]   ),                                                   

          .c_valid_i                (master_c_valid[i]         ),                                         
          .c_ready_o                (master_c_ready[i]         ),                                         
          .c_addr_i                 (master_c_bits[i].address  ),                                                 
          .c_valid_o                (c_valid_int[i]           ),                                     
          .c_ready_i                (c_ready_int_reverse[i]   ),                                                   

          .e_valid_i                (master_e_valid[i]         ),                                         
          .e_ready_o                (master_e_ready[i]         ),                                         
          .e_bits_i                 (master_e_bits[i]          ),                                         
          .e_valid_o                (e_valid_int[i]           ),                                     
          .e_ready_i                (e_ready_int_reverse[i]   ),                                                   

          .b_valid_i                (b_valid_int_reverse[i]   ),                                               
          .b_ready_o                (b_ready_int[i]           ),                                       
          .b_bits_i                 (slave_b_bits            ),                                   
          .b_valid_o                (master_b_valid[i]         ),                                        
          .b_ready_i                (master_b_ready[i]         ),                                       
          .b_bits_o                 (master_b_bits[i]          ),                                     

          .d_valid_i                (d_valid_int_reverse[i]   ),                  
          .d_ready_o                (d_ready_int[i]           ),                  
          .d_bits_i                 (slave_d_bits             ),               
          .d_valid_o                (master_d_valid[i]         ),                 
          .d_ready_i                (master_d_ready[i]         ),                
          .d_bits_o                 (master_d_bits[i]          ),

          .start_addr_i             (start_addr_i             ),        
          .end_addr_i               (end_addr_i               ),      
          .enable_region_i          (region_en_i              ),           
          .connectivity_map_i       ({SLAVE_NUM{1'b1}}       )
         );
    end

endmodule