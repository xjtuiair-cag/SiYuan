import sys
import os

def read_hex_file(filename):
    """读取每行8字节十六进制数据，返回bytes数组"""
    data = bytearray()
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # 每行16个hex字符 -> 8字节
            if len(line) != 16:
                raise ValueError(f"Invalid line length in {filename}: {line}")
            data.extend(bytes.fromhex(line))
    return data


def main(file1, file2, addr2_hex, outfile):
    addr2 = int(addr2_hex, 16)
    data1 = read_hex_file(file1)
    data2 = read_hex_file(file2)

    # 计算最终长度
    total_len = addr2 + len(data2)
    merged = bytearray(total_len)

    # 填充全0
    for i in range(total_len):
        merged[i] = 0

    # 拷贝第一个文件内容
    merged[0:len(data1)] = data1

    # 拷贝第二个文件内容（起始地址为 addr2）
    merged[addr2:addr2+len(data2)] = data2

    # 以16字节（即8字）为一行输出
    with open(outfile, "w") as f:
        for i in range(0, len(merged), 8):
            chunk = merged[i:i+8]
            f.write(chunk.hex().upper().zfill(16) + "\n")

    print(f"[OK] 合并完成，输出文件: {outfile}")
    print(f"文件总大小: {len(merged)} bytes")


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("用法: python merge_boot.py file1.txt file2.txt 0xADDR_OUT output.txt")
        print("例如: python merge_boot.py boot1.txt boot2.txt 0x1000 merged.txt")
        sys.exit(1)

    _, f1, f2, addr2, out = sys.argv
    main(f1, f2, addr2, out)
