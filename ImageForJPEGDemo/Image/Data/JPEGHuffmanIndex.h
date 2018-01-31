//
//  JPEGHuffmanIndex.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/16.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGHuffmanIndex : NSObject

@property (nonatomic, assign) int tag;

@property (nonatomic, assign) int dcTag;
@property (nonatomic, assign) int acTag;

@end
