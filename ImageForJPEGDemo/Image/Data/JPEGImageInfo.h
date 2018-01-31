//
//  JPEGImageInfo.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPEGQuantizationTable.h"
#import "JPEGQuantizationIndex.h"
#import "JPEGHuffmanTable.h"
#import "JPEGHuffmanIndex.h"
#import "JPEGImageChroma.h"

@interface JPEGImageInfo : NSObject

@property (nonatomic, copy) NSString *fileType;
@property (nonatomic, copy) NSString *versions;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, readonly) NSArray<JPEGQuantizationIndex *> *quantizationIndexs;
- (void) creatQuantizationIndex:(void (^)(JPEGQuantizationIndex *index)) comp;

@property (nonatomic, readonly) NSDictionary<NSNumber * , JPEGQuantizationTable *> *quantizationTables;
- (void) creatQuantizationTable:(void (^)(JPEGQuantizationTable *table)) comp;

@property (nonatomic, assign) int restartMCU;

@property (nonatomic, readonly) NSArray<JPEGHuffmanIndex *> *huffmanIndexs;
- (void) creatHuffmanIndex:(void (^)(JPEGHuffmanIndex *index)) comp;

@property (nonatomic, readonly) NSDictionary<NSNumber * , JPEGHuffmanTable *> *huffmanTables;
- (void) creatHuffmanTable:(void (^)(JPEGHuffmanTable *table)) comp;

@end
