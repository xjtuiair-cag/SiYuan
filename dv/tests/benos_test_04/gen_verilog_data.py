import numpy as np
import argparse

parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--file", type=str, default="./mysbi.hex")
parser.add_argument("--offset", type=str, default="0x80000000")
parser.add_argument("--output", type=str, default="sbi.dat")
parser.add_argument("--length", type=int, default=1024*1024)  # total Byte length, default: 1MB

args = parser.parse_args()

data = ['00'] * args.length 
ddr = []
offset = int(args.offset[2:], 16)

with open(args.file, 'rt') as infile:
    for line in infile:
        # judge data type
        if line[0] == '@':
            addr_start = int(line[1:-1], 16) - offset
        else:
            Byte = line.split(' ')[:-1]
            Byte_num = len(Byte)
            for i in range(Byte_num):
                data[addr_start + i] = Byte[i]
            addr_start += Byte_num

if addr_start % 8 !=0:
    line_num = int(addr_start / 8 + 1)
else:
    line_num = int(addr_start / 8)

for i in range(line_num):
    B_64 = ''
    for j in range(8):
        inx = (i+1)*8 - j -1
        B_64 += data[inx]
    B_64 += '\n'
    ddr.append(B_64)

with open('./output/' + args.output, 'wt') as outfile:
    for line in ddr:
        outfile.write(line)

print("Transform is finished.")

