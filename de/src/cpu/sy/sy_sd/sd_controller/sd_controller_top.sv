// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_controller_top.v
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

module sd_controller_top
    import sy_pkg::*;
(
  input   wire          clk_i,   // CPU clock
  input   wire          rst_i,   // active low

  output  reg           sd_irq,
  output  wire          sd_clk,
  input   wire          sd_detect,
  output  wire          sd_reset,

  input   logic [3:0]   sd_dat_i,
  output  logic [3:0]   sd_dat_o,
  output  logic         sd_dat_oe_o,
  input   logic         sd_cmd_i,
  output  logic         sd_cmd_o,
  output  logic         sd_cmd_oe_o,

  input   wire          spisd_en,
  input   wire          spisd_we,
  input   wire [7:0]    spisd_be,
  input   wire [15:0]   spisd_addr,
  input   wire [63:0]   spisd_wrdata,
  output  wire [63:0]   spisd_rddata
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  reg [15:0]                    spisd_addr_0;
  logic                         init_done;
  // Request Slave
  logic [`SD_ADDR_WIDTH-1:0]    req_addr_sd;    // addr in SD 
  logic [`SD_ADDR_WIDTH-1:0]    req_addr_dma;   // addr in fake memory
  logic [`SD_ADDR_WIDTH-10:0]   req_blkcnt;

  logic                         req_wr;         // HIGH write
  logic                         req_rd;         // HIGH read
  logic                         req_wr_0;       // HIGH write delayed
  logic                         req_rd_0;       // HIGH read delayed
  logic                         req_wr_1;       // HIGH write delayed
  logic                         req_rd_1;       // HIGH read delayed
  logic [`SD_ADDR_WIDTH-1:0]    req_addr_sd_f;  // addr in SD 
  logic [`SD_ADDR_WIDTH-1:0]    req_addr_dma_f; // addr in fake DMA memory
  logic                         sd_irq_en;
  logic [31:0]                  core_buffer_addr;
  logic                         core_buffer_ce;
  logic                         core_buffer_wr;
  logic [1:0]                   core_buffer_sz;
  logic [`NOC_DATA_BITS]        core_buffer_data;
  logic [`NOC_DATA_BITS]        buffer_core_data;
  logic                         sys_rst_reg;
  logic [31:0]                  slow_clk_divider;   
  logic [31:0]                  fast_clk_divider;   
  logic [31:0]                  power_stable_cnt;   
  logic [31:0]                  acmd41_reissue_cnt;   
  
  wire                          req_rdy, is_hcxc;
  wire                          sys_rst;
  // Response Master
  wire                          resp_ok;    // HIGH ok; LOW err.
  wire                          resp_val;
  logic                         resp_rdy;
  logic [63:0]                  resp_vec, resp_data, spisd_wrdata_rev, spisd_rddata_norev, spisd_rddata_rev;
  logic [7:0]                   init_state;
  // compact FSM output
  wire [31:0]                   counter;
  wire [42:0]                   init_fsm; // {adr, dat, we, stb, counter_en}
  wire [5:0]                    tran_state;
  // tran compact FSM output
  wire [41:0]                   tran_fsm; // {adr, dat, we, stb}

//======================================================================================================================
// Instance
//======================================================================================================================
  for (genvar i = 0; i < 64; i += 8) begin : data_rev
    assign spisd_wrdata_rev[i +: 8] = spisd_wrdata[(56-i) +: 8];
    assign spisd_rddata_rev[i +: 8] = spisd_rddata_norev[(56-i) +: 8];
  end
    
  always @(`DFF_CR(clk_i,rst_i))
    if (`DFF_IS_R(rst_i)) begin
      sd_irq        <= 0;
      sd_irq_en     <= 0;
      resp_vec      <= 0;
      sys_rst_reg   <= 0;
      req_rd_0      <= 0;
      req_wr_0      <= 0;
      req_rd_1      <= 0;
      req_wr_1      <= 0;
      req_rd        <= 0;
      req_wr        <= 0;
      req_addr_sd   <= 0;
      req_addr_dma  <= 0;
      slow_clk_divider <= 32'd49;
      fast_clk_divider <= 32'd1;
      power_stable_cnt <= 32'd3000000;
      acmd41_reissue_cnt <= 32'd15000000;
    end else begin
      spisd_addr_0 <= spisd_addr;
      if (resp_val) begin
          resp_vec <= {resp_vec,resp_ok};
      end

      resp_rdy    <= resp_val;
      sd_irq      <= sd_irq_en & req_rdy & (req_wr|req_rd);
      sys_rst_reg <= 0;
      req_rd_0    <= req_rd;
      req_wr_0    <= req_wr;
      req_rd_1    <= req_rd & ~req_rd_0;
      req_wr_1    <= req_wr & ~req_wr_0;

      if (spisd_en&(|spisd_we)&(spisd_addr[15:14]==2'b00)) begin
  	    case(spisd_addr[6:3])
  	      4'h0: req_addr_sd    <= spisd_wrdata;
  	      4'h1: req_addr_dma   <= spisd_wrdata;
  	      4'h2: begin resp_vec <= 0; req_blkcnt <= spisd_wrdata; end
  	      4'h3: req_rd         <= spisd_wrdata;
  	      4'h4: req_wr         <= spisd_wrdata;
  	      4'h5: sd_irq_en      <= spisd_wrdata;
  	      4'h6: sys_rst_reg    <= spisd_wrdata;
          4'h7: begin slow_clk_divider <= spisd_wrdata[31:0]; fast_clk_divider <= spisd_wrdata[63:32];   end
          4'h8: begin power_stable_cnt <= spisd_wrdata[31:0]; acmd41_reissue_cnt <= spisd_wrdata[63:32]; end
  	      default:;
  	    endcase
      end
  	  case(spisd_addr[6:3])
  	    4'h0: resp_data <= req_addr_sd_f;
  	    4'h1: resp_data <= req_addr_dma_f;
        4'h2: resp_data <= {sd_detect,is_hcxc,init_done,req_rdy,sd_irq,sd_irq_en,req_wr,req_rd};
        4'h3: resp_data <= resp_vec;
        4'h4: resp_data <= init_state;
        4'h5: resp_data <= counter;
        4'h6: resp_data <= init_fsm;
        4'h7: resp_data <= tran_state;
        4'h8: resp_data <= tran_fsm;
        4'h9: resp_data <= {fast_clk_divider,slow_clk_divider};
        4'hA: resp_data <= {acmd41_reissue_cnt,power_stable_cnt};
      default:resp_data <= 32'HDEADBEEF;
      endcase
    end

  assign sys_rst = !sys_rst_reg & rst_i; // active low 
  sd_controller sd_controller_inst(
    // Clock and reset
    .sys_clk                (clk_i),
    .sys_rst                (sys_rst),
    // SD interface
    .sd_cd                  (sd_detect),
    .sd_reset               (sd_reset),
    .sd_clk                 (sd_clk),
    .sd_cmd_dat_i           (sd_cmd_i),
    .sd_cmd_out_o           (sd_cmd_o),
    .sd_cmd_oe_o            (sd_cmd_oe_o ),
    .sd_dat_dat_i           (sd_dat_i),
    .sd_dat_out_o           (sd_dat_o),
    .sd_dat_oe_o            (sd_dat_oe_o ),

    .init_done              (init_done),
    .req_addr_sd            (req_addr_sd),
    .req_addr_dma           (req_addr_dma),
    .req_blkcnt             (req_blkcnt),
    .req_wr                 (req_wr_1),
    .req_val                (req_wr_1|req_rd_1),
    .req_rdy                (req_rdy),
    .req_addr_sd_f          (req_addr_sd_f),
    .req_addr_dma_f         (req_addr_dma_f),

    .resp_ok                (resp_ok),
    .resp_val               (resp_val),
    .resp_rdy               (resp_rdy),
    
    .core_buffer_addr       ({16'h0,spisd_addr}),
    .core_buffer_data       (spisd_wrdata_rev),
    .core_buffer_ce         (spisd_en & spisd_addr[15]),
    .core_buffer_wr         (|spisd_we),
    .core_buffer_sz         (2'b11),
    .buffer_core_data       (spisd_rddata_norev),

    .slow_clk_divider       (slow_clk_divider),
    .fast_clk_divider       (fast_clk_divider),

    .power_stable_cnt       (power_stable_cnt  ),
    .acmd41_reissue_cnt     (acmd41_reissue_cnt),

    .is_hcxc                (is_hcxc),
    .init_state             (init_state),
    // compact FSM output
    .counter                (counter),
    .init_fsm               (init_fsm), // {adr, dat, we, stb, counter_en}
    .tran_state             (tran_state),
    // compact FSM output
    .tran_fsm               (tran_fsm) // {adr, dat, we, stb, counter_en}
  );

  assign  spisd_rddata = spisd_addr_0[15] ? spisd_rddata_rev : resp_data;  

endmodule 