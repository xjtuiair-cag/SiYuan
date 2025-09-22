import numpy as np
import argparse

parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--length", type=int, default=1024)  
parser.add_argument("--output", type=str, default="ddr0.dat")  


args = parser.parse_args()
length = args.length 

data = np.random.randint(low=0, high=255, size=(length,4), dtype=int)
ddr_data = np.resize(data, (int(length/2),8))

test_data = []
ddr = []

for i in range(length):
    s = ''
    for j in range(4):
        s += format(data[i][j], "02X")
    s += "\n"
    test_data.append(s)

for i in range(int(length/2)):
    s = ''
    for j in range(8):
        s = format(ddr_data[i][j], "02X") + s
    s += "\n"
    ddr.append(s)

with open('./output/' + "test_data.dat", 'wt') as outfile:
    for line in test_data:
        outfile.write(line)
        
with open('./output/' + "ddr0.dat", 'wt') as outfile:
    for line in ddr:
        outfile.write(line)

print("Transform is finished.")
