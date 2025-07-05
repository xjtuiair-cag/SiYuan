import numpy as np
import cv2
import argparse
 
parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--input", type=str, default="image.jpg")  
parser.add_argument("--output", type=str, default="ifm.dat")  

args = parser.parse_args()

img = cv2.imread(args.input)    # RGB
data = img.flatten()
cnt = 0
s = ''
with open('./output/' + args.output, "w") as outfile:
    for i in range(len(data)):
        s = format(data[i], '02X') + s
        cnt += 1
        if cnt % 8 == 0:
            s += '\n'
            outfile.write(s)
            s = ''
