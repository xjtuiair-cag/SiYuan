# How to Simulate

## 1. compile

1. ```cd dv/sim_cpu```

2. ```source setup_env.sh```

3. ```make cpu_sim```

## 2. single simulation
BOOTMODE=1

1. ```make run_gui TEST=core0_rv64uc-p-rvc```

BOOTMODE=0

2. ```make run_gui TEST=bootmode_test_01 BOOTMODE=0```

## 3. regression simulation

1. ```python run_regression all_test_list.txt```