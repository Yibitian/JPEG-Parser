//
//  JPEGImageChroma.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/16.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPEGImageChroma : NSObject

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, readonly) NSMutableArray<NSData *> *mcuData;

@end
