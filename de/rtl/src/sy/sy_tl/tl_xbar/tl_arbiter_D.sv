// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_arbiter_D.v
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

module tl_arbiter_D 
  import tl_pkg::*;
#(
  parameter       SLAVE_NUM     = 0,
  parameter type  DATA_T        = logic[0:0]
) (
  input  logic                                        clk_i,
  input  logic                                        rst_i,

  input  DATA_T[SLAVE_NUM-1:0]                        inp_bits_i, 
  input  logic [SLAVE_NUM-1:0]                        inp_valid_i,
  output logic [SLAVE_NUM-1:0]                        inp_ready_o,

  output logic                                        oup_valid_o,
  output DATA_T                                       oup_bits_o,
  input  logic                                        oup_ready_i
);

  typedef enum logic [0:0] {IDLE,BURST} state_e;
  state_e state_d, state_q;

  logic [SLAVE_NUM-1:0]                           allow_pass_d, allow_pass_q;             
  logic [SLAVE_NUM-1:0]                           valid_after_filter;           
  logic [SLAVE_NUM-1:0]                           ready_after_filter;           

  logic [9:0]                                       counter_d, counter_q;

  assign valid_after_filter = inp_valid_i & allow_pass_q;

  always_comb begin : FSM 
      state_d   = state_q;
      counter_d = counter_q;
      allow_pass_d = allow_pass_q;
      unique case(state_q)
        IDLE : begin 
          if (oup_valid_o && oup_ready_i) begin
            // if the request need multiple cycles to finish transaction, 
            // make the arbiter only allow this request until it's finish
            // size in Get operation is used to indicate the data length in D channel
            if (oup_bits_o.size >= 1'b1) begin  // is burst request ?
              allow_pass_d = inp_valid_i & inp_ready_o;
              state_d = BURST;
              counter_d = oup_bits_o.size;
            end else begin
              allow_pass_d = {SLAVE_NUM{1'b1}}; 
              state_d = IDLE;
            end
          end
        end
        BURST : begin 
          if (oup_valid_o && oup_ready_i) begin // finish one transaction
            counter_d = counter_q - 1'b1; 
            if (counter_q == 1'b1) begin    // last beat
              allow_pass_d = {SLAVE_NUM{1'b1}};   // allow all requests
              state_d = IDLE;
            end 
          end  
        end
        default : state_d = IDLE;
      endcase
  end

  tl_arbiter #(
    .DATA_T     (DATA_T),
    .N_MASTER   (SLAVE_NUM)
  ) i_arbiter (
    .clk_i        (clk_i),
    .rst_i        (rst_i),

    .inp_data_i   (inp_bits_i),
    .inp_valid_i  (valid_after_filter),
    .inp_ready_o  (ready_after_filter),

    .oup_data_o   (oup_bits_o),
    .oup_valid_o  (oup_valid_o),
    .oup_ready_i  (oup_ready_i)
  );

  assign inp_ready_o = ready_after_filter & valid_after_filter;

  always_ff @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
      state_q         <= IDLE;
      allow_pass_q    <= {SLAVE_NUM{1'b1}};
      counter_q       <= 0;
    end else begin
      state_q         <= state_d;
      allow_pass_q    <= allow_pass_d;
      counter_q       <= counter_d;
    end
  end

endmodule