#! /usr/bin/python3
import os
import sys
import numpy as np
from optparse import OptionParser
import struct
import logging

# Parser input args
# usage = "Usage: %prog [iof] arg"
parser = OptionParser(version="%prog 0.1")
parser.add_option("-i", "--input", dest="pif", default="bbl.bin", help="Input directory and filename.")
                  
parser.add_option("-o", "--output", dest="pof", default="bbl.dat", help="Output directory and filename.")
parser.add_option("-l", "--length", dest="len", type="int", default="64", help="How many bytes per line.")
# parser.add_option("-t", "--byte_access", dest="byte_access", action="store_true",
#                   help="The output data is addressed in Byte.")
# parser.add_option("-b", "--bin", dest="bin", action="store_true",
#                   help="The output data is binary.")
(options, args) = parser.parse_args()

# read txt data and transform it to bin
with open(options.pif, "rb") as pif:
    with open(options.pof, "w") as pof:
        # line = pif.read(options.len)
        for line in pif:
            if line:
                for i in range(options.len):
                    # pof.write("%02x" % struct.unpack('B', line[0:2]))
                    pof.write("%02x" % line[options.len-1-i])
                pof.write("\n")
            else:
                break

# transform is finished
logging.info(options.pof + " is generated.")

