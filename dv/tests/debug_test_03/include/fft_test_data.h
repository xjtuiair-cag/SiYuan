#include <stdint.h>

uint64_t fft_output[32];

uint64_t fft_input[32] = {
    0xbf81a4733efe5151ULL,     0x3ea0e507be0d9528ULL,
    0xbf6874443f25ceebULL,     0xbfb4c65e3fc2f2a4ULL,
    0x3fbb9a61be6fc5e7ULL,     0xbe6731e7be6fc199ULL,
    0x3d8a4c3a3fca23a5ULL,     0xbfb65e263f44769aULL,
    0xbf0b5cabbef05ef2ULL,     0x3de32b623f0ae537ULL,
    0xbf9353c2beed4515ULL,     0x3ec05b7ebeee7421ULL,
    0xbf19c3753e77c4f5ULL,     0xbe9558e2bff4e65eULL,
    0xbf1a0972bfdcca1cULL,     0x3fed1774bf0ff213ULL,
    0x000000003f800000ULL,     0xbec3ef163f6c835eULL,
    0xbf3504f33f3504f3ULL,     0xbf6c835e3ec3ef15ULL,
    0xbf800000b33bbd2eULL,     0xbf6c835ebec3ef18ULL,
    0xbf3504f3bf3504f3ULL,     0xbec3ef10bf6c8360ULL,
    0x33bbbd2ebf800000ULL,     0x3ec3ef15bf6c835eULL,
    0x3f3504f5bf3504f1ULL,     0x3f6c8361bec3ef0bULL,
    0x3f800000324cde2eULL,     0x3f6c835d3ec3ef1bULL,
    0x3f3504ef3f3504f7ULL,     0x3ec3ef153f6c835fULL,
};

uint64_t fft_ref_output[16] = {
    0xc07f2755bed06a25ULL,     0xc0917fd1c0184943ULL,
    0xc05d4391bf2c21cfULL,     0x3dab4120c008fe96ULL,
    0x409d028d3f0364e8ULL,     0x3f98658240340654ULL,
    0xc0c66e86bcd71180ULL,     0xc0888a9ac08a5ebbULL,
    0xc02560a73f0de5deULL,     0xc012390640d4421cULL,
    0xc0030483c015a8c4ULL,     0xc0f3a5f0408a9e15ULL,
    0xbf8d62c4bf0531e6ULL,     0x40b57e3240a20787ULL,
    0x40010e44404758c7ULL,     0x41004e06c0112032ULL,
};