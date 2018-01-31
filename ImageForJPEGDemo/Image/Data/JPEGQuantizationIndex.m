//
//  JPEGQuantizationIndex.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/16.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGQuantizationIndex.h"

@implementation JPEGQuantizationIndex

- (int) sampCount
{
    return self.sampLevel * self.sampVertical;
}

@end
