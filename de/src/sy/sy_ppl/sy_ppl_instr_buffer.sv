// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_instr_buffer.v
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

// most code from this file come from cva6 : https://github.com/openhwgroup/cva6  

module sy_ppl_instr_buffer
    import  sy_pkg::*;
#(
    parameter INSTR_PER_FETCH = 2,
    parameter FETCH_FIFO_DEPTH = 4
)(
    // =====================================
    // [clock & reset]
    input  logic                                        clk_i,
    input  logic                                        rst_ni,
    // =====================================
    // [fetch instr interface]
    input  logic                                        flush_i,
    input  logic [INSTR_PER_FETCH-1:0]                  fet_valid_i,
    input  logic [INSTR_PER_FETCH-1:0][63:0]            fet_addr_i,
    input  logic [INSTR_PER_FETCH-1:0][31:0]            fet_instr_i,
    // There is no need to store entire exception information in the buffer
    // because exception occur in fetch stage is only one: Instruction Page Fault
    input  logic                                        fet_ex_i, 
    output logic                                        ready_o,
    // =====================================
    // [dec interface]
    input  logic                                        dec_ready_i,
    output logic                                        dec_valid_o,
    output logic[AWTH-1:0]                              dec_pc_o,
    output logic[AWTH-1:0]                              dec_npc_o,
    output logic[IWTH-1:0]                              dec_instr_o,
    output logic                                        dec_is_compressed_o,
    output exception_t                                  dec_ex_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
  typedef struct packed {
    logic [31:0]     instr; // instruction word
    logic            ex;    // exception happened
  } instr_data_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [INSTR_PER_FETCH-1:0]                 instr_queue_full;
    logic [INSTR_PER_FETCH-1:0]                 instr_queue_empty;
    logic [INSTR_PER_FETCH*2-1:0][31:0]         instr_data_double;
    instr_data_t[INSTR_PER_FETCH-1:0]           instr_data_in;
    logic [INSTR_PER_FETCH-1:0]                 push_instr;
    instr_data_t[INSTR_PER_FETCH-1:0]           instr_data_out;
    logic [INSTR_PER_FETCH-1:0]                 pop_instr;
    logic                                       fifo_in_idx_d, fifo_in_idx_q;
    logic                                       fifo_out_idx_d, fifo_out_idx_q;
    logic [AWTH-1:0]                            instr_pc_d, instr_pc_q;
    logic                                       reset_pc_d, reset_pc_q;
    logic [IWTH-1:0]                            instr_before_reply;
    logic [IWTH-1:0]                            instr_after_reply;
    logic                                       illegal_instr;
    logic                                       is_compressed;

//======================================================================================================================
// Instance
//======================================================================================================================

  assign ready_o = ~(|instr_queue_full);

  always_comb begin : gen_fifo_idx 
      fifo_in_idx_d = fifo_in_idx_q;
      // if fetching only one instruction, idx should change from 1 to 0 or 0 to 1
      if((!fet_valid_i[0] && fet_valid_i[1]) || (fet_valid_i[0] && !fet_valid_i[1])) begin
          fifo_in_idx_d = ~fifo_in_idx_q;
      end
  end

  //why duplicate instr? It's easier to exchange instr in different position
  for (genvar i=0; i< INSTR_PER_FETCH; i++) begin
    assign instr_data_double[i] = fet_instr_i[i];
    assign instr_data_double[i+INSTR_PER_FETCH] = fet_instr_i[i];
  end

  for (genvar i=0; i< INSTR_PER_FETCH; i++) begin
    assign instr_data_in[i].instr = instr_data_double[i+fifo_in_idx_q]; 
    assign instr_data_in[i].ex = fet_ex_i;
  end

  // when idx is 1, exchange instr push signal
  always_comb begin : gen_push
    push_instr = fet_valid_i;
    if(fifo_in_idx_q) begin
      push_instr[0] = fet_valid_i[1];
      push_instr[1] = fet_valid_i[0];
    end 
  end      

  // FIFOs
  // we generate two FIFO because it's possible to fetch two instrctions in one clock cycle 
  for (genvar i = 0; i < INSTR_PER_FETCH; i++) begin : gen_instr_fifo
    // Make sure we don't save any instructions if we couldn't save the address
    fifo_v3 #(
      .DEPTH      ( FETCH_FIFO_DEPTH ),
      .dtype      ( instr_data_t                 )
    ) i_fifo_instr_data (
      .clk_i      ( clk_i                ),
      .rst_ni     ( rst_ni               ),
      .flush_i    ( flush_i              ),
      .testmode_i ( 1'b0                 ),
      .full_o     ( instr_queue_full[i]  ),
      .empty_o    ( instr_queue_empty[i] ),
      .usage_o    (),
      .data_i     ( instr_data_in[i]     ),
      .push_i     ( push_instr[i]   ),
      .data_o     ( instr_data_out[i]    ),
      .pop_i      ( pop_instr[i]         )
    );
  end

  // generate output instr
  assign dec_valid_o = ~(&instr_queue_empty) && (!flush_i);
  always_comb begin : gen_ouput_data
    fifo_out_idx_d = fifo_out_idx_q;
    instr_before_reply = instr_data_out[fifo_out_idx_q].instr; 
    dec_pc_o = instr_pc_q; 
    dec_npc_o = instr_pc_q + (instr_before_reply[1:0] != 2'b11 ? 'd2 : 'd4); 
    dec_ex_o.valid = instr_data_out[fifo_out_idx_q].ex || (illegal_instr && is_compressed);
    dec_ex_o.cause = instr_data_out[fifo_out_idx_q].ex ? INSTR_PAGE_FAULT : ILLEGAL_INSTR;
    dec_ex_o.tval = instr_data_out[fifo_out_idx_q].ex ? instr_pc_q : {16'b0, instr_before_reply[15:0]};
    pop_instr = '0;
    if(dec_valid_o && dec_ready_i) begin
      fifo_out_idx_d = ~fifo_out_idx_q;
      pop_instr[fifo_out_idx_q] = 1'b1;
    end
  end

  // compressed instr to normal instr
  sy_ppl_compress_dec u_compressed_dec(
      .instr_i               (instr_before_reply) ,
      .instr_o               (instr_after_reply) ,
      .illegal_instr_o       (illegal_instr) ,
      .is_compressed_o       (is_compressed) 
  );
  assign dec_instr_o = is_compressed ? instr_after_reply : instr_before_reply;
  assign dec_is_compressed_o = is_compressed;
  // generate instr pc
  always_comb begin : gen_pc
    instr_pc_d = instr_pc_q; 
    reset_pc_d = flush_i ? 1'b1 : reset_pc_q;

    if(dec_valid_o && dec_ready_i) begin
      instr_pc_d = instr_pc_q + (is_compressed ? 'd2 : 'd4);
    end
    if(reset_pc_q && fet_valid_i[0]) begin
      reset_pc_d = 1'b0;
      instr_pc_d = fet_addr_i[0];
    end
  end


//======================================================================================================================
// Registers
//======================================================================================================================

  always_ff @(`DFF_CR(clk_i, rst_ni)) begin
    if(`DFF_IS_R(rst_ni)) begin
      fifo_in_idx_q <= 1'b0;
      fifo_out_idx_q <= 1'b0;
      instr_pc_q <= '0;
      reset_pc_q <= 1'b1;
    end else begin
      instr_pc_q <= instr_pc_d;
      if(flush_i) begin
        fifo_in_idx_q <= 1'b0;
        fifo_out_idx_q <= 1'b0;
        reset_pc_q <= 1'b1;
      end else begin
        fifo_in_idx_q <= fifo_in_idx_d;
        fifo_out_idx_q <= fifo_out_idx_d;
        reset_pc_q <= reset_pc_d;
      end
    end
  end

endmodule : sy_ppl_instr_buffer