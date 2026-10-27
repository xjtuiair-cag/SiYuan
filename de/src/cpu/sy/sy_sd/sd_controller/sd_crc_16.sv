module sd_crc_16
   import sy_pkg::*;
(
   input  logic        CLK,
   input  logic        RST,

   input  logic        BITVAL,                            // Next input bit
   input  logic        ENABLE,                            // Enable calculation
   input  logic        CLEAR,                             // Init CRC value
   output logic [15:0] CRC                                // Current output CRC value
);

   logic         inv;
   
   assign inv = BITVAL ^ CRC[15];                   // XOR required?
   
   always @(`DFF_CR(CLK,RST)) begin
      if (`DFF_IS_R(RST)) begin
         CRC <= 0;                                  // Init before calculation
      end else begin
         if (CLEAR == 1) begin
            CRC <= 0;
         end else if (ENABLE == 1) begin
             CRC[15] <= CRC[14];
             CRC[14] <= CRC[13];
             CRC[13] <= CRC[12];
             CRC[12] <= CRC[11] ^ inv;
             CRC[11] <= CRC[10];
             CRC[10] <= CRC[9];
             CRC[9]  <= CRC[8];
             CRC[8]  <= CRC[7];
             CRC[7]  <= CRC[6];
             CRC[6]  <= CRC[5];
             CRC[5]  <= CRC[4] ^ inv;
             CRC[4]  <= CRC[3];
             CRC[3]  <= CRC[2];
             CRC[2]  <= CRC[1];
             CRC[1]  <= CRC[0];
             CRC[0]  <= inv;
         end
      end
   end
   
endmodule