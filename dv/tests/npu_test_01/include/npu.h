#ifndef	_NPU_H
#define	_NPU_H


typedef signed char             int8_t;   
typedef short int               int16_t;  
typedef int                     int32_t;  
  
typedef unsigned char           uint8_t;  
typedef unsigned short int      uint16_t;  
typedef unsigned int            uint32_t;  
typedef unsigned long int       uint64_t; 

typedef unsigned long int	    uintptr_t;
 

#define NPU_BASE 0x2000

#define NPU_VERSION     NPU_BASE + 0
#define NPU_DATE        NPU_BASE + 16 
#define NPU_CTRL        NPU_BASE + 32 
#define NPU_BASE_ADDR   NPU_BASE + 48
#define NPU_REG01       NPU_BASE + 64 
#define NPU_DONE        NPU_BASE + 80
#define NPU_REG03       NPU_BASE + 96
#define NPU_REG04       NPU_BASE + 112
#define NPU_REG05       NPU_BASE + 128

#define START_OFFSET             0x0   
#define FETCH_EN_OFFSET          0x3   

int init_npu();
int start_npu();
int start_conv();
int wait_npu_done();

#endif  