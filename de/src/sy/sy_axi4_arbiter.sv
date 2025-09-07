// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_axi4_arbiter.v
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

module sy_axi4_arbiter
  import sy_pkg::*;
#(
    parameter int unsigned PORT_NUM = 2
)(
    input   logic                             clk_i,
    input   logic                             rst_i,
    // AXI4 in 
    input   logic             [PORT_NUM-1:0]  inp_axi_aw_valid_i,
    output  logic             [PORT_NUM-1:0]  inp_axi_aw_ready_o,         
    input   axi_pkg::aw_chan_t[PORT_NUM-1:0]  inp_axi_aw_bits_i,
    input   logic             [PORT_NUM-1:0]  inp_axi_ar_valid_i,
    output  logic             [PORT_NUM-1:0]  inp_axi_ar_ready_o,         
    input   axi_pkg::ar_chan_t[PORT_NUM-1:0]  inp_axi_ar_bits_i,
    input   logic             [PORT_NUM-1:0]  inp_axi_w_valid_i,
    output  logic             [PORT_NUM-1:0]  inp_axi_w_ready_o,         
    input   axi_pkg::w_chan_t [PORT_NUM-1:0]  inp_axi_w_bits_i,
    output  logic             [PORT_NUM-1:0]  inp_axi_r_valid_o,
    input   logic             [PORT_NUM-1:0]  inp_axi_r_ready_i,
    output  axi_pkg::r_chan_t [PORT_NUM-1:0]  inp_axi_r_bits_o, 
    output  logic             [PORT_NUM-1:0]  inp_axi_b_valid_o,
    input   logic             [PORT_NUM-1:0]  inp_axi_b_ready_i,
    output  axi_pkg::b_chan_t [PORT_NUM-1:0]  inp_axi_b_bits_o,

    output  logic                             oup_axi_aw_valid_o,
    input   logic                             oup_axi_aw_ready_i,         
    output  axi_pkg::aw_chan_t                oup_axi_aw_bits_o,
    output  logic                             oup_axi_ar_valid_o,
    input   logic                             oup_axi_ar_ready_i,         
    output  axi_pkg::ar_chan_t                oup_axi_ar_bits_o,
    output  logic                             oup_axi_w_valid_o,
    input   logic                             oup_axi_w_ready_i,         
    output  axi_pkg::w_chan_t                 oup_axi_w_bits_o,
    input   logic                             oup_axi_r_valid_i,
    output  logic                             oup_axi_r_ready_o,
    input   axi_pkg::r_chan_t                 oup_axi_r_bits_i, 
    input   logic                             oup_axi_b_valid_i,
    output  logic                             oup_axi_b_ready_o,
    input   axi_pkg::b_chan_t                 oup_axi_b_bits_i

);
  
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  typedef enum logic[1:0] {IDLE, READ, WRITE, RESP} state_e;
  state_e                           state_d, state_q;
  logic [PORT_NUM-1:0]              axi_req_all;
  logic [PORT_NUM-1:0]              axi_gnt_all;
  logic                             axi_req;
  logic                             axi_gnt;
  logic[$clog2(PORT_NUM)-1:0]       axi_port_sel;
  logic                             is_rd;
  logic                             is_wr;
  axi_pkg::aw_chan_t                axi_aw_bits;
  axi_pkg::ar_chan_t                axi_ar_bits;
  logic                             sel_port_d,sel_port_q;
  logic [9:0]                       counter_d, counter_q;

//======================================================================================================================
// Instance
//======================================================================================================================
  always_comb begin :  axi_req_gen
    for (int i = 0; i < PORT_NUM; i++) begin
      axi_req_all[i] = inp_axi_aw_valid_i[i] | inp_axi_ar_valid_i[i];
    end 
  end
  
  // arbiter 
  rr_arb_tree #(
    .NumIn     (PORT_NUM),
    .DataWidth (1)
  ) req_rr_arb_tree (
    .clk_i  (clk_i          ),
    .rst_ni (rst_i          ),
    .flush_i('0             ),
    .rr_i   ('0             ),
    .req_i  (axi_req_all    ),
    .gnt_o  (axi_gnt_all    ),
    .data_i ('0             ),
    .gnt_i  (axi_gnt        ),
    .req_o  (axi_req        ),
    .data_o (               ),
    .idx_o  (axi_port_sel   )
  );

  assign is_rd = inp_axi_ar_valid_i[axi_port_sel];
  assign is_wr = inp_axi_aw_valid_i[axi_port_sel];
  assign axi_aw_bits = inp_axi_aw_bits_i[axi_port_sel];
  assign axi_ar_bits = inp_axi_ar_bits_i[axi_port_sel];

  assign inp_axi_ar_ready_o = axi_gnt_all & {PORT_NUM{is_rd}};
  assign inp_axi_aw_ready_o = axi_gnt_all & {PORT_NUM{is_wr}};

  assign oup_axi_aw_bits_o = axi_aw_bits;
  assign oup_axi_ar_bits_o = axi_ar_bits;
  assign oup_axi_w_bits_o = inp_axi_w_bits_i[sel_port_q];

  always_comb begin
    for (integer i=0;i<PORT_NUM;i++) begin
      inp_axi_r_bits_o[i] = oup_axi_r_bits_i;
      inp_axi_b_bits_o[i] = oup_axi_b_bits_i;
    end
  end

  always_comb begin : FSM 
      state_d   = state_q;
      counter_d = counter_q;
      sel_port_d = sel_port_q;
      axi_gnt = 1'b0;
      oup_axi_ar_valid_o = 1'b0;
      oup_axi_aw_valid_o = 1'b0;
      oup_axi_w_valid_o = 1'b0;
      oup_axi_r_ready_o = 1'b0;
      oup_axi_b_ready_o = 1'b0;

      inp_axi_w_ready_o = '0;
      inp_axi_r_valid_o = '0;
      inp_axi_b_valid_o = '0;
      unique case(state_q)
        IDLE : begin 
          if (axi_req) begin
            if (is_rd) begin
              axi_gnt = oup_axi_ar_ready_i;
              oup_axi_ar_valid_o = 1'b1;
              sel_port_d = axi_port_sel;
              if (oup_axi_ar_ready_i) begin
                state_d = READ;
                counter_d = axi_ar_bits.len;
              end
            end else if (is_wr) begin
              axi_gnt = oup_axi_aw_ready_i;
              oup_axi_aw_valid_o = 1'b1;
              sel_port_d = axi_port_sel;
              if (oup_axi_aw_ready_i) begin
                state_d = WRITE;
                counter_d = axi_aw_bits.len;
              end
            end
          end
        end
        READ: begin
          oup_axi_r_ready_o = inp_axi_r_ready_i[sel_port_q];
          inp_axi_r_valid_o[sel_port_q] = oup_axi_r_valid_i;
          if (oup_axi_r_valid_i && oup_axi_r_ready_o) begin
            counter_d = counter_q - 1;
            if (counter_q == 0) begin
              state_d = IDLE;
            end
          end
        end
        WRITE : begin
          oup_axi_w_valid_o = inp_axi_w_valid_i[sel_port_q];
          inp_axi_w_ready_o[sel_port_q] = oup_axi_w_ready_i;
          if (oup_axi_w_valid_o && oup_axi_w_ready_i) begin
            counter_d = counter_q - 1;
            if (counter_q == 0) begin
              state_d = RESP;
            end
          end
        end
        RESP : begin
          oup_axi_b_ready_o = inp_axi_b_ready_i[sel_port_q];
          inp_axi_b_valid_o[sel_port_q] = oup_axi_b_valid_i;
          if (oup_axi_b_valid_i && oup_axi_b_ready_o) begin
            state_d = IDLE;
          end
        end
        default : state_d = IDLE;
      endcase
  end

  always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
      if(`DFF_IS_R(rst_i)) begin
        state_q <= IDLE;
        sel_port_q <= '0;
        counter_q <= '0;
      end else begin
        state_q <= state_d;
        sel_port_q <= sel_port_d;
        counter_q <= counter_d;
      end
  end

endmodule