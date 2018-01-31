//
//  JPEGImage.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPEGImageInfo.h"

@interface JPEGImage : NSObject

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, assign) CGFloat scale;

+ (instancetype) imageWithPath:(NSString *) path;

- (void) analysis;

@end
