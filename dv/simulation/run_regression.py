#!/usr/bin/env python3
import subprocess
import sys
import os

def run_tests(test_list_file):
    # 结果输出文件
    result_file = "summary_result.txt"

    # 检查输入文件是否存在
    if not os.path.exists(test_list_file):
        print(f"错误：输入文件 {test_list_file} 不存在。")
        sys.exit(1)

    # 清空或创建结果文件
    with open(result_file, "w") as f:
        f.write("Test Summary\n")
        f.write("============\n")

    bootmode = 1
    # 逐行读取测试项
    with open(test_list_file, "r") as infile:
        for line in infile:
            test_name = line.strip()
            # 跳过空行或注释
            if not test_name or test_name.startswith("#"):
                continue
            if test_name.startswith("bootmode") :
                bootmode = 0
            else:
                bootmode = 1

            print(f"\n>>> 正在运行测试: {test_name}")

            # 执行命令 make run TEST={name}
            try:
                subprocess.run(
                    ["make", "run", f"TEST={test_name}", f"BOOTMODE={bootmode}"],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    check=False  # 不因失败中断整个流程
                )
            except Exception as e:
                print(f"执行测试 {test_name} 失败: {e}")
                result = "ERROR"
            else:
                # 读取 res.txt 文件内容
                res_path = os.path.join('./works/log/'+test_name, "res.txt")
                if os.path.exists(res_path):
                    with open(res_path, "r") as res_file:
                        res_content = res_file.read()
                        if "TEST PASS" in res_content:
                            result = "PASS"
                        elif "TEST FAIL" in res_content:
                            result = "FAIL"
                        else:
                            result = "UNKNOWN"
                else:
                    result = "NO_RES_FILE"

            # 写入结果文件
            with open(result_file, "a") as f:
                f.write(f"{test_name:30s} : {result}\n")

            print(f"结果: {result}")

    print(f"\n所有测试完成。结果已写入 {result_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python3 run_tests.py <test_list.txt>")
        sys.exit(1)

    run_tests(sys.argv[1])
