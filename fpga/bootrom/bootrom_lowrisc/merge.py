#!/usr/bin/env python3
import argparse
import os
import struct

def read_bin(path):
    with open(path, "rb") as f:
        return f.read()

def main():
    parser = argparse.ArgumentParser(description="Merge two BINs into bootrom.sv")
    parser.add_argument("bin1", help="first BIN file")
    parser.add_argument("bin2", help="second BIN file")
    parser.add_argument("offset", type=lambda x: int(x, 0),
                        help="offset where second BIN is placed, e.g. 0x100")
    parser.add_argument("-o", "--output", default="bootrom.sv",
                        help="output SystemVerilog file name")
    args = parser.parse_args()

    # Read both binaries
    bin1 = read_bin(args.bin1)
    bin2 = read_bin(args.bin2)
    offset = args.offset

    # Build merged buffer
    merged = bytearray()
    merged.extend(bin1)

    # Padding 0 until offset
    if len(merged) < offset:
        merged.extend(b"\x00" * (offset - len(merged)))

    # Append second BIN
    merged.extend(bin2)

    # Pad to 8 bytes alignment
    if len(merged) % 8 != 0:
        pad_len = 8 - (len(merged) % 8)
        merged.extend(b"\x00" * pad_len)

    # Break into 64-bit words (little-endian)
    words = []
    for i in range(0, len(merged), 8):
        chunk = merged[i:i+8]
        val = struct.unpack("<Q", chunk)[0]   # little-endian 64-bit
        words.append(val)

    rom_size = len(words)

    # Generate SystemVerilog output
    with open(args.output, "w") as f:
        f.write("module bootrom_lowrisc (\n")
        f.write("   input  logic         clk_i,\n")
        f.write("   input  logic         req_i,\n")
        f.write("   input  logic [63:0]  addr_i,\n")
        f.write("   output logic [63:0]  rdata_o\n")
        f.write(");\n")
        f.write(f"    localparam int RomSize = {rom_size};\n\n")
        f.write("    const logic [RomSize-1:0][63:0] mem = {\n")

        # Write each 64-bit word
        for i, w in enumerate(reversed(words)):
            comma = "," if i != rom_size - 1 else ""
            f.write(f"        64'h{w:016x}{comma}\n")

        f.write("    };\n\n")
        f.write("    logic [$clog2(RomSize)-1:0] addr_q;\n\n")
        f.write("    always_ff @(posedge clk_i) begin\n")
        f.write("        if (req_i) begin\n")
        f.write("            addr_q <= addr_i[$clog2(RomSize)-1+3:3];\n")
        f.write("        end\n")
        f.write("    end\n\n")
        f.write("    assign rdata_o = (addr_q < RomSize) ? mem[addr_q] : '0;\n")
        f.write("endmodule\n")

    print(f"[OK] Generated {args.output}")
    print(f"RomSize = {rom_size} words (64-bit)")


if __name__ == "__main__":
    main()
