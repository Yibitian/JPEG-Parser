//
//  JPEGImageDataParser.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 16/9/8.
//  Copyright © 2016年 B_Sui. All rights reserved.
//

#import "JPEGImageDataParser.h"
#import "JPEGDataParserHelp.h"

uint8_t And[9] = {0,1,3,7,0xf,0x1f,0x3f,0x7f,0xff};

@interface JPEGImageDataParser ()
{
    NSUInteger _location;
    
    uint16_t _qtTable[3][64];
    
    JPEGColorComponents _Y_qtTable;
    JPEGColorComponents _U_qtTable;
    JPEGColorComponents _V_qtTable;
    
    JPEGHuffmanTable _huffmanTable[4];
    
    uint16_t _restartMCU; // 没收集n个量化表后，直流分量重置。
    
    uint8_t *_lp;
    int _lpIndex;
    int _bitPos;
    uint8_t _curByte;
}

@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *versions;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) JPEGColorSpace colorSpace;

@end

@implementation JPEGImageDataParser

- (id) init
{
    self = [super init];
    if (self)
    {
        _location = 0;
        [self initParameter];
    }
    return self;
}

- (void) initParameter
{
    uint16_t *a = *_qtTable;
    for (int i = 0; i < 3 * 64; i++)
    {
        *a = 0;
        a++;
    }
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

- (void) openFile:(NSString *) fileStr
{
    NSData *data = [NSMutableData dataWithContentsOfFile:fileStr];
    if (data == nil || data.length <= 0)
    {
        return;
    }
    
    self.imageData = data;
    [self parserTheData];
}

- (void) parserTheData
{
    BOOL isFinish = NO;
    NSUInteger locationLP = 0;
    
    while (!isFinish || locationLP >= self.imageData.length)
    {
        uint16_t bt16 = 0;
        [self.imageData getBytes:&bt16 range:NSMakeRange(locationLP, sizeof(uint16_t))];
        uint8_t bt = 0;
        [self.imageData getBytes:&bt range:NSMakeRange(locationLP, sizeof(uint8_t))];
        if (bt == 0xff)
        {
            locationLP += sizeof(uint8_t);
            [self.imageData getBytes:&bt range:NSMakeRange(locationLP, sizeof(uint8_t))];
            locationLP += sizeof(uint8_t);
            [self parserTableHeadWithMark:bt offset:&locationLP];
        }
        else
        {
            isFinish = YES;
        }
    }
    
    NSData *data = [self.imageData subdataWithRange:NSMakeRange(locationLP, self.imageData.length - locationLP - 2)];
    
    CGContextRef ctx = [self createBitmapContextWithWidth:self.imageSize.width pixelsHigh:self.imageSize.height];
    [self  decodeWithData:data toContext:ctx];
    CGContextRelease(ctx);
}

- (void) parserTableHeadWithMark:(uint8_t) mark offset:(NSUInteger *) offset
{
    if (mark == M_SOI || mark == M_EOI)
    {
        return;
    }
    uint16_t dataLength = 0;
    [self.imageData getBytes:&dataLength range:NSMakeRange(*offset, sizeof(uint16_t))];
    dataLength = MakeUint16(dataLength);
    NSData *data = [self.imageData subdataWithRange:NSMakeRange(*offset, dataLength)];
    switch (mark)
    {
        case M_APP0:
        {
            [self parserAPP0WithData:data];
        }
            break;
        case M_DQT:
        {
            [self parserDQTWithData:data];
        }
            break;
        case M_SOF0:
        {
            [self parserSOF0WithData:data];
        }
            break;
        case M_DHT:
        {
            [self parserDHTWithData:data];
        }
            break;
        case M_DRI:
        {
            [self parserDRIWithData:data];
        }
            break;
        case M_SOS:
        {
            [self parserSOSWithData:data];
        }
            break;
        default:
            break;
    }
    *offset += dataLength;
}

- (void) parserAPP0WithData:(NSData *) data
{
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
    
    if (length - pa > 0)
    {// 标识符 固定值0x4A46494600，即字符串“JFIF0”
        uint8_t identifier[5] = {0};
        [data getBytes:identifier range:NSMakeRange(pa, sizeof(uint8_t) * 5)];
        self.fileType = [NSString stringWithFormat:@"%s", (char *)identifier];
        pa += sizeof(uint8_t) * 5;
    }
    
    if (length - pa > 0)
    {// 版本号 一般是0x0102，表示JFIF的版本号1.2
        uint16_t versions = 0;
        [data getBytes:&versions range:NSMakeRange(pa, sizeof(uint16_t))];
        self.versions = [NSString stringWithFormat:@"%d.%d",  (uint8_t)(versions >> 8), (uint8_t)versions];
        pa += sizeof(uint16_t);
    }
    
//    if (length - pa > 0)
//    {// X和Y的密度单位 => 0：无单位；1：点数/英寸；2：点数/厘米
//        uint8_t unit = 0;
//        [data getBytes:&unit range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//    }
//    
//    if (length - pa > 0)
//    {// X方向像素密度
//        uint16_t x_density = 0;
//        [data getBytes:&x_density range:NSMakeRange(pa, sizeof(uint16_t))];
//        x_density = MakeUint16(x_density);
//        pa += sizeof(uint16_t);
//    }
//    
//    if (length - pa > 0)
//    {// Y方向像素密度
//        uint16_t y_density = 0;
//        [data getBytes:&y_density range:NSMakeRange(pa, sizeof(uint16_t))];
//        y_density = MakeUint16(y_density);
//        pa += sizeof(uint16_t);
//    }
//    
//    if (length - pa > 0)
//    {// 缩略图水平像素数目
//        uint8_t x_pixelsCount = 0;
//        [data getBytes:&x_pixelsCount range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//    }
//    
//    if (length - pa > 0)
//    {// 缩略图垂直像素数目
//        uint8_t y_pixelsCount = 0;
//        [data getBytes:&y_pixelsCount range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//    }
//    
//    if (length - pa > 0)
//    {// 缩略图RGB位图
//        NSMutableArray *arr = [NSMutableArray array];
//        for (int i = 0; i < length; i++)
//        {
//            uint8_t rgb = 0;
//            [data getBytes:&rgb range:NSMakeRange(pa, sizeof(uint8_t))];
//            [arr addObject:@(rgb)];
//            pa += sizeof(uint8_t);
//        }
//    }
}

//- (void) parserAllAPPnWithData:(NSData *) data
//{// Application，应用程序保留标记n，其中n=1～15(任选)
//    NSUInteger pa = 0;
//    // 数据长度
//    uint16_t length = data.length;
//    pa += sizeof(uint16_t);
//}

- (void) parserDQTWithData:(NSData *) data
{// Define Quantization Table 定义量化表
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
    
    //  精度及量化表ID   1字节 高4位：精度，只有两个可选值 0：8位；1：16位。低4位：量化表ID，取值范围为0～3
    while (length - pa > 0)
    {
        uint8_t precision = 0;
        [data getBytes:&precision range:NSMakeRange(pa, sizeof(uint8_t))];
        int tableID = precision & 0x0f;
        pa += sizeof(uint8_t);
        
        // 量化表是个 8 * 8 的二维表
        int bit = precision & 0xf0 ? sizeof(uint16_t) : sizeof(uint8_t);
        int parameterLength = 64 * bit;
        for (int i = 0; i < 64; i++)
        {
            uint16_t parameterItem = 0;
            [data getBytes:&parameterItem range:NSMakeRange(pa + i * bit, bit)];
            _qtTable[tableID][i] = parameterItem;
        }
        
        pa += parameterLength;
    }
}

- (void) parserSOF0WithData:(NSData *) data
{// Start of Frame，帧图像开始
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
        
    if (length - pa > 0)
    {//  精度及量化表ID   1字节 高4位：精度，只有两个可选值 0：8位；1：16位。低4位：量化表ID，取值范围为0～3
//        uint8_t precision = 0;
//        [data getBytes:&precision range:NSMakeRange(pa, sizeof(uint8_t))];
        pa += sizeof(uint8_t);
    }
    
    uint16_t imageHeight = 0;
    uint16_t imageWidth = 0;
    if (length - pa > 0)
    {
        // 图像高度
        [data getBytes:&imageHeight range:NSMakeRange(pa, sizeof(uint16_t))];
        imageHeight = MakeUint16(imageHeight);
        pa += sizeof(uint16_t);
        
        // 图像宽度
        [data getBytes:&imageWidth range:NSMakeRange(pa, sizeof(uint16_t))];
        imageWidth = MakeUint16(imageWidth);
        pa += sizeof(uint16_t);
    }
    self.imageSize = CGSizeMake(imageWidth, imageHeight);
    
    uint8_t colorComponentsCount = 0;
    if (length - pa > 0)
    {// 颜色分量数 1：灰度图；3：YCrCb或YIQ；4：CMYK (而JFIF中使用YCrCb，故这里颜色分量数恒为3)
        [data getBytes:&colorComponentsCount range:NSMakeRange(pa, sizeof(uint8_t))];
        self.colorSpace = colorComponentsCount;
        pa += sizeof(uint8_t);
    }
    
    // 颜色分量信息
    
    if (colorComponentsCount == 1)
    {// 灰度图
        // 颜色分量ID
        uint8_t ccID = 0;
        [data getBytes:&ccID range:NSMakeRange(pa, sizeof(uint8_t))];
        _Y_qtTable.index = ccID;
        _U_qtTable.index = ccID;
        _V_qtTable.index = ccID;
        pa += sizeof(uint8_t);
        
        // 水平/垂直采样因子 高4位：水平采样因子；低4位：垂直采样因子。
        uint8_t samplingFactors = 0;
        [data getBytes:&samplingFactors range:NSMakeRange(pa, sizeof(uint8_t))];
        int level = samplingFactors >> 4;
        int vertical = samplingFactors & 0x0f;
        _Y_qtTable.sampl_vertical = vertical;
        _U_qtTable.sampl_vertical = vertical;
        _V_qtTable.sampl_vertical = vertical;
        _Y_qtTable.sampl_level = level;
        _U_qtTable.sampl_level = level;
        _V_qtTable.sampl_level = level;
        pa += sizeof(uint8_t);
        
        //  量化表 ID
        uint8_t qID = 0;
        [data getBytes:&qID range:NSMakeRange(pa, sizeof(uint8_t))];
        _Y_qtTable.qt_table = _qtTable[qID];
        _U_qtTable.qt_table = _qtTable[qID];
        _V_qtTable.qt_table = _qtTable[qID];
        pa += sizeof(uint8_t);
    }
    
    if (colorComponentsCount == 3)
    {// YUV
        uint8_t ccID = 0;
        uint8_t samplingFactors = 0;
        int level = 0;
        int vertical = 0;
        uint8_t qID = 0;
        
        // Y
        [data getBytes:&ccID range:NSMakeRange(pa, sizeof(uint8_t))];
        _Y_qtTable.index = ccID;
        pa += sizeof(uint8_t);
        
        [data getBytes:&samplingFactors range:NSMakeRange(pa, sizeof(uint8_t))];
        level = samplingFactors >> 4;
        vertical = samplingFactors & 0x0f;
        _Y_qtTable.sampl_vertical = vertical;
        _Y_qtTable.sampl_level = level;
        pa += sizeof(uint8_t);
        
        [data getBytes:&qID range:NSMakeRange(pa, sizeof(uint8_t))];
        _Y_qtTable.qt_table = _qtTable[qID];
        pa += sizeof(uint8_t);
        
        // U
        [data getBytes:&ccID range:NSMakeRange(pa, sizeof(uint8_t))];
        _U_qtTable.index = ccID;
        pa += sizeof(uint8_t);
        
        [data getBytes:&samplingFactors range:NSMakeRange(pa, sizeof(uint8_t))];
        level = samplingFactors >> 4;
        vertical = samplingFactors & 0x0f;
        _U_qtTable.sampl_vertical = vertical;
        _U_qtTable.sampl_level = level;
        pa += sizeof(uint8_t);
        
        [data getBytes:&qID range:NSMakeRange(pa, sizeof(uint8_t))];
        _U_qtTable.qt_table = _qtTable[qID];
        pa += sizeof(uint8_t);
        
        // V
        [data getBytes:&ccID range:NSMakeRange(pa, sizeof(uint8_t))];
        _V_qtTable.index = ccID;
        pa += sizeof(uint8_t);
        
        [data getBytes:&samplingFactors range:NSMakeRange(pa, sizeof(uint8_t))];
        level = samplingFactors >> 4;
        vertical = samplingFactors & 0x0f;
        _V_qtTable.sampl_vertical = vertical;
        _V_qtTable.sampl_level = level;
        pa += sizeof(uint8_t);
        
        [data getBytes:&qID range:NSMakeRange(pa, sizeof(uint8_t))];
        _V_qtTable.qt_table = _qtTable[qID];
        pa += sizeof(uint8_t);
    }
}

- (void) parserDHTWithData:(NSData *) data
{// Difine Huffman Table，定义哈夫曼表
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
    
    while (length - pa > 0)
    {// 哈夫曼表
        //  表ID和表类型 (Tc,Th)
        uint8_t tableTypeAndID = 0;
        [data getBytes:&tableTypeAndID range:NSMakeRange(pa, sizeof(uint8_t))];
        int tableTypt = tableTypeAndID >> 4; // 高4位：类型，只有两个值可选。0：DC直流；1：AC交流。
        int tableID = tableTypeAndID & 0x0f;// 低4位：哈夫曼表ID。
        int tableIndex = 2 * tableTypt + tableID; // Huffman表编号(2×Tc+Th)
        _huffmanTable[tableIndex].index = tableIndex;
        pa += sizeof(uint8_t);
        
        // 总共16行，每一行的位数不一样。总共16行
        int count = 0;
        for (int i = 0; i < 16; i++)
        {
            uint8_t countInLine = 0;
            [data getBytes:&countInLine range:NSMakeRange(pa, sizeof(uint8_t))];
            _huffmanTable[tableIndex].code_len[i] = countInLine;
            count += countInLine;
            pa += sizeof(uint8_t);
        }
        
        uint8_t *items = (uint8_t *) malloc(sizeof(uint8_t) * count);
        uint8_t *pi = items;
        for (int i = 0; i < 16; i++)
        {
            NSUInteger count = _huffmanTable[tableIndex].code_len[i];
            if (count)
            {
                for (int j = 0; j < count; j++)
                {
                    uint8_t num = 0;
                    [data getBytes:&num range:NSMakeRange(pa, sizeof(uint8_t))];
                    *pi = num;
                    pi++;
                    pa += sizeof(uint8_t);
                }
            }
        }
        _huffmanTable[tableIndex].value = items;
    }
}

- (void) parserDRIWithData:(NSData *) data
{// Define Restart Interval，定义差分编码累计复位的间隔
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
    
    if (length - pa > 0)
    {// MCU块的单元中的重新开始间隔
        uint16_t restart = 0;
        [data getBytes:&restart range:NSMakeRange(pa, sizeof(uint16_t))];
        restart = MakeUint16(restart);
        _restartMCU = restart;
        pa += sizeof(uint16_t);
    }
}

- (void) parserSOSWithData:(NSData *) data
{// Start of Scan，扫描开始
    NSUInteger pa = 0;
    // 数据长度
    uint16_t length = data.length;
    pa += sizeof(uint16_t);
    
    uint8_t colorComponentsCount = 0;
    if (length - pa > 0)
    {// 颜色分量数 1：灰度图；3：YCrCb或YIQ；4：CMYK (而JFIF中使用YCrCb，故这里颜色分量数恒为3)
        [data getBytes:&colorComponentsCount range:NSMakeRange(pa, sizeof(uint8_t))];
        pa += sizeof(uint8_t);
    }
    
    if (self.colorSpace != colorComponentsCount)
        return;
    
    if (length - pa > 0)
    {// 颜色分量信息
        for (int i = 0; i < colorComponentsCount; i++)
        {
            uint8_t colorComponentsID = 0;
            [data getBytes:&colorComponentsID range:NSMakeRange(pa, sizeof(uint8_t))];
            pa += sizeof(uint8_t);
            
            uint8_t DcAcId = 0;
            [data getBytes:&DcAcId range:NSMakeRange(pa, sizeof(uint8_t))];
            int DcId = DcAcId >> 4;
            int AcId = DcAcId & 0x0f;
            if (colorComponentsID == _Y_qtTable.index)
            {
                _Y_qtTable.Dc_index = DcId;
                _Y_qtTable.Ac_index = 2 + AcId;
            }
            else
            {
                _U_qtTable.Dc_index = DcId;
                _U_qtTable.Ac_index = 2 + AcId;
                _V_qtTable.Dc_index = DcId;
                _V_qtTable.Ac_index = 2 + AcId;
            }
            pa += sizeof(uint8_t);
        }
    }
    
//    if (length - pa > 0)
//    {// 压缩图像数据
//        uint8_t spectralBegin = 0;
//        [data getBytes:&spectralBegin range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//        
//        uint8_t spectralEnd = 0;
//        [data getBytes:&spectralEnd range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//        
//        uint8_t spectral = 0;
//        [data getBytes:&spectral range:NSMakeRange(pa, sizeof(uint8_t))];
//        pa += sizeof(uint8_t);
//    }
}

uint8_t ycoef = 0;
uint8_t ucoef = 0;
uint8_t vcoef = 0;
uint8_t BitPos = 0;
uint8_t CurByte = 0;
uint8_t BlockBuffer[64];

//- (uint8_t) readByte
//{
////    uint8_t i;
////    
////    i = *(lp++);
////    if (i==0xff)
////        lp++;
////    BitPos = 8;
////    CurByte = i;
////    return i;
//    
//    return 0;
//}

- (void) prepareDecodeParameter
{
    _lpIndex = 0;
    for (int tableIndex = 0; tableIndex < 4; tableIndex++)
    {
        _huffmanTable[tableIndex].min_value[0] = 0;
        _huffmanTable[tableIndex].max_value[0] = _huffmanTable[tableIndex].code_len[0];
        _huffmanTable[tableIndex].code_pos[0] = 0;
        
        uint16_t nextItem = 0;
        uint8_t len = 0;
        for (int i = 1; i < 16; i++)
        {
            len = _huffmanTable[tableIndex].code_len[i];
            if (len > 0)
            {
                _huffmanTable[tableIndex].min_value[i] = nextItem;
                _huffmanTable[tableIndex].max_value[i] = nextItem + len - 1;
                nextItem = _huffmanTable[tableIndex].max_value[i];
                nextItem = nextItem + 1;
            }
            nextItem = nextItem << 1;
            
            _huffmanTable[tableIndex].code_pos[i] = _huffmanTable[tableIndex].code_pos[i - 1] + len;
        }
    }
}

- (uint8_t) readByteAndRunNext
{
    uint8_t a = *_lp;
    _lp++;
    _lpIndex ++;
    if (a == 0xff && *_lp == 0x00)
    {
        _lp++;
        _lpIndex ++;
    }
    return a;
}

- (void) decodeWithData:(NSData *) data toContext:(CGContextRef) ctx
{
    [self prepareDecodeParameter];
    _lp = (uint8_t *)data.bytes;
    
    int16_t mcbTable[10][64];
    int16_t qtzzTable[10][64];
    
    int16_t yLastItem = 0;
    int16_t uLastItem = 0;
    int16_t vLastItem = 0;
    
    int16_t y[4][64];
    int16_t u[4][64];
    int16_t v[4][64];
    
    uint8_t r[4][64];
    uint8_t g[4][64];
    uint8_t b[4][64];
    
    int ptX = 0;
    int ptY = 0;
    
    BOOL isRestart = NO;
    int interval = 0;
    BOOL isSucceed = NO;
    
    while ((isSucceed = [self decodeMCBToTable:mcbTable
                                 withIsRestart:isRestart
                                 withYLastItem:&yLastItem
                                 withULastItem:&uLastItem
                                 withVLastItem:&vLastItem]))
    {
        interval++;
        isRestart = (_restartMCU && interval % _restartMCU == 0);
        
        [self transitionQtToZz:qtzzTable withMCUTable:mcbTable];
        [self getYUV:y :u :v withQtZzTable:qtzzTable];
        [self getRGB:r :g :b
             withYUV:y :u :v];
        [self makeImageToCtx:ctx withR:r withG:g withB:b withPtX:ptX withPtY:ptY];
        
        ptX += _Y_qtTable.sampl_level * 8;
        if (ptX >= self.imageSize.width)
        {
            ptX = 0;
            ptY += _Y_qtTable.sampl_vertical * 8;
        }
        
        if ((ptX == 0) && (ptY >= self.imageSize.height))
            break;
    }
    
    if (isSucceed)
    {
        NSLog(@"Succeed");
        CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
        UIImage *image = [UIImage imageWithCGImage:imgRef];
        [self.delegate imageMake:image];
    }
    else
    {
        NSLog(@"fail");
    }
}

- (BOOL) decodeMCBToTable:(int16_t[10][64]) mcbTable
            withIsRestart:(BOOL) isRestart
            withYLastItem:(int16_t *) yLastItem
            withULastItem:(int16_t *) uLastItem
            withVLastItem:(int16_t *) vLastItem
{// 读数据并解码成 8 * 8 的量化表
    if (isRestart)
    {
        _lp += 2;
        _lpIndex += 2;
        _bitPos = 0;
        *yLastItem = *uLastItem = *vLastItem = 0;
    }
    
    uint8_t index = 0;
    switch (self.colorSpace)
    {
        case 3:
        {
            if (![self decodeSingleMCBToTable:mcbTable
                                   withQtInfo:_Y_qtTable
                            withMCBTableIndex:&index
                                 withLastItem:yLastItem])
            {
                return NO;
            }
            
            if (![self decodeSingleMCBToTable:mcbTable
                                   withQtInfo:_U_qtTable
                            withMCBTableIndex:&index
                                 withLastItem:uLastItem])
            {
                return NO;
            }
            
            if (![self decodeSingleMCBToTable:mcbTable
                                   withQtInfo:_V_qtTable
                            withMCBTableIndex:&index
                                 withLastItem:vLastItem])
            {
                return NO;
            }
        }
            break;
        case 1:
        {
            if (![self decodeSingleMCBToTable:mcbTable
                                   withQtInfo:_Y_qtTable
                            withMCBTableIndex:&index
                                 withLastItem:yLastItem])
            {
                return NO;
            }
            for (int i = 0; i < 64; i++)
            {
                mcbTable[index][i] = 0;
                mcbTable[index + 1][i] = 0;
            }
        }
            break;
        default:
            break;
    }
    
    return YES;
}

- (BOOL) decodeSingleMCBToTable:(int16_t[10][64])mcbTable
                     withQtInfo:(JPEGColorComponents) info
              withMCBTableIndex:(uint8_t *) index
                   withLastItem:(int16_t *) lastItem
{
    for (int i = 0; i < info.sampl_level * info.sampl_vertical; i++)
    {
        if (![self decodeMCBItem:mcbTable[*index] withDCIndex:info.Dc_index withACIndex:info.Ac_index])
        {
            return NO;
        }
        mcbTable[*index][0] += *lastItem;
        *lastItem = mcbTable[*index][0];
        (*index)++;
    }
    return YES;
}

- (BOOL) decodeMCBItem:(int16_t[64]) mcbTable
           withDCIndex:(uint8_t) dcIndex
           withACIndex:(uint8_t) acIndex
{// 解析一个MCB（量化表）
    
    int16_t value = 0;
    uint8_t weight = 0;
    int readSize = 0;
    int interval = 0;
    
    // 用 Dc 表取首位元素
    if ([self decodeSingleWeight:&weight
                withHuffmanIndex:dcIndex])
    {
        readSize = weight;
        [self decodeToValue:&value
                 withWeight:readSize
           withHuffmanIndex:dcIndex];
        
        mcbTable[0] = value;
    }
    else
    {
        return NO;
    }
    
    // 用 Ac 取剩下的元素
    for (int i = 1; i < 64; i++)
    {
        if ([self decodeSingleWeight:&weight
                    withHuffmanIndex:acIndex])
        {
            if (weight == 0)
            {
                for (; i < 64; i++)
                {
                    mcbTable[i] = 0;
                }
                break;
            }
            
            interval = weight >> 4;
            readSize = weight & 0x0f;
            
            [self decodeToValue:&value
                     withWeight:readSize
               withHuffmanIndex:acIndex];
            
            for (int j = 0; j < interval; j++)
            {
                mcbTable[i] = 0;
                i++;
            }
            mcbTable[i] = value;
        }
        else
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL) decodeSingleWeight:(uint8_t *) weight
           withHuffmanIndex:(uint8_t) huffmanIndex
{// 先读取权指（后面用于解析成要间隔的大小和接下来要读取的位数）
    uint16_t decodeByte = 0;
    uint8_t tmpByte = 0;
    int codelen = -1; // 匹配Huffman表
    
    do
    {
        if (_bitPos > 0)
        {
            _bitPos--;
            tmpByte = _curByte >> _bitPos;
            _curByte = _curByte & And[_bitPos];
        }
        else
        {
            _curByte = [self readByteAndRunNext];
            _bitPos = 7;
            tmpByte = _curByte >> 7;
            _curByte = _curByte & And[7];
        }
        decodeByte = (decodeByte << 1) + tmpByte;
        
        codelen ++;
        if (codelen > 16)
        {
            return NO;
        }
    }
    while (decodeByte < _huffmanTable[huffmanIndex].min_value[codelen] ||
           _huffmanTable[huffmanIndex].code_len[codelen] == 0 ||
           decodeByte > _huffmanTable[huffmanIndex].max_value[codelen]);
    
    // 先读取权指，解析成要间隔的大小和接下来要读取的位数
    uint16_t indexHuffValue = _huffmanTable[huffmanIndex].code_pos[codelen] + decodeByte - _huffmanTable[huffmanIndex].max_value[codelen] - 1;
    uint8_t weightValue = _huffmanTable[huffmanIndex].value[indexHuffValue];
    
    *weight = weightValue;
    
    return YES;
}

- (BOOL) decodeToValue:(int16_t *) value
            withWeight:(int) weight
      withHuffmanIndex:(uint8_t) huffmanIndex
{
    // 继续往后读参数
    uint16_t tmpValue = 0;
    int tmpSize = weight;
    do
    {
        int curBitPos = MIN(_bitPos, tmpSize);
        _bitPos -= curBitPos;
        tmpSize -= curBitPos;
        tmpValue += (uint16_t)(_curByte >> _bitPos) << tmpSize;
        _curByte = _curByte & And[_bitPos];
        if (_bitPos == 0 || tmpSize > 0)
        {
            _curByte = [self readByteAndRunNext];
            _bitPos = 8;
        }
    }
    while (tmpSize > 0);
    
    if (tmpValue >> (weight - 1))
    {
        *value = tmpValue;
    }
    else
    {// 如果首位是0，那么需要将该数所有位取反，然后取负数
        tmpValue = tmpValue ^ 0xffff;
        tmpValue = tmpValue ^ (0xffff << weight);
        *value = -tmpValue;
    }
    
    return YES;
}

- (void) transitionQtToZz:(int16_t [10][64]) qtzzTable
             withMCUTable:(int16_t [10][64]) mcuTable
{
    uint8_t index = 0;
    [self transitionSingleQtToZz:qtzzTable
                    withMCUTable:mcuTable
               withMCBTableIndex:&index
                      withQtInfo:_Y_qtTable
                      withOffset:128];
    
    [self transitionSingleQtToZz:qtzzTable
                    withMCUTable:mcuTable
               withMCBTableIndex:&index
                      withQtInfo:_U_qtTable
                      withOffset:0];
    [self transitionSingleQtToZz:qtzzTable
                    withMCUTable:mcuTable
               withMCBTableIndex:&index
                      withQtInfo:_V_qtTable
                      withOffset:0];
}

- (void) transitionSingleQtToZz:(int16_t [10][64]) qtzzTable
                   withMCUTable:(int16_t [10][64]) mcuTable
              withMCBTableIndex:(uint8_t *) index
                     withQtInfo:(JPEGColorComponents) qtInfo
                     withOffset:(int16_t) offset
{
    uint8_t l = qtInfo.sampl_level;
    uint8_t v = qtInfo.sampl_vertical;
    for (int i = 0; i < l * v; i++)
    {
        [self transitionQtItemToZz:qtzzTable[*index]
                      withMCUTable:mcuTable[*index]
                        withQtInfo:qtInfo
                        withOffset:offset];
        (*index)++;
    }
}

- (void) transitionQtItemToZz:(int16_t [64]) qtzzTable
                 withMCUTable:(int16_t [64]) mcuTable
                   withQtInfo:(JPEGColorComponents) qtInfo
                   withOffset:(int16_t) offset
{
    int buffer[8][8];
    int tag;
    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            tag = Zig_Zag[i][j];
            buffer[i][j] = (int)(mcuTable[tag] * qtInfo.qt_table[tag]);
        }
    }
    [self fastIDCT:(int *)buffer];
    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            qtzzTable[i * 8 + j] = buffer[i][j] + 128;
        }
    }
}

