import numpy as np
import struct
import os
import sys

# ================================================================
# 工具函数：FP32 编码转换
# ================================================================
def float_to_hex32(value):
    """将 FP32 浮点数转换为 8 位十六进制字符串"""
    return format(struct.unpack('>I', struct.pack('>f', np.float32(value)))[0], '08x')

def complex_to_hex32_imag_first(c):
    """复数转十六进制字符串（虚部在前，实部在后）"""
    imag_hex = float_to_hex32(np.imag(c))
    real_hex = float_to_hex32(np.real(c))
    return imag_hex + real_hex

# ================================================================
# 文件保存函数
# ================================================================
def save_complex_array_to_hexfile(arr, filename):
    """将复数数组保存为十六进制文本文件（虚部在前）"""
    with open(filename, 'w') as f:
        for c in arr:
            f.write(complex_to_hex32_imag_first(c) + '\n')

def save_complex_array_to_decfile(arr, filename):
    """将复数数组保存为十进制（虚部 实部）"""
    with open(filename, 'w') as f:
        for c in arr:
            f.write(f"{np.imag(c):.7f} {np.real(c):.7f}\n")

def save_weights(weights, basename):
    """保存旋转因子为十六进制和十进制（虚部在前）"""
    with open(basename + "_hex.txt", 'w') as fh, open(basename + "_dec.txt", 'w') as fd:
        for w in weights:
            fh.write(complex_to_hex32_imag_first(w) + '\n')
            fd.write(f"{np.imag(w):.7f} {np.real(w):.7f}\n")

# ================================================================
# FFT 蝶形运算
# ================================================================
def fft_stage(data, stage, N, weights):
    """执行第 stage 级蝶形运算（FP32）"""
    step = 2 ** (stage + 1)
    half_step = step // 2
    result = np.copy(data).astype(np.complex64)

    for k in range(0, N, step):
        for n in range(half_step):
            w_index = n * N // step
            twiddle = weights[w_index]
            a = result[k + n]
            b = np.complex64(result[k + n + half_step] * twiddle)
            result[k + n] = np.complex64(a + b)
            result[k + n + half_step] = np.complex64(a - b)
    return result

def fft_iterative(data, weights):
    """迭代式基-2 FFT蝶形算法（逐级输出）"""
    N = len(data)
    stages = int(np.log2(N))

    # 位反转置换
    indices = np.arange(N)
    rev = np.array([int('{:0{w}b}'.format(i, w=stages)[::-1], 2) for i in indices])
    data = data[rev]

    results_per_stage = []
    result = np.copy(data).astype(np.complex64)
    for s in range(stages):
        result = fft_stage(result, s, N, weights)
        results_per_stage.append(np.copy(result))
    return results_per_stage

def generate_twiddle_factors(N):
    """生成 N 点 FFT 的旋转因子表（顺序存储）"""
    k = np.arange(N, dtype=np.float32)
    W_N = np.exp(-2j * np.pi * k / N).astype(np.complex64)
    return W_N

# ================================================================
# 主程序入口
# ================================================================
def main():
    if len(sys.argv) != 2:
        print("用法: python fft_sim_fp32_imagfirst.py <FFT点数>")
        sys.exit(1)

    N = int(sys.argv[1])
    if N & (N - 1) != 0:
        raise ValueError("FFT点数必须是 2 的幂次方")

    np.random.seed(42)

    # 生成随机复数输入数据（FP32）
    data = (np.random.randn(N).astype(np.float32) +
            1j * np.random.randn(N).astype(np.float32)).astype(np.complex64)

    # 生成权重（FP32）
    weights = generate_twiddle_factors(N)

    os.makedirs("fft_output", exist_ok=True)

    # 保存输入数据
    save_complex_array_to_hexfile(data, "fft_output/input_stage0_hex.txt")
    save_complex_array_to_decfile(data, "fft_output/input_stage0_dec.txt")

    # 保存旋转因子
    save_weights(weights, "fft_output/weights")

    # 执行 FFT 逐级蝶形计算
    results = fft_iterative(data, weights)

    # 保存每级输出（十六进制 + 十进制）
    for i, stage_out in enumerate(results):
        save_complex_array_to_hexfile(stage_out, f"fft_output/output_stage{i+1}_hex.txt")
        save_complex_array_to_decfile(stage_out, f"fft_output/output_stage{i+1}_dec.txt")

    save_complex_array_to_hexfile(results[-1], "fft_output/output.txt")

    print(f"✅ FFT仿真完成，共 {len(results)} 级。")
    print(f"📁 所有输出已保存到 ./fft_output/ （虚部在左，实部在右）")

if __name__ == "__main__":
    main()
