import os

def print_hex(bytes):
  l = [hex(int(i)).replace('0x', '').zfill(2) for i in bytes]
  return " ".join(l)

with open("./output/bbl.dat","w") as pof:
    with open("./bbl.bin", "rb") as pif:
        l1 = []
        for line in pif:
            l1.extend(print_hex(line).split(' '))
        frame = len(l1) // 8
        for i in range(frame):
            one_frame = l1[i*8:8+i*8]
            s = ""
            for byte in one_frame[::-1]:
                s += byte
            s += "\n"
            # print(s)
            pof.write(s)
        # addtional bytes
        if len(l1) % 8 != 0:
            left_byte_num = 8 - len(l1) % 8
            s = ""
            for i in range(left_byte_num):
                s += "00"
            left_frame = l1[frame*8 : len(l1)]
            for byte in left_frame[::-1]:
                s += byte
            s += "\n"
            # print(s)
            pof.write(s)