- (void) fastIDCT:(int *) buffer
{
    for (int i = 0; i < 8; i++)
        idctrow(buffer + 8 * i);
    
    for (int i = 0; i<8; i++)
        idctcol(buffer + i);
}

- (void) getYUV:(int16_t[4][64]) y :(int16_t[4][64]) u :(int16_t[4][64]) v
  withQtZzTable:(int16_t[10][64]) qtzzTable
{
    int index = 0;
    for (int i = 0; i < _Y_qtTable.sampl_level * _Y_qtTable.sampl_vertical; i++)
    {
        for (int k = 0; k < 8 * 8; k++)
            y[i][k] = qtzzTable[index][k];
        index ++;
    }
    
    for (int i = 0; i < _U_qtTable.sampl_level * _U_qtTable.sampl_vertical; i++)
    {
        for (int k = 0; k < 8 * 8; k++)
            u[i][k] = qtzzTable[index][k];
        index ++;
    }
    
    for (int i = 0; i < _V_qtTable.sampl_level * _V_qtTable.sampl_vertical; i++)
    {
        for (int k = 0; k < 8 * 8; k++)
            v[i][k] = qtzzTable[index][k];
        index ++;
    }
}

- (void) getRGB:(uint8_t[4][64]) r :(uint8_t[4][64]) g :(uint8_t[4][64]) b
        withYUV:(int16_t[4][64]) y :(int16_t[4][64]) u :(int16_t[4][64]) v
{
    int l_YtoU = _Y_qtTable.sampl_level / _U_qtTable.sampl_level;
    int v_YtoU = _Y_qtTable.sampl_vertical / _U_qtTable.sampl_vertical;
    int l_YtoV = _Y_qtTable.sampl_level / _V_qtTable.sampl_level;
    int v_YtoV = _Y_qtTable.sampl_vertical / _V_qtTable.sampl_vertical;
    
    int16_t cr, cg, cb;
    int16_t yy, uu, vv;
    uint8_t R, G, B;
    
    for (int i = 0; i < _Y_qtTable.sampl_vertical; i++)
    {
        for (int j = 0; j < _Y_qtTable.sampl_level; j++)
        {
            for (int k = 0; k < 8; k++)
            {
                for (int h = 0; h < 8; h++)
                {
                    yy = y[i * _Y_qtTable.sampl_level + j][k * 8 + h];
                    uu = u[(i / v_YtoU) * _Y_qtTable.sampl_level + j / l_YtoU][k * 8 + h];
                    vv = v[(i / v_YtoV) * _Y_qtTable.sampl_level + j / l_YtoV][k * 8 + h];
                    
                    cr = yy + 1.402 * (vv - 128);
                    cg = yy - 0.34414 * (uu - 128) - 0.71414 * (vv - 128);
                    cb = yy + 1.772 * (uu - 128);
                    R = (uint8_t)cr;
                    G = (uint8_t)cg;
                    B = (uint8_t)cb;
                    if (cr & 0xff00)
                    {
                        if (cr > 255) R = 255;
                        else if (cr < 0) R = 0;
                    }
                    if (cg & 0xff00)
                    {
                        if (cg > 255) G = 255;
                        else if (cg < 0) G = 0;
                    }
                    if (cb & 0xff00)
                    {
                        if (cb > 255) B = 255;
                        else if (cb < 0) B = 0;
                    }
                    r[i * _Y_qtTable.sampl_level + j][k * 8 + h] = R;
                    g[i * _Y_qtTable.sampl_level + j][k * 8 + h] = G;
                    b[i * _Y_qtTable.sampl_level + j][k * 8 + h] = B;
                }
            }
        }
    }
}

