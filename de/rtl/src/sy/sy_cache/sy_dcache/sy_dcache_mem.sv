// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dcache_mem.v
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

module sy_dcache_mem  
  import sy_pkg::*;
#(
  parameter TAG_PORT           = 2,
  parameter DATA_PORT          = 2
) (
  input  logic                                            clk_i,
  input  logic                                            rst_i,

  input  logic                                            flush_i,              
  // tag port
  input  logic [TAG_PORT-1:0]                             tag_req_i,
  output logic [TAG_PORT-1:0]                             tag_gnt_o,
  input  tag_req_t [TAG_PORT-1:0]                         tag_req_bits_i,
  output tag_rsp_t [TAG_PORT-1:0]                         tag_rsp_bits_o,

  // data port         
  input  logic [DATA_PORT-1:0]                            data_req_i,
  output logic [DATA_PORT-1:0]                            data_gnt_o,
  input  data_req_t [DATA_PORT-1:0]                       data_req_bits_i,
  output data_rsp_t [DATA_PORT-1:0]                       data_rsp_bits_o

);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

  logic [DCACHE_WAY_NUM-1:0]                              data_ram_ren ;   // read all ways                
  logic [DCACHE_WAY_NUM-1:0]                              data_ram_wen;                   
  logic [DCACHE_TAG_LSB-DCACHE_DATA_WTH-1:0]              data_ram_raddr;      // used to select data array
  logic [DCACHE_TAG_LSB-DCACHE_DATA_WTH-1:0]              data_ram_waddr;      // used to select data array
  logic [DCACHE_WAY_NUM-1:0][DCACHE_DATA_SIZE*8-1:0]      data_ram_rdata;            
  logic [DCACHE_DATA_SIZE*8-1:0]                          data_ram_wdata;            

  logic [DCACHE_WAY_NUM-1:0]                              tag_array_ren;      // read all ways                
  logic [DCACHE_WAY_NUM-1:0]                              tag_array_wen;                   
  logic [DCACHE_TAG_LSB-DCACHE_BLOCK_WTH-1:0]             tag_array_raddr;      // used to select data array
  logic [DCACHE_TAG_LSB-DCACHE_BLOCK_WTH-1:0]             tag_array_waddr;      // used to select data array
  tag_t [DCACHE_WAY_NUM-1:0]                              tag_array_rdata;            
  tag_t                                                   tag_array_wdata;            

  logic [DCACHE_SET_SIZE-1:0][DCACHE_TAG_WTH-1:0]         tag_array [DCACHE_WAY_NUM-1:0];
  cache_state_e [DCACHE_SET_SIZE-1:0]                     state_array [DCACHE_WAY_NUM-1:0];
  logic [DCACHE_SET_SIZE-1:0]                             cl_valid [DCACHE_WAY_NUM-1:0];   // cache_line_valid
  logic [DCACHE_WAY_NUM-1:0]                              valid_bit;
  logic [DCACHE_WAY_NUM-1:0][DCACHE_TAG_WTH-1:0]          tag_rd_data;
  cache_state_e [DCACHE_WAY_NUM-1:0]                      state_rd_data;

  data_req_t                                              data_req_bits;
  tag_req_t                                               tag_req_bits;
  
  logic                                                   tag_req;
  logic                                                   data_req;

  logic [$clog2(TAG_PORT)-1:0]                            tag_port_sel;
  logic [$clog2(DATA_PORT)-1:0]                           data_port_sel;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]                      data_rd_way_idx, data_rd_way_idx_dly;


