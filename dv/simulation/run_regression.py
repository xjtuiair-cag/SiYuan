import numpy as np
import os
import argparse

parser = argparse.ArgumentParser(description='manual to this script')
parser.add_argument("--path", type=str, default="/tests/riscv_test_list")
parser.add_argument("--env", type=str, default="p")
parser.add_argument("--test", type=str, default="rv64ui")


args = parser.parse_args()

root_path = os.getenv('DV_HOME')
file_list_path = root_path + args.path + '/' + args.test + '.txt'
file_list = []
result_path = 'works/' + args.test + '-' + args.env + '-' + 'res' +'.txt'

with open(file_list_path,'r') as f:
    file_list = f.readlines()

with open(result_path,'w') as f:
    for test in file_list:
        test = test.replace('\n','')
        command = "make run_riscv_test TEST=" + test
        os.system(command)
        res_path = root_path + '/' + 'simulation/works/log' + '/'+ test + '/' + 'res.txt' 
        with open(res_path,'r') as f_res: 
            res = f_res.readline()
        res = test.ljust(20, ' ') + res + '\n'
        f.write(res)

