#include <string.h>
#include <sys/types.h>
#include <stdint.h>
#include "uart.h"
#include "hid.h"
#include "mini-printf.h"
#include "ariane.h"
// #include "qspi.h"
#include "elfriscv.h"
// #include "eth.h"

// void gpio_leds(uint32_t arg)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   swp[0] = arg;
// }

// uint32_t gpio_sw(void)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   return swp[0];
// }

// uint32_t hwrnd(void)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   swp[2] = 0;
//   return swp[2];
// }

// uint32_t qspistatus(void)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   return swp[6]; // {spi_busy, spi_error}
// }

// uint64_t qspi_send(uint8_t len, uint8_t quad, uint16_t data_in_count, uint16_t data_out_count, uint32_t *data)
// {
//   uint32_t i, stat;
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   swp[5] = (quad<<31) | ((len&127) << 24) | ((data_out_count&4095) << 12) | (data_in_count&4095);
//   for (i = 0; i < len; i++)
//     swp[5] = data[i];
//   i = 0;
//   do
//     {
//       stat = swp[6];
//     }
//   while ((stat & 0x2) && (++i < 1000));
//   return swp[4];
// }

// void rtc_write(uint64_t secs, uint32_t usecs)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   swp[7] = (secs << 26) | (usecs & ((1 << 26) - 1));
// }

// uint64_t rtc_secs(void)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   return swp[7] >> 26;
// }

// uint32_t rtc_usecs(void)
// {
//   volatile uint64_t *swp = (volatile uint64_t *)GPIOBase;
//   return swp[7] & ((1 << 26) - 1);
// }

// uint8_t *const qspi_base = (void *)0x84000000;
// uint32_t qspi_len;

// uint32_t qspi_read4(uint8_t *dest, uint32_t start, uint32_t max)
//       {
//         uint32_t i = 0;
//         uint64_t rslt;
//         uint32_t j, data[2], blank = 0;
//         int data_in_count = 39;
//         int data_out_count = 65;
//         data[0] = CMD_4READ;
//         printf("dest=0x%x, start=0x%x, max=%d\n", dest, start, max);
//         do
//           {
//             data[1] = i + BITSIZE; // Should locate start of BBL
//             rslt = qspi_send(2, 0, data_in_count, data_out_count, data);
//             if ((rslt == 0xFFFFFFFFFFFFFFFF) && !max)
//               ++blank;
//             else
//               blank = 0;
//             for (j = 0; j < 8; j++)
//               {
//                 dest[i+j] = rslt >> (7-j)*8;
//               }
// #ifdef QSPI_VERBOSE
//             for (j = 0; j < 8; j++)
//               {
//                 puthex(dest[i+j], 2);
//                 printf(" ");
//               }
//             printf("\n");
// #endif                
//             i += 8;
//           }
//         while (((i < max) || !max) && (blank < 512));
//         if (!max) printf("Detected qspi becomes blank after %d bytes\n", i);
//         return i;
//       }

// void qspi_elfn(void *dst, uint32_t off, uint32_t sz)
// {
//   uint32_t i;
//   if (off >= qspi_len)
//     {
//       printf("elf read offset %x extended beyond end of QSPI %x\n", off, qspi_len);
//     }
//   memcpy(dst, qspi_base+off, sz);
// #ifdef QSPI_VERBOSE
// #else  
//   if (off < 0x1000) for (i = 0; i < sz; i += 16)
//       {
//         uint32_t j;
//         uint8_t *buf = i + (uint8_t *)dst;
//         puthex(off+i, 8);
//         printf(" ");
//         for (j = 0; j < 16; j++)
//           {
//             puthex(buf[j], 2);
//             printf(" ");
//           }
//         printf("\n");
//       }
// #endif
// }
  
// void qspi_main(int sw)
// {
//   int64_t entry;
//   // read elf
//   printf("load QSPI to DDR memory\n");
//   qspi_len = qspi_read4(qspi_base, BITSIZE, 0);
//   printf("load ELF to DDR memory\n");
//   entry = load_elf(qspi_elfn);
//   if (entry < 0)
//     {
//     printf("elf read failed with code %ld", -entry);
//     return;
//     }
//   just_jump(entry);
// }
int main()
{
  init_uart(UARTBase, 0x001B);
  print_uart(UARTBase, "Hello World!\r\n");
  sd_main(0);

  while (1)
    {
      // do nothing
    }
}

void handle_trap(void)
{
  print_uart(UARTBase, "trap\r\n");
}
