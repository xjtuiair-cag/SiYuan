import numpy as np
import argparse

parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--length", type=int, default=1024)  
parser.add_argument("--output", type=str, default="ddr0.dat")  


args = parser.parse_args()
length = args.length 

data = np.random.randint(low=0, high=15, size=(length,16), dtype=int)

ddr = []

for i in range(length):
    s = ''
    for j in range(16):
        s += hex(data[i][j])[-1]
    s += "\n"
    ddr.append(s)


with open('./output/' + args.output, 'wt') as outfile:
    for line in ddr:
        outfile.write(line)

print("Transform is finished.")
