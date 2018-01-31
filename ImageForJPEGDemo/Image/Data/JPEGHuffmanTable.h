//
//  JPEGHuffmanTable.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/15.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGHuffmanTable : NSObject

@property (nonatomic, assign) int tag;

@property (nonatomic, strong) NSData *codeLen;
@property (nonatomic, strong) NSData *codeValue;

- (uint8_t) countOfLen:(int) len;
- (uint8_t) valueOfIndex:(int) index;

@property (nonatomic, readonly) NSData *minItem;
@property (nonatomic, readonly) NSData *maxItem;
@property (nonatomic, readonly) NSData *codePos;

- (void) initHuffmanTable;

- (uint16_t) minItemOfIndex:(int) index;
- (uint16_t) maxItemOfIndex:(int) index;
- (uint16_t) codePosOfIndex:(int) index;

@end

int getHuffmanTableLengthFromData(NSData *data);
