//
//  JPEGImageBitTool.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/17.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImageBitTool.h"

@interface JPEGImageBitTool ()
{
    int _bitPos;
    uint8_t _curByte;
}

@end

@implementation JPEGImageBitTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bitPos = 8;
    }
    return self;
}

#pragma mark - read

- (BOOL) isEnd
{
    return _bitPos <= 0;
}

- (void) setByte:(uint8_t)byte
{
    _byte = byte;
    _bitPos = 8;
    _curByte = byte;
}

- (void) spliceNextBitToByte:(uint16_t *) byte
{
    if (self.isEnd)
    {
        return;
    }
    
    int pos = _bitPos - 1;
    *byte = *byte << 1;
    *byte |= _curByte >> pos;
    _curByte &= 0xff >> (8 - pos);
    
    _bitPos = pos;
}

- (int) spliceBitToByte:(uint16_t *) byte withLenght:(int) lenght
{
    if (self.isEnd)
    {
        return 0;
    }
    
    int curBitPos = MIN(_bitPos, lenght);
    int pos = _bitPos - curBitPos;
    *byte = *byte << curBitPos;
    *byte |= _curByte >> pos;
    _curByte &= 0xff >> (8 - pos);
    
    _bitPos -= curBitPos;
    lenght -= curBitPos;
    
    return lenght;
}

#pragma mark - write

- (BOOL) isFull
{
    return _bitPos <= 0;
}

- (BOOL) isEmpty
{
    return _bitPos >= 8;
}

- (void) resetByte
{
    _byte = 0;
    _bitPos = 8;
    _curByte = 0;
}

- (void) condenseByte:(uint16_t) byte withLenght:(int) lenght callBack:(void (^)(uint8_t byte)) callBack
{
    for (int i = sizeof(byte); i > 0; i--)
    {
        uint8_t ui8 = byte >> (i - 1) * 8;
        int lenghtTmp = (lenght - (i - 1) * 8);
        
        uint8_t byteTmp = ui8 << (8 - lenghtTmp);
        while (lenghtTmp > 0)
        {
            int curBitPos = MIN(_bitPos, lenghtTmp);
            
            _curByte |= byteTmp >> (8 - _bitPos);
            byteTmp = byteTmp << curBitPos;
            
            lenght -= curBitPos;
            lenghtTmp -= curBitPos;
            _bitPos -= curBitPos;
            
            if (self.isFull)
            {
                if (callBack)
                {
                    callBack(_curByte);
                }
                [self resetByte];
            }
        }
    }
    
    _byte = _curByte;
}

@end
