//
//  JPEGQuantizationIndex.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/16.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGQuantizationIndex : NSObject

@property (nonatomic, assign) int tag;

@property (nonatomic, assign) int sampVertical;
@property (nonatomic, assign) int sampLevel;

@property (nonatomic, readonly) int sampCount;

@property (nonatomic, assign) int qtTag;

@end
