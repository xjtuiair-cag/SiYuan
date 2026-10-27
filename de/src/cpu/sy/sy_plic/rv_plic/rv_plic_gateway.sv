// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// RISC-V Platform-Level Interrupt Gateways module

module rv_plic_gateway #(
  parameter int N_SOURCE = 32
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,

  input  logic[N_SOURCE-1:0]   src,
  input  logic[N_SOURCE-1:0]   le,      // Level0 Edge1

  input  logic[N_SOURCE-1:0]   claim, // $onehot0(claim)
  input  logic[N_SOURCE-1:0]   complete, // $onehot0(complete)

  output logic[N_SOURCE-1:0]   ip
);

logic [N_SOURCE-1:0] ia;    // Interrupt Active

logic [N_SOURCE-1:0] set;   // Set: (le) ? src & ~src_d : src ;
logic [N_SOURCE-1:0] src_d;

always_ff @(posedge clk_i, negedge rst_ni) begin
  if (!rst_ni) begin
    src_d <= '0;
  end else begin
    src_d <= src;
  end
end

always_comb begin
  for (int i = 0 ; i < N_SOURCE; i++) begin
    set[i] = (le[i]) ? src[i] & ~src_d[i] : src[i] ;
  end
end

// Interrupt pending is set by source (depends on le), cleared by claim.
// Until interrupt is claimed, set doesn't affect ip.
// RISC-V PLIC spec mentioned it can have counter for edge triggered
// But skipped the feature as counter consumes substantial logic size.
always_ff @(posedge clk_i, negedge rst_ni) begin
  if (!rst_ni) begin
    ip <= '0;
  end else begin
    ip <= (ip | (set & ~ia & ~ip)) & (~claim);
  end
end

// Interrupt active is to control ip. If ip is set then until completed
// by target, ip shouldn't be set by source even claim can clear ip.
always_ff @(posedge clk_i, negedge rst_ni) begin
  if (!rst_ni) begin
    ia <= '0;
  end else begin
    ia <= (ia | (set & ~ia)) & (~complete);
  end
end

endmodule
