//
//  JPEGHuffmanTable.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/15.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGHuffmanTable.h"

@interface JPEGHuffmanTable ()

@property (nonatomic, strong) NSData *minItem;
@property (nonatomic, strong) NSData *maxItem;
@property (nonatomic, strong) NSData *codePos;

@end

@implementation JPEGHuffmanTable

- (uint8_t) countOfLen:(int) len
{
    uint8_t count = ((uint8_t *)self.codeLen.bytes)[len];
    return count;
}

- (uint8_t) valueOfIndex:(int) index
{
    uint8_t value = ((uint8_t *)self.codeValue.bytes)[index];
    return value;
}

- (void) initHuffmanTable
{
    uint16_t min_value = 0;
    uint16_t max_value = [self countOfLen:0];
    uint16_t code_pos = 0;
    
    NSMutableData *minData = [NSMutableData dataWithBytes:&min_value length:sizeof(min_value)];
    NSMutableData *maxData = [NSMutableData dataWithBytes:&max_value length:sizeof(max_value)];
    NSMutableData *posData = [NSMutableData dataWithBytes:&code_pos length:sizeof(code_pos)];
    
    uint16_t nextItem = 0;
    uint8_t len = 0;
    for (int i = 1; i < 16; i++)
    {
        len = [self countOfLen:i];
        if (len > 0)
        {
            min_value = nextItem;
            max_value = nextItem + len - 1;
            
            nextItem = max_value;
            nextItem = nextItem + 1;
        }
        nextItem = nextItem << 1;
        
        code_pos += len;
        
        [minData appendBytes:&min_value length:sizeof(min_value)];
        [maxData appendBytes:&max_value length:sizeof(max_value)];
        [posData appendBytes:&code_pos length:sizeof(code_pos)];
    }
    
    self.minItem = [NSData dataWithData:minData];
    self.maxItem = [NSData dataWithData:maxData];
    self.codePos = [NSData dataWithData:posData];
}

- (uint16_t) minItemOfIndex:(int) index
{
    uint16_t item = ((uint16_t *)self.minItem.bytes)[index];
    return item;
}

- (uint16_t) maxItemOfIndex:(int) index
{
    uint16_t item = ((uint16_t *)self.maxItem.bytes)[index];
    return item;
}

- (uint16_t) codePosOfIndex:(int) index
{
    uint16_t item = ((uint16_t *)self.codePos.bytes)[index];
    return item;
}

@end

int getHuffmanTableLengthFromData(NSData *data)
{
    int pa = 0;
    int count = 0;
    for (int i = 0; i < 16; i++)
    {
        uint8_t countInLine = 0;
        [data getBytes:&countInLine range:NSMakeRange(pa, sizeof(uint8_t))];
        count += countInLine;
        pa += sizeof(uint8_t);
    }
    return count;
}
