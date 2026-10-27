module plic_regs #(
  parameter int SOURCE_NUM = 31,
  parameter int TARGET_NUM = 8,
  parameter int SOURCE_WTH = $clog2(SOURCE_NUM+1),
  parameter int TARGET_WTH = $clog2(TARGET_NUM)

)(
  input   logic [SOURCE_NUM:0][2:0]              prio_i,
  output  logic [SOURCE_NUM:0][2:0]              prio_o,
  output  logic [SOURCE_NUM:0]                   prio_we_o,

  input   logic [SOURCE_NUM:0]                   ip_i,

  input   logic [TARGET_NUM-1:0][SOURCE_NUM:0]   ie_i,
  output  logic [TARGET_NUM-1:0][SOURCE_NUM:0]   ie_o,
  output  logic [TARGET_NUM-1:0]                 ie_we_o,

  input   logic [TARGET_NUM-1:0][2:0]            threshold_i,
  output  logic [TARGET_NUM-1:0][2:0]            threshold_o,
  output  logic [TARGET_NUM-1:0]                 threshold_we_o,
  input   logic [TARGET_NUM-1:0][SOURCE_WTH-1:0] cc_i,
  output  logic [TARGET_NUM-1:0][SOURCE_WTH-1:0] cc_o,
  output  logic [TARGET_NUM-1:0]                 cc_we_o,
  output  logic [TARGET_NUM-1:0]                 cc_re_o,
  // Bus Interface
  input  sy_pkg::reg_intf_req_a32_d32            req_i,
  output sy_pkg::reg_intf_resp_d32               resp_o
);
//======================================================================================================================
// Parameters

localparam VALID_ADDR_BITS = 26;

localparam PRIO_LSB   = 2;
localparam PRIO_MSB   = SOURCE_WTH + PRIO_LSB;
localparam IP_LSB     = 2;
localparam IP_MSB     = IP_LSB + $clog2((SOURCE_NUM+1)/32);
localparam EN_BITS_TARGET_LSB   = 7;
localparam EN_BITS_TARGET_MSB   = EN_BITS_TARGET_LSB + TARGET_WTH;
localparam EN_BITS_SOURCE_LSB   = 2;
localparam EN_BITS_SOURCE_MSB   = EN_BITS_SOURCE_LSB + $clog2((SOURCE_NUM+1)/32);
localparam THRESH_TARGET_LSB    = 12;
localparam THRESH_TARGET_MSB    = THRESH_TARGET_LSB + TARGET_WTH;

localparam PRIO_BASE_ADDR     = 26'h0;
localparam PRIO_END_ADDR      = PRIO_BASE_ADDR + (SOURCE_NUM+1) * 4;
localparam IP_BASE_ADDR       = 26'h1000;
localparam IP_END_ADDR        = IP_BASE_ADDR + (SOURCE_NUM+1);
localparam EN_BITS_BASE_ADDR  = 26'h2000;
localparam EN_BITS_END_ADDR   = EN_BITS_BASE_ADDR + 32'h80*TARGET_NUM;
localparam THRESH_BASE_ADDR   = 26'h20_0000;
localparam THRESH_END_ADDR    = THRESH_BASE_ADDR + 32'h1000*TARGET_NUM;
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
logic [VALID_ADDR_BITS-1:0] req_addr;
logic [SOURCE_WTH-1:0] prio_addr;
logic [TARGET_WTH-1:0] en_bits_target_addr;
logic [$clog2((SOURCE_NUM+1)/32)-1:0] ip_addr;
logic [$clog2((SOURCE_NUM+1)/32)-1:0] en_bits_source_addr;
logic [TARGET_WTH-1:0] thresh_target_addr;
logic   prio_req;
logic   ip_req;
logic   en_bits_req;
logic   thresh_req;
logic   is_claim;
//======================================================================================================================
// Instance
//======================================================================================================================

assign req_addr     = req_i.addr[VALID_ADDR_BITS-1:0];
assign prio_req     = req_i.valid && (req_addr >= PRIO_BASE_ADDR) && (req_addr < PRIO_END_ADDR);
assign ip_req       = req_i.valid && (req_addr >= IP_BASE_ADDR)   && (req_addr < IP_END_ADDR);
assign en_bits_req  = req_i.valid && (req_addr >= EN_BITS_BASE_ADDR) && (req_addr < EN_BITS_END_ADDR);
assign thresh_req   = req_i.valid && (req_addr >= THRESH_BASE_ADDR) && (req_addr < THRESH_END_ADDR);

// priority write
assign prio_addr = req_i.addr[PRIO_MSB-1:PRIO_LSB];
always_comb begin
  prio_o = '0;
  prio_we_o = '0;
  if (prio_req && req_i.write) begin
    prio_o[prio_addr] = req_i.wdata[2:0];
    prio_we_o[prio_addr] = 1'b1;
  end
end

// interrupt enable bit write
assign en_bits_target_addr = req_i.addr[EN_BITS_TARGET_MSB-1:EN_BITS_TARGET_LSB];
assign en_bits_source_addr = req_i.addr[EN_BITS_SOURCE_MSB-1:EN_BITS_SOURCE_LSB];
always_comb begin
  ie_o = ie_i;
  ie_we_o = '0;
  if (en_bits_req && req_i.write) begin
    ie_we_o[en_bits_target_addr] = 1'b1;
    ie_o[en_bits_target_addr][{en_bits_source_addr,5'b0}+:32] = req_i.wdata[31:0];
  end
end

// Priority threshold 
assign thresh_target_addr = req_i.addr[THRESH_TARGET_MSB-1:THRESH_TARGET_LSB];
assign is_claim = req_i.addr[2];
always_comb begin
  threshold_o = '0; 
  threshold_we_o = '0;
  cc_o = '0;
  cc_we_o = '0;
  if (thresh_req && req_i.write) begin
    // write claim
    if (is_claim) begin
      cc_o[thresh_target_addr] = req_i.wdata[SOURCE_WTH-1:0]; 
      cc_we_o[thresh_target_addr] = 1'b1;
    end else begin
      threshold_o[thresh_target_addr] = req_i.wdata[2:0];
      threshold_we_o[thresh_target_addr] = 1'b1;
    end
  end
end

// read priority/interrupt pending/enable bits/priority threshold
assign ip_addr = req_i.addr[IP_MSB-1:IP_LSB];
always_comb begin
  resp_o.ready = 1'b1;
  resp_o.rdata = '0;
  resp_o.error = '0;
  cc_re_o = '0;
  if (prio_req && !req_i.write) begin
    resp_o.rdata[2:0] = prio_i[prio_addr];
  end else if (ip_req && !req_i.write) begin
    resp_o.rdata[31:0] = ip_i[{ip_addr,5'b0}+:32];
  end else if (en_bits_req && !req_i.write) begin
    resp_o.rdata[31:0] = ie_i[en_bits_target_addr][{en_bits_source_addr,5'b0}+:32];
  end else if (thresh_req && !req_i.write) begin
    if (is_claim) begin
      resp_o.rdata[SOURCE_WTH-1:0] = cc_i[thresh_target_addr];
      cc_re_o[thresh_target_addr] = 1'b1;
    end else begin
      resp_o.rdata[2:0] = threshold_i[thresh_target_addr];
    end
  end
end

endmodule