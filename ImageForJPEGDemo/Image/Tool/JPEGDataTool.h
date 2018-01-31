//
//  JPEGDataTool.h
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPEGDataTool : NSObject

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSUInteger scanLocation;
@property (nonatomic, readonly) NSUInteger length;

+ (instancetype) scannerWithData:(NSData *) data;
- (id) initWithData:(NSData *) data;

- (BOOL) isScanEnd;
- (void) resetScanLocation;

- (BOOL) getBytes:(void *) buffer ofLength:(NSUInteger) length;

- (BOOL) scanBytes:(void *) buffer ofLength:(NSUInteger) length;
- (BOOL) scanData:(NSData **) data ofLength:(NSUInteger) length;
- (BOOL) scanNullTerminatedString:(NSString **)value withEncoding:(NSStringEncoding)encoding;

@end

@interface JPEGImageDataTool : JPEGDataTool

- (uint8_t) extractByteWithBrockRSTn:(void (^)()) brockRSTn
                            brockEOI:(void (^)()) brockEOI;

- (void) spliceByte:(uint8_t) byte;

@end
