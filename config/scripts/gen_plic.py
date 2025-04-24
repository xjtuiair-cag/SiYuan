import yaml
import argparse
import os

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file_path", help="config file path")
    args = parser.parse_args()

    file_path = args.file_path
    # Read YAML file
    with open(file_path, "r", encoding="utf-8") as file:
        cfg = yaml.safe_load(file)
    core_num = cfg["Core_num"]

    os.system("cd ../../de/ip/rv_plic/rtl && python gen_plic_addrmap.py -t {} > plic_regmap.sv".format(core_num*2))