//======================================================================================================================
// Instance
//======================================================================================================================

  // arbiter for tag
  rr_arb_tree #(
    .NumIn     (TAG_PORT),
    .DataWidth (1)
  ) tag_rr_arb_tree (
    .clk_i  (clk_i          ),
    .rst_ni (rst_i          ),
    .flush_i('0             ),
    .rr_i   ('0             ),
    .req_i  (tag_req_i      ),
    .gnt_o  (tag_gnt_o      ),
    .data_i ('0             ),
    .gnt_i  (1'b1           ),
    .req_o  (tag_req        ),
    .data_o (               ),
    .idx_o  (tag_port_sel   )
  );

  // arbiter for tag
  rr_arb_tree #(
    .NumIn     (DATA_PORT),
    .DataWidth (1)
  ) data_rr_arb_tree (
    .clk_i  (clk_i          ),
    .rst_ni (rst_i          ),
    .flush_i('0             ),
    .rr_i   ('0             ),
    .req_i  (data_req_i     ),
    .gnt_o  (data_gnt_o     ),
    .data_i ('0             ),
    .gnt_i  (1'b1           ),
    .req_o  (data_req       ),
    .data_o (               ),
    .idx_o  (data_port_sel  )
  );

  assign data_req_bits = data_req_bits_i[data_port_sel];
  assign tag_req_bits = tag_req_bits_i[tag_port_sel];
  oneHot2Int #(
    .WIDTH    (DCACHE_WAY_NUM)
  ) way_idx(
      .in_i       (data_req_bits.way_en),
      .cnt_o      (data_rd_way_idx),
      .empty_o    ()
  );

  assign data_ram_waddr               = data_req_bits.idx[DCACHE_TAG_LSB-1:DCACHE_DATA_WTH];
  assign data_ram_wdata               = data_req_bits.wr_data;
  assign data_ram_raddr               = data_req_bits.idx[DCACHE_TAG_LSB-1:DCACHE_DATA_WTH];
  assign data_rsp_bits_o[0].rd_data   = data_ram_rdata[data_rd_way_idx_dly];
  assign data_rsp_bits_o[1].rd_data   = data_ram_rdata[data_rd_way_idx_dly];

  assign tag_array_waddr          = tag_req_bits.idx[DCACHE_TAG_LSB-1:DCACHE_BLOCK_WTH];
  assign tag_array_wdata          = tag_req_bits.wr_tag;
  assign tag_array_raddr          = tag_req_bits.idx[DCACHE_TAG_LSB-1:DCACHE_BLOCK_WTH];

  for (genvar i = 0; i < DATA_PORT; i++) begin 
    for (genvar j=0; j < DCACHE_WAY_NUM; j++) begin
      assign tag_rsp_bits_o[i].tag_data[j].valid  = valid_bit[j];
      assign tag_rsp_bits_o[i].tag_data[j].state  = state_rd_data[j];
      assign tag_rsp_bits_o[i].tag_data[j].tag    = tag_rd_data[j];
    end
  end

  for (genvar i = 0; i < DCACHE_WAY_NUM; i++) begin : tag_and_data
    assign data_ram_wen[i]   =  data_req_bits.we && data_req && data_req_bits.way_en[i];
    assign data_ram_ren[i]   = !data_req_bits.we && data_req && data_req_bits.way_en[i];

    assign tag_array_wen[i]  =  tag_req_bits.we  && tag_req  && tag_req_bits.way_en[i];
    assign tag_array_ren[i]  = !tag_req_bits.we  && tag_req  && tag_req_bits.way_en[i];
//======================================================================================================================
// Data array
//======================================================================================================================
    sdp_512x64sd1_wrap data_ram(
      .wr_clk_i                   (clk_i                ),              
      .we_i                       (data_ram_wen[i]      ),          
      .waddr_i                    (data_ram_waddr       ),             
      .wdata_i                    (data_ram_wdata       ),             
      .wstrb_i                    (8'hff                ),             
      .rd_clk_i                   (clk_i                ),              
      .re_i                       (data_ram_ren[i]      ),          
      .raddr_i                    (data_ram_raddr       ),             
      .rdata_o                    (data_ram_rdata[i]    )    
    );
//======================================================================================================================
// Tag array
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i)begin
      if (!rst_i) begin
        tag_array[i] <= '0;
      // write tag
      end else if (tag_array_wen[i]) begin
        tag_array[i][tag_array_waddr] <= tag_array_wdata.tag;
      end
    end

    // read tag
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        tag_rd_data[i] <= '0;
      end else if(tag_array_ren[i]) begin
        tag_rd_data[i] <= tag_array[i][tag_array_raddr];
      end 
    end
//======================================================================================================================
// State array
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i)begin
      if (!rst_i) begin
        for (integer j=0;j<DCACHE_SET_SIZE;j++) begin
          state_array[i][j] <= Nothing;
        end
      // flush state
      end else if (flush_i) begin
        for (integer j=0;j<DCACHE_SET_SIZE;j++) begin
          state_array[i][j] <= Nothing;
        end
      // write state
      end else if (tag_array_wen[i]) begin
        state_array[i][tag_array_waddr] <= tag_array_wdata.state;
      end
    end

    // read state
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        state_rd_data[i] <= Nothing;
      end else if(tag_array_ren[i]) begin
        state_rd_data[i] <= state_array[i][tag_array_raddr];
      end else begin
        state_rd_data[i] <= Nothing; 
      end
    end
//======================================================================================================================
// Valid bit array
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i) begin
      if(!rst_i) begin
        cl_valid[i] <= '0;  
      end else if(flush_i) begin
        cl_valid[i] <= '0;
      // refill cache line
      end else if(tag_array_wen[i]) begin
        cl_valid[i][tag_array_waddr] <= tag_array_wdata.valid;
      end
    end
    // read valid bit
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        valid_bit[i] <= 1'b0;
      end else if(tag_array_ren[i]) begin
        valid_bit[i] <= cl_valid[i][tag_array_raddr];
      end else begin
        valid_bit[i] <= 1'b0;       
      end
    end
  end

//======================================================================================================================
// registers
//======================================================================================================================

    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        data_rd_way_idx_dly <= '0;
      end else begin
        data_rd_way_idx_dly <= data_rd_way_idx;
      end
  end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================


endmodule