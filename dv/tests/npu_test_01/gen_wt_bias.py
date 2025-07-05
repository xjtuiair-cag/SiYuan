import numpy as np
import argparse

parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--input", type=str, default="total_weight.txt")  
parser.add_argument("--output", type=str, default="weight.dat")  


args = parser.parse_args()

data = []

with open(args.input, 'r') as infile:
    while 1:
        line = infile.readline()
        line_trans = ['0'] * 16
        if line:
            for i in range(8):
                line_trans[i*2] = line[14-i*2]
                line_trans[i*2+1] = line[15-i*2]
            # print(line_trans)
            data.append(line_trans)
        else: 
            break


with open('./output/' + args.output, 'wt') as outfile:
    for line in data:
        s = ''
        for i in range(16):
            s += line[i]
        s += '\n'
        outfile.write(s)

print("Transform is finished.")
