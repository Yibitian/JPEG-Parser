//
//  JPEGImageParser.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPEGImageInfo.h"

@interface JPEGImageParser : NSObject

- (instancetype)initWithData:(NSData *) data;
- (instancetype)initWithPath:(NSString *) path;

- (void) startParser;
- (void) carveChroma;

@property (nonatomic, readonly) JPEGImageInfo *hearInfo;
@property (nonatomic, readonly) JPEGImageChroma *chromasInfo;

@end
