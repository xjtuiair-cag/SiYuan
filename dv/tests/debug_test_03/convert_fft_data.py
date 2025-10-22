import sys

def convert_to_uint64_array(input_file, array_name):
    """将16进制字符串列表转为uint64_t数组"""
    with open(input_file, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    print(f"共读取 {len(lines)} 行数据。")

    print(f"uint64_t {array_name}[{len(lines)}] = {{")
    for i, line in enumerate(lines):
        # 清理前缀、空格等
        hexval = line.lower().replace("0x", "")
        if len(hexval) != 16:
            raise ValueError(f"第 {i+1} 行长度不是16位: {hexval}")
        print(f"    0x{hexval}ULL,", end='')
        if (i + 1) % 2 == 0:
            print()  # 每两行换行
        else:
            print(" ", end='')
    print("};")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python convert_fft_data.py <输入文件> <数组名>")
        sys.exit(1)
    convert_to_uint64_array(sys.argv[1], sys.argv[2])
