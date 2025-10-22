import numpy as np

code_data = []
dtype = 'unknown'

with open('./output/swf_code.hex', 'rt') as infile:
    for line in infile:
        # judge data type
        if line[0] == '@':
            addr = int(line[1 : ], 16)
            if addr >= 0xc0000000 and addr < 0x100000000:
                dtype = 'code_data'
                tmp = ("%08x\n") % (addr - 0xc0000000)
                code_data.append('@' + tmp)
            else:
                dtype = 'unknown'

        else:
            if dtype == 'code_data':
                code_data.append(line)

with open('./output/code_data.dat', 'wt') as outfile:
    for line in code_data:
        outfile.write(line)

print("Transform is finished.")

