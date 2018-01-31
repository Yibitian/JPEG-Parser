//
//  JPEGDataTool.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGDataTool.h"
#include <bitstring.h>

@interface JPEGDataTool ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) NSUInteger scanLocation;

@end

@implementation JPEGDataTool

+ (instancetype) scannerWithData:(NSData *) data
{
    if (data == nil)
    {
        return nil;
    }
    id scanner = [[self alloc] initWithData:data];
    return scanner;
}

- (id) initWithData:(NSData *) data
{
    self = [super init];
    if (self)
    {
        self.data = data;
    }
    return self;
}

- (void) setScanLocation:(NSUInteger) value
{
    if(value > self.data.length)
        [NSException raise:NSRangeException format:@"*** -[JPEGDataScanner setScanLocation:]: Range or index out of bounds"];
    
    _scanLocation = value;
}

- (BOOL) isScanEnd
{
    return self.scanLocation >= self.data.length;
}

- (void) resetScanLocation
{
    _scanLocation = 0;
}

- (NSUInteger) length
{
    return self.data.length;
}

#pragma mark - buffer

- (BOOL) getBytes:(void *) buffer ofLength:(NSUInteger) length
{
    NSUInteger loc = [self scanLocation];
    if (loc + length > self.data.length)
        return NO;
    
    uint8_t *byte = buffer;
    if (buffer != NULL)
    {
        for (int i = 0; i < length; i++)
        {
            [[self data] getBytes:byte range:NSMakeRange(loc + i, 1)];
            byte ++;
        }
    }
    
    return YES;
}

- (BOOL) scanBytes:(void *) buffer ofLength:(NSUInteger) length
{
    NSUInteger loc = [self scanLocation];
    if (loc + length > self.data.length)
        return NO;
    
    uint8_t *byte = buffer;
    if (buffer != NULL)
    {
        for (int i = 0; i < length; i++)
        {
            [[self data] getBytes:byte range:NSMakeRange(loc + i, 1)];
            byte ++;
        }
    }
    
    [self setScanLocation:loc + length];
    return YES;
}

- (BOOL) scanData:(NSData **) data ofLength:(NSUInteger) length
{
    NSUInteger loc = [self scanLocation];
    if (loc + length > self.data.length)
        return NO;
    
    if (data != NULL)
        *data = [[self data] subdataWithRange:NSMakeRange(loc, length)];
    
    [self setScanLocation:loc + length];
    
    return YES;
}

- (BOOL)scanNullTerminatedString:(NSString **)value withEncoding:(NSStringEncoding)encoding
{
    NSData *terminator = [self terminatorDataForEncoding:encoding];
    
    NSRange termRange = [self.data rangeOfData:terminator options:0 range:NSMakeRange(_scanLocation, self.data.length - _scanLocation)];
    
    if(termRange.location != NSNotFound)
    {
        if(value != NULL)
        {
            NSData *subData = [self.data subdataWithRange:NSMakeRange(_scanLocation, termRange.location - _scanLocation)];
            *value = [[NSString alloc] initWithData:subData encoding:encoding];
        }
        
        _scanLocation = NSMaxRange(termRange);
        return YES;
    }
    
    return NO;
}

- (NSData *) terminatorDataForEncoding:(NSStringEncoding) encoding
{
    NSString *nullTerminatorString = [NSString stringWithCharacters:(unichar[]){ 0 } length:1];
    
    NSUInteger length = [nullTerminatorString lengthOfBytesUsingEncoding:encoding];
    
    static char nullBytes[20] = { 0 };
    
    return [NSData dataWithBytesNoCopy:nullBytes length:length freeWhenDone:NO];
}

@end

@implementation JPEGImageDataTool

- (uint8_t) extractByteWithBrockRSTn:(void (^)()) brockRSTn
                            brockEOI:(void (^)()) brockEOI
{
    uint8_t byte = 0;
    
    if (![self scanBytes:&byte ofLength:sizeof(byte)])
    {
        if (brockEOI)
        {
            brockEOI();
        }
        return 0;
    }
    
    while (byte == 0xff)
    {
        if (![self scanBytes:&byte ofLength:sizeof(byte)])
        {
            if (brockEOI)
            {
                brockEOI();
            }
            return 0;
        }
        
        if (byte == 0x00)
        {
            return 0xff;
        }
        else if (byte >= 0xd0 && byte <= 0xd7)
        {// RSTn 标示，重置所有参数
            if (brockRSTn)
            {
                brockRSTn();
            }
            [self scanBytes:&byte ofLength:sizeof(byte)];
            continue;
        }
        else if (byte == 0xd9)
        {// EOI 标示，结束Image
            if (brockEOI)
            {
                brockEOI();
            }
            return 0;
        }
        else if (byte == 0xff)
        {
            continue;
        }
    }
    
    return byte;
}

- (void) spliceByte:(uint8_t) byte
{
    if (!self.data || ![self.data isKindOfClass:[NSMutableData class]])
    {
        self.data = [NSMutableData data];
    }
    NSMutableData *data = (NSMutableData *) self.data;
    [data appendBytes:&byte length:sizeof(byte)];
    if (byte == 0xff)
    {
        byte = 0x00;
        [data appendBytes:&byte length:sizeof(byte)];
    }
}

@end
