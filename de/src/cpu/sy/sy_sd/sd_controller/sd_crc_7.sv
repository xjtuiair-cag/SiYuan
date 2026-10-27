module sd_crc_7
   import sy_pkg::*;
(
   input  logic       CLK,                            // Current bit valid (Clock)
   input  logic       RST,                            // Bit strobe (bit valid)

   input  logic       BITVAL,                            // Next input bit
   input  logic       ENABLE,                            // Enable calculation
   input  logic       CLEAR,                             // Init CRC value
   output logic [6:0] CRC                                // Current output CRC value
);

   logic         inv;
   
   assign inv = BITVAL ^ CRC[6];                   // XOR required?
   
   always @(`DFF_CR(CLK,RST)) begin
      if (`DFF_IS_R(RST)) begin
         CRC <= 0;                                  // Init before calculation
      end else begin
         if (CLEAR == 1) begin
            CRC <= 0;
         end else if (ENABLE == 1) begin
             CRC[6] <= CRC[5];
             CRC[5] <= CRC[4];
             CRC[4] <= CRC[3];
             CRC[3] <= CRC[2] ^ inv;
             CRC[2] <= CRC[1];
             CRC[1] <= CRC[0];
             CRC[0] <= inv;
         end
      end
   end
endmodule