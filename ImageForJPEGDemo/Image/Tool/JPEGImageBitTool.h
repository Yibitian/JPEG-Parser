//
//  JPEGImageBitTool.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/17.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGImageBitTool : NSObject

@property (nonatomic, assign) uint8_t byte;

@property (nonatomic, readonly) BOOL isEnd;
- (void) spliceNextBitToByte:(uint16_t *) byte;
- (int) spliceBitToByte:(uint16_t *) byte withLenght:(int) lenght;


@property (nonatomic, readonly) BOOL isFull;
@property (nonatomic, readonly) BOOL isEmpty;
- (void) resetByte;
- (void) condenseByte:(uint16_t) byte withLenght:(int) lenght callBack:(void (^)(uint8_t byte)) callBack;

@end
