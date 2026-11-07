#!/usr/bin/env python3
import random
import sys

def gen_random_data(length):
    """生成 length 个随机 uint8 数据"""
    return [random.randint(0, 255) for _ in range(length)]

def write_mem_file(filename, base_addr, data):
    """
    写出文件格式：
    @<base_addr>
    <16字节数据，空格分隔>
    """
    with open(filename, "w") as f:
        f.write(f"@{base_addr:08X}\n")
        for i in range(0, len(data), 16):
            line_data = data[i:i+16]
            f.write(" ".join(f"{x:02X}" for x in line_data) + "\n")

def main():
    if len(sys.argv) != 5:
        print("用法: python3 gen_mem_data.py <length> <addr1> <addr2> <basename>")
        print("示例: python3 gen_mem_data.py 64 0x80003000 0x90004000 data")
        sys.exit(1)

    length = int(sys.argv[1]) * 1024 # KB
    addr1 = int(sys.argv[2], 16)
    addr2 = int(sys.argv[3], 16)
    basename = sys.argv[4]

    # 生成随机数据
    data = gen_random_data(length)

    # 写两个文件，内容相同，仅起始地址不同
    file1 = f"{basename}_1.hex"
    file2 = f"{basename}_2.hex"

    write_mem_file(file1, addr1, data)
    write_mem_file(file2, addr2, data)

    print(f"✅ 已生成两个文件：")
    print(f"  {file1} (起始地址 {addr1:#010x})")
    print(f"  {file2} (起始地址 {addr2:#010x})")

if __name__ == "__main__":
    main()
