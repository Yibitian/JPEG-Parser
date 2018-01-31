//
//  JPEGQuantizationTable.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/15.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGQuantizationTable : NSObject

@property (nonatomic, assign) int tag;
@property (nonatomic, assign) int bitSize;
@property (nonatomic, strong) NSData *data;

@end
