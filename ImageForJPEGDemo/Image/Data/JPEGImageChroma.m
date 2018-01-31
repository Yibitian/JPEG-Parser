//
//  JPEGImageChroma.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/16.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImageChroma.h"

@interface JPEGImageChroma ()

@property (nonatomic, strong) NSMutableArray<NSData *> *mcuData;

@end

@implementation JPEGImageChroma

#pragma mark - mcu data

- (NSMutableArray *) mcuData
{
    if (!_mcuData)
    {
        _mcuData = [NSMutableArray array];
    }
    return _mcuData;
}

@end
