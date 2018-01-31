//
//  JPEGImage.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImage.h"
#import "JPEGImageInfo.h"
#import "JPEGImageParser.h"

@interface JPEGImage ()

@property (nonatomic, copy) NSString *path;

@property (nonatomic, strong) JPEGImageInfo *hearInfo;

@end

@implementation JPEGImage

+ (instancetype) imageWithPath:(NSString *) path
{
    JPEGImage *image = [[self alloc] init];
    image.path = path;
    return image;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (CGSize) size
{
    return CGSizeZero;
}

- (void) analysis
{
    JPEGImageParser *parser = [[JPEGImageParser alloc] initWithPath:self.path];
    [parser startParser];
    
    self.hearInfo = parser.hearInfo;
    
    CGSize sceenSize = [UIScreen mainScreen].bounds.size;
    if (self.hearInfo.size.width > sceenSize.width && self.hearInfo.size.height > sceenSize.height)
    {
        [parser carveChroma];
    }
}

- (UIImage *) imageWithRect:(CGRect) rect
{
    return nil;
}

@end
