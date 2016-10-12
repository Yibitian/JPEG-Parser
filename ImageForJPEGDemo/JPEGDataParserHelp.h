//
//  JPEGDataParserHelp.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 16/9/12.
//  Copyright © 2016年 B_Sui. All rights reserved.
//

#ifndef JPEGDataParserHelp_h
#define JPEGDataParserHelp_h

#define MakeUint16(a)      ((uint16_t)(a >> 8 | a << 8))

#define M_SOI   0xd8
#define M_APP0  0xe0
#define M_DQT   0xdb
#define M_SOF0  0xc0
#define M_DHT   0xc4
#define M_DRI   0xdd
#define M_SOS   0xda
#define M_EOI   0xd9

#define W1 2841 /* 2048*sqrt(2)*cos(1*pi/16) */
#define W2 2676 /* 2048*sqrt(2)*cos(2*pi/16) */
#define W3 2408 /* 2048*sqrt(2)*cos(3*pi/16) */
#define W5 1609 /* 2048*sqrt(2)*cos(5*pi/16) */
#define W6 1108 /* 2048*sqrt(2)*cos(6*pi/16) */
#define W7 565  /* 2048*sqrt(2)*cos(7*pi/16) */

#define clipInNum(a,b) MAX(-b, MIN(a, b))

typedef enum
{
    JPEGColorSpace_gray         = 1,
    JPEGColorSpace_YCrCb_YIQ    = 3,
    JPEGColorSpace_CMYK         = 4
}JPEGColorSpace;

static int Zig_Zag[8][8]=
{
    {0, 1, 5, 6, 14,15,27,28},
    {2, 4, 7, 13,16,26,29,42},
    {3, 8, 12,17,25,30,41,43},
    {9, 11,18,24,37,40,44,53},
    {10,19,23,32,39,45,52,54},
    {20,22,33,38,46,51,55,60},
    {21,34,37,47,50,56,59,61},
    {35,36,48,49,57,58,62,63}
};

typedef struct JPEGColorComponents
{
    uint8_t index;
    uint8_t Dc_index;
    uint8_t Ac_index;
    uint8_t sampl_level;
    uint8_t sampl_vertical;
    uint16_t *qt_table;
}JPEGColorComponents;

typedef struct JPEGHuffmanTable
{
    uint8_t index;
    uint8_t code_len[16];
    uint8_t *value;
    
    uint16_t code_pos[16];
    uint16_t min_value[16];
    uint16_t max_value[16];
}JPEGHuffmanTable;

void idctrow(int *buffer)
{
    int x0, x1, x2, x3, x4, x5, x6, x7, x8;
    //intcut
    if (!((x1 = buffer[4] << 11) | (x2 = buffer[6]) | (x3 = buffer[2]) |
          (x4 = buffer[1]) | (x5 = buffer[7]) | (x6 = buffer[5]) | (x7 = buffer[3])))
    {
        buffer[0] = buffer[1] = buffer[2] = buffer[3] = buffer[4] = buffer[5] = buffer[6] = buffer[7] = buffer[0]<<3;
        return;
    }
    x0 = (buffer[0] << 11) + 128; // for proper rounding in the fourth stage
    //first stage
    x8 = W7 * (x4 + x5);
    x4 = x8 + (W1 - W7) * x4;
    x5 = x8 - (W1 + W7) * x5;
    x8 = W3 * (x6 + x7);
    x6 = x8 - (W3 - W5) * x6;
    x7 = x8 - (W3 + W5) * x7;
    //second stage
    x8 = x0 + x1;
    x0 -= x1;
    x1 = W6 * (x3 + x2);
    x2 = x1 - (W2 + W6) * x2;
    x3 = x1 + (W2 - W6) * x3;
    x1 = x4 + x6;
    x4 -= x6;
    x6 = x5 + x7;
    x5 -= x7;
    //third stage
    x7 = x8 + x3;
    x8 -= x3;
    x3 = x0 + x2;
    x0 -= x2;
    x2 = (181 * (x4 + x5) + 128) >> 8;
    x4 = (181 * (x4 - x5) + 128) >> 8;
    //fourth stage
    buffer[0] = (x7 + x1) >> 8;
    buffer[1] = (x3 + x2) >> 8;
    buffer[2] = (x0 + x4) >> 8;
    buffer[3] = (x8 + x6) >> 8;
    buffer[4] = (x8 - x6) >> 8;
    buffer[5] = (x0 - x4) >> 8;
    buffer[6] = (x3 - x2) >> 8;
    buffer[7] = (x7 - x1) >> 8;
}

void idctcol(int *buffer)
{
    int x0, x1, x2, x3, x4, x5, x6, x7, x8;
    //intcut
    if (!((x1 = (buffer[8*4]<<8)) | (x2 = buffer[8*6]) | (x3 = buffer[8*2]) |
          (x4 = buffer[8*1]) | (x5 = buffer[8*7]) | (x6 = buffer[8*5]) | (x7 = buffer[8*3])))
    {
        buffer[8 * 0] = buffer[8 * 1] = buffer[8 * 2] = buffer[8 * 3] = buffer[8 * 4] = buffer[8 * 5]
        = buffer[8 * 6] = buffer[8 * 7] = clipInNum((buffer[8 * 0] + 32) >> 6, 256);
        return;
    }
    x0 = (buffer[8*0]<<8) + 8192;
    //first stage
    x8 = W7*(x4+x5) + 4;
    x4 = (x8+(W1-W7)*x4)>>3;
    x5 = (x8-(W1+W7)*x5)>>3;
    x8 = W3*(x6+x7) + 4;
    x6 = (x8-(W3-W5)*x6)>>3;
    x7 = (x8-(W3+W5)*x7)>>3;
    //second stage
    x8 = x0 + x1;
    x0 -= x1;
    x1 = W6*(x3+x2) + 4;
    x2 = (x1-(W2+W6)*x2)>>3;
    x3 = (x1+(W2-W6)*x3)>>3;
    x1 = x4 + x6;
    x4 -= x6;
    x6 = x5 + x7;
    x5 -= x7;
    //third stage
    x7 = x8 + x3;
    x8 -= x3;
    x3 = x0 + x2;
    x0 -= x2;
    x2 = (181*(x4+x5)+128)>>8;
    x4 = (181*(x4-x5)+128)>>8;
    //fourth stage
    buffer[8*0] = clipInNum((x7+x1)>>14, 256);
    buffer[8*1] = clipInNum((x3+x2)>>14, 256);
    buffer[8*2] = clipInNum((x0+x4)>>14, 256);
    buffer[8*3] = clipInNum((x8+x6)>>14, 256);
    buffer[8*4] = clipInNum((x8-x6)>>14, 256);
    buffer[8*5] = clipInNum((x0-x4)>>14, 256);
    buffer[8*6] = clipInNum((x3-x2)>>14, 256);
    buffer[8*7] = clipInNum((x7-x1)>>14, 256);
}

#endif /* JPEGDataParserHelp_h */
