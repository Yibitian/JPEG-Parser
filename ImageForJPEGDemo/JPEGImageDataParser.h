//
//  JPEGImageDataParser.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 16/9/8.
//  Copyright © 2016年 B_Sui. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JPEGImageDataParserDelegate <NSObject>

- (void) imageMake:(UIImage *) image;

@end

@interface JPEGImageDataParser : NSObject

@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, weak) id<JPEGImageDataParserDelegate> delegate;

- (void) openFile:(NSString *) fileStr;

@end
