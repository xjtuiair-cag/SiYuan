/* ISC License
 *
 * Copyright (C) 2016 Olof Kindgren <olof.kindgren@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

module wb_ram_generic
  #(parameter depth=256,
    parameter memfile = "")
  (input clk,
   input [3:0]	 we,
   input [31:0]  din,
   input [$clog2(depth)-1:0] 	 waddr,
   input [$clog2(depth)-1:0] 	 raddr,
   output reg [31:0] dout);

   reg [31:0] 	 mem [0:depth-1] /* verilator public */;

   always @(posedge clk) begin
      if (we[0]) mem[waddr][7:0]   <= din[7:0];
      if (we[1]) mem[waddr][15:8]  <= din[15:8];
      if (we[2]) mem[waddr][23:16] <= din[23:16];
      if (we[3]) mem[waddr][31:24] <= din[31:24];
      dout <= mem[raddr];
   end

   generate
      initial
	if(memfile != "") begin
	   $display("Preloading %m from %s", memfile);
	   $readmemh(memfile, mem);
	end
   endgenerate

endmodule