- (void) makeImageToCtx:(CGContextRef) ctx
                  withR:(uint8_t[4][64]) r withG:(uint8_t[4][64]) g withB:(uint8_t[4][64]) b
                withPtX:(int) ptX withPtY:(int) ptY
{
    UInt32 *colorData = CGBitmapContextGetData(ctx);
    for (int i = 0; i < _Y_qtTable.sampl_level; i ++)
    {
        for (int j = 0; j < _Y_qtTable.sampl_vertical; j++)
        {
            for (int k = 0; k < 8; k++)
            {
                for (int h = 0; h < 8; h++)
                {
                    int x = ptX + j * 8 + h;
                    int y = ptY + i * 8 + k;
                    if (x >= self.imageSize.width || y >= self.imageSize.height)
                    {
                        break;
                    }
                    UInt32 *subData;
                    subData = colorData + y * (uint32_t)self.imageSize.width + x;
                    
                    UInt8 *bgra;
                    bgra = (UInt8 *)subData;
                    bgra[0] = b[i * _Y_qtTable.sampl_level + j][k * 8 + h];
                    bgra[1] = g[i * _Y_qtTable.sampl_level + j][k * 8 + h];
                    bgra[2] = r[i * _Y_qtTable.sampl_level + j][k * 8 + h];
                    bgra[3] = 255;
                }
            }
        }
    }
}

@end
