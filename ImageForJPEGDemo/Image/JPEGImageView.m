//
//  JPEGImageView.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImageView.h"

@implementation JPEGImageView

- (void) setImage:(JPEGImage *)image
{
    _image = image;
    [self redrawImage];
}

- (void) redrawImage
{
    [self.image analysis];
//    CGContextRef ctx = [self createBitmapContextWithWidth:self.image.size.width pixelsHigh:self.image.size.height];
//    [self decodeToContext:ctx];
//    CGContextRelease(ctx);
}

- (void) decodeToContext:(CGContextRef) ctx
{
    
//    while ((isSucceed = [self decodeMCBToTable:mcbTable
//                                 withIsRestart:isRestart
//                                 withYLastItem:&yLastItem
//                                 withULastItem:&uLastItem
//                                 withVLastItem:&vLastItem]))
//    {
//        interval++;
//        isRestart = (_restartMCU && interval % _restartMCU == 0);
//        
//        [self transitionQtToZz:qtzzTable withMCUTable:mcbTable];
//        [self getYUV:y :u :v withQtZzTable:qtzzTable];
//        [self getRGB:r :g :b
//             withYUV:y :u :v];
//        [self makeImageToCtx:ctx withR:r withG:g withB:b withPtX:ptX withPtY:ptY];
//        
//        ptX += _Y_qtTable.sampl_level * 8;
//        if (ptX >= self.imageSize.width)
//        {
//            ptX = 0;
//            ptY += _Y_qtTable.sampl_vertical * 8;
//        }
//        
//        if ((ptX == 0) && (ptY >= self.imageSize.height))
//            break;
//    }
    
//    int16_t mcbTable[10][64];
//    int16_t qtzzTable[10][64];
//    
//    for (NSData *data in self.image.info.mcuData)
//    {
//        [self decodeData:data MCBToTable:mcbTable];
//    }
//    
//    NSLog(@"Succeed");
//    CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
//    UIImage *image = [UIImage imageWithCGImage:imgRef];
//    self.layer.contents = (__bridge id _Nullable)(image.CGImage);
}

- (void) decodeData:(NSData *) data MCBToTable:(int16_t[10][64]) mcbTable
{
    
}

- (CGContextRef) createBitmapContextWithWidth:(int) pixelsWide pixelsHigh:(int) pixelsHigh
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow       = (pixelsWide * 4);
    colorSpace              = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst;
    
    UInt32 *pixels;
    pixels = (UInt32 *) calloc(pixelsHigh * pixelsWide, sizeof(UInt32));
    context                 = CGBitmapContextCreate (pixels, pixelsWide, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, bitmapInfo);
    
    if (context== NULL)
    {
        fprintf (stderr, "Context not created!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    CGContextConcatCTM(context, CGAffineTransformMake(1.0,0.0,0.0,-1.0,0.0,pixelsHigh));
    CGColorSpaceRelease(colorSpace);
    return context;
}

@end
