// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_L2_cache_mem.v
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

module sy_L2_cache_mem
  import sy_pkg::*;
(
  input  logic                                            clk_i,
  input  logic                                            rst_i,

  input  logic                                            flush_i,              
  // tag port
  input  logic                                            tag_req_i,
  input  L2_tag_req_t                                     tag_req_bits_i,
  output L2_tag_rsp_t                                     tag_rsp_bits_o,
  // data port         
  input  logic                                            data_req_i,
  input  L2_data_req_t                                    data_req_bits_i,
  output L2_data_rsp_t                                    data_rsp_bits_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef struct packed {
        logic [L2_CACHE_TAG_WTH-1:0]    tag;
        logic                           dirty;    
        logic                           valid;
    } L2_tag_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

  logic [L2_CACHE_WAY_NUM-1:0]                            data_ram_ren ;   // read all ways                
  logic [L2_CACHE_WAY_NUM-1:0]                            data_ram_wen;                   
  logic [L2_CACHE_TAG_LSB-L2_CACHE_DATA_WTH-1:0]          data_ram_raddr;  // used to select data array
  logic [L2_CACHE_TAG_LSB-L2_CACHE_DATA_WTH-1:0]          data_ram_waddr;  // used to select data array
  logic [L2_CACHE_WAY_NUM-1:0][L2_CACHE_DATA_SIZE*8-1:0]  data_ram_rdata;            
  logic [L2_CACHE_DATA_SIZE*8-1:0]                        data_ram_wdata;            

  logic [L2_CACHE_WAY_NUM-1:0]                            tag_array_ren;      // read all ways                
  logic [L2_CACHE_WAY_NUM-1:0]                            tag_array_wen;                   
  logic [L2_CACHE_TAG_LSB-L2_CACHE_BLOCK_WTH-1:0]         tag_array_raddr;      // used to select data array
  logic [L2_CACHE_TAG_LSB-L2_CACHE_BLOCK_WTH-1:0]         tag_array_waddr;      // used to select data array

  L2_tag_t [L2_CACHE_WAY_NUM-1:0]                         tag_array_rdata;            
  L2_tag_t                                                tag_array_wdata;            

  logic [L2_CACHE_SET_SIZE-1:0][L2_CACHE_TAG_WTH-1:0]     tag_array   [L2_CACHE_WAY_NUM-1:0];
  logic [L2_CACHE_SET_SIZE-1:0]                           dirty_array [L2_CACHE_WAY_NUM-1:0];
  logic [L2_CACHE_SET_SIZE-1:0]                           cl_valid    [L2_CACHE_WAY_NUM-1:0];   // cache_line_valid
  logic [L2_CACHE_WAY_NUM-1:0]                            valid_bit;
  logic [L2_CACHE_WAY_NUM-1:0][L2_CACHE_TAG_WTH-1:0]      tag_rd_data;
  logic [L2_CACHE_WAY_NUM-1:0]                            dirty_rd_data;
//======================================================================================================================
// Instance
//======================================================================================================================
  assign data_ram_waddr               = data_req_bits_i.idx[L2_CACHE_TAG_LSB-1:L2_CACHE_DATA_WTH];
  assign data_ram_wdata               = data_req_bits_i.wr_data;
  assign data_ram_raddr               = data_req_bits_i.idx[L2_CACHE_TAG_LSB-1:L2_CACHE_DATA_WTH];
  for (genvar i=0;i<L2_CACHE_WAY_NUM;i++) begin
    assign data_rsp_bits_o.rd_data[i] = data_ram_rdata[i];
  end

  assign tag_array_waddr          = tag_req_bits_i.idx[L2_CACHE_TAG_LSB-1:L2_CACHE_BLOCK_WTH];
  assign tag_array_wdata.tag      = tag_req_bits_i.tag;
  assign tag_array_wdata.valid    = tag_req_bits_i.tag_valid;
  assign tag_array_wdata.dirty    = tag_req_bits_i.dirty;
  assign tag_array_raddr          = tag_req_bits_i.idx[L2_CACHE_TAG_LSB-1:L2_CACHE_BLOCK_WTH];

  for (genvar i=0; i < L2_CACHE_WAY_NUM; i++) begin
    assign tag_rsp_bits_o.tag_valid[i]  = valid_bit[i];
    assign tag_rsp_bits_o.dirty[i]      = dirty_rd_data[i];
    assign tag_rsp_bits_o.tag[i]        = tag_rd_data[i];
  end

  for (genvar i = 0; i < L2_CACHE_WAY_NUM; i++) begin : tag_and_data
    assign data_ram_wen[i]   =  data_req_bits_i.we && data_req_i && data_req_bits_i.way_en[i];
    assign data_ram_ren[i]   = !data_req_bits_i.we && data_req_i && data_req_bits_i.way_en[i];

    assign tag_array_wen[i]  =  tag_req_bits_i.we  && tag_req_i  && tag_req_bits_i.way_en[i];
    assign tag_array_ren[i]  = !tag_req_bits_i.we  && tag_req_i  && tag_req_bits_i.way_en[i];
    // data array
    sdp_2048x64sd1_wrap data_ram(
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
    // Tag array
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if (`DFF_IS_R(rst_i)) begin
        tag_array[i] <= '0;
      // write tag
      end else if (tag_array_wen[i]) begin
        tag_array[i][tag_array_waddr] <= tag_array_wdata.tag;
      end
    end

    // read tag
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        tag_rd_data[i] <= '0;
      end else if(tag_array_ren[i]) begin
        tag_rd_data[i] <= tag_array[i][tag_array_raddr];
      end 
    end
    // State array
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if (`DFF_IS_R(rst_i)) begin
        for (integer j=0;j<L2_CACHE_SET_SIZE;j++) begin
          dirty_array[i][j] <= 1'b0;
        end
      // flush state
      end else if (flush_i) begin
        for (integer j=0;j<L2_CACHE_SET_SIZE;j++) begin
          dirty_array[i][j] <= 1'b0;
        end
      // write state
      end else if (tag_array_wen[i]) begin
        dirty_array[i][tag_array_waddr] <= tag_array_wdata.dirty;
      end
    end

    // read state
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        dirty_rd_data[i] <= 1'b0;
      end else if(tag_array_ren[i]) begin
        dirty_rd_data[i] <= dirty_array[i][tag_array_raddr];
      end else begin
        dirty_rd_data[i] <= 1'b0; 
      end
    end
    // Valid bit array
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
      if(`DFF_IS_R(rst_i)) begin
        cl_valid[i] <= '0;  
      end else if(flush_i) begin
        cl_valid[i] <= '0;
      // refill cache line
      end else if(tag_array_wen[i]) begin
        cl_valid[i][tag_array_waddr] <= tag_array_wdata.valid;
      end
    end
    // read valid bit
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        valid_bit[i] <= 1'b0;
      end else if(tag_array_ren[i]) begin
        valid_bit[i] <= cl_valid[i][tag_array_raddr];
      end else begin
        valid_bit[i] <= 1'b0;       
      end
    end
  end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule