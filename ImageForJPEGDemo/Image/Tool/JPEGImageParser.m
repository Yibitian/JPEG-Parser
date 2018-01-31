//
//  JPEGImageParser.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImageParser.h"
#import "JPEGDataTool.h"
#import "JPEGImageBitTool.h"

#define JPEGMakeUint16(a) ((uint16_t)(a >> 8 | a << 8))

#define M_SOI   0xd8
#define M_APP0  0xe0
#define M_DQT   0xdb
#define M_SOF0  0xc0
#define M_DHT   0xc4
#define M_DRI   0xdd
#define M_SOS   0xda
#define M_EOI   0xd9

typedef enum JPEGImageDataFlag
{
    JPEGImageDataFlag_NON  = -1,
    
    JPEGImageDataFlag_SOI   = M_SOI,
    JPEGImageDataFlag_APP0  = M_APP0,
    JPEGImageDataFlag_DQT   = M_DQT,
    JPEGImageDataFlag_SOF0  = M_SOF0,
    JPEGImageDataFlag_DHT   = M_DHT,
    JPEGImageDataFlag_DRI   = M_DRI,
    JPEGImageDataFlag_SOS   = M_SOS,
    JPEGImageDataFlag_EOI   = M_EOI,
    
}JPEGImageDataFlag;

@interface JPEGImageParser ()
{
    int16_t _lastArr[3];
}

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) JPEGImageInfo *info;
@property (nonatomic, strong) JPEGImageChroma *chromas;

@property (nonatomic, strong) JPEGImageDataTool *scanner;

@property (nonatomic, strong) JPEGImageBitTool *bitReadTool;
@property (nonatomic, strong) JPEGImageBitTool *bitWriteTool;

@end

@implementation JPEGImageParser

- (instancetype)initWithData:(NSData *) data
{
    self = [super init];
    if (self)
    {
        self.data = data;
    }
    return self;
}

- (instancetype)initWithPath:(NSString *) path
{
    self = [super init];
    if (self)
    {
        NSData *data = [NSMutableData dataWithContentsOfFile:path];
        self.data = data;
    }
    return self;
}

- (JPEGImageInfo *) info
{
    if (!_info)
    {
        _info = [[JPEGImageInfo alloc] init];
    }
    return _info;
}

- (JPEGImageInfo *) hearInfo
{
    return _info;
}

- (JPEGImageChroma *) chromas
{
    if (_chromas)
    {
        _chromas = [[JPEGImageChroma alloc] init];
    }
    return _chromas;
}

- (JPEGImageChroma *) chromasInfo
{
    return _chromas;
}

- (JPEGImageDataTool *) scanner
{
    if (!self.data.length)
    {
        return nil;
    }
    
    if (!_scanner)
    {
        _scanner = [JPEGImageDataTool scannerWithData:self.data];
    }
    return _scanner;
}

- (JPEGImageBitTool *) bitReadTool
{
    if (!_bitReadTool)
    {
        _bitReadTool = [[JPEGImageBitTool alloc] init];
    }
    return _bitReadTool;
}

- (JPEGImageBitTool *) bitWriteTool
{
    if (!_bitWriteTool)
    {
        _bitWriteTool = [[JPEGImageBitTool alloc] init];
    }
    return _bitWriteTool;
}

#pragma mark - event

- (void) startParser
{
    if (!self.scanner || self.scanner.isScanEnd)
    {
        return;
    }
    while (!self.scanner.isScanEnd)
    {
        uint16_t mark = 0;
        [self.scanner getBytes:&mark ofLength:sizeof(mark)];
        JPEGImageDataFlag flag = [self getParserWithMark:mark];
        
        if (flag == JPEGImageDataFlag_NON)
        {
            break;
        }
        else
        {
            [self.scanner scanBytes:NULL ofLength:2];
            [self analyzeInfoWithFlag:flag];
        }
    }
}

- (JPEGImageDataFlag) getParserWithMark:(uint16_t) mark
{
    JPEGImageDataFlag flag = JPEGImageDataFlag_NON;
    uint8_t f = mark;
    if (f != 0xff)
        return flag;
    
    uint8_t m = mark >> 8;
    flag = m;
    return flag;
}

- (void) analyzeInfoWithFlag:(JPEGImageDataFlag)flag
{
    if (flag == JPEGImageDataFlag_SOI || flag == JPEGImageDataFlag_EOI)
    {
        return;
    }
    
    uint16_t length = 0;
    [self.scanner getBytes:&length ofLength:sizeof(length)];
    length = JPEGMakeUint16(length);
    
    NSData *data = nil;
    [self.scanner scanData:&data ofLength:length];
    
    {
        JPEGDataTool *subScanner = [JPEGDataTool scannerWithData:data];
        [subScanner scanBytes:NULL ofLength:2];
        
        switch (flag)
        {
            case JPEGImageDataFlag_APP0:
            {
                [self analyzeAPP0WithScanner:subScanner];
            }
                break;
            case JPEGImageDataFlag_DQT:
            {
                [self analyzeDQTWithScanner:subScanner];
            }
                break;
            case JPEGImageDataFlag_SOF0:
            {
                [self analyzeSOF0WithScanner:subScanner];
            }
                break;
            case JPEGImageDataFlag_DHT:
            {
                [self analyzeDHTWithScanner:subScanner];
            }
                break;
            case JPEGImageDataFlag_DRI:
            {
                [self analyzeDRIWithScanner:subScanner];
            }
                break;
            case JPEGImageDataFlag_SOS:
            {
                [self analyzeSOSWithScanner:subScanner];
            }
                break;
            default:
                break;
        }
    }
}

- (void) analyzeAPP0WithScanner:(JPEGDataTool *) scanner
{
    NSString *fileType = nil;
    [scanner scanNullTerminatedString:&fileType withEncoding:NSUTF8StringEncoding];
    self.info.fileType = fileType;
    
    NSString *versions = nil;
    {
        uint16_t ver = 0;
        [scanner scanBytes:&ver ofLength:sizeof(ver)];
        versions = [NSString stringWithFormat:@"%d.%d",  (uint8_t)(ver >> 8), (uint8_t)ver];
    }
    self.info.versions = versions;
}

- (void) analyzeDQTWithScanner:(JPEGDataTool *) scanner
{
    while (!scanner.isScanEnd)
    {
        uint8_t precision = 0;
        [scanner scanBytes:&precision ofLength:sizeof(precision)];
        
        int tag = precision & 0x0f;
        int bitSize = precision & 0xf0 ? sizeof(uint16_t) : sizeof(uint8_t);
        
        NSData *parameters = nil;
        [scanner scanData:&parameters ofLength:64 * bitSize];
        
        [self.info creatQuantizationTable:^(JPEGQuantizationTable *table) {
            table.tag = tag;
            table.bitSize = bitSize;
            table.data = parameters;
        }];
    }
}

- (void) analyzeSOF0WithScanner:(JPEGDataTool *) scanner
{
    uint8_t precision = 0;
    [scanner scanBytes:&precision ofLength:sizeof(precision)];
    
    uint16_t height = 0;
    uint16_t width = 0;
    [scanner scanBytes:&height ofLength:sizeof(height)];
    [scanner scanBytes:&width ofLength:sizeof(width)];
    self.info.size = CGSizeMake(height, width);
    
    uint8_t chromaCount = 0;
    [scanner scanBytes:&chromaCount ofLength:sizeof(chromaCount)];
    
    for (int i = 0; i < chromaCount; i++)
    {
        uint8_t tag = 0;
        [scanner scanBytes:&tag ofLength:sizeof(tag)];
        
        uint8_t samp = 0;
        [scanner scanBytes:&samp ofLength:sizeof(samp)];
        int level = samp >> 4;
        int vertical = samp & 0x0f;
        
        uint8_t qtTag = 0;
        [scanner scanBytes:&qtTag ofLength:sizeof(qtTag)];
        
        [self.info creatQuantizationIndex:^(JPEGQuantizationIndex *index) {
            index.tag = tag;
            index.sampLevel = level;
            index.sampVertical = vertical;
            index.qtTag = qtTag;
        }];
    }
}

- (void) analyzeDHTWithScanner:(JPEGDataTool *) scanner
{
    while (!scanner.isScanEnd)
    {
        uint8_t tableFlag = 0;
        [scanner scanBytes:&tableFlag ofLength:sizeof(tableFlag)];
        int tableType = tableFlag >> 4;
        int tableId = tableFlag & 0x0f;
        int tableTag = 2 * tableType + tableId;
        
        NSData *lens = nil;
        [scanner scanData:&lens ofLength:16];
        int count = getHuffmanTableLengthFromData(lens);
        
        NSData *items = nil;
        [scanner scanData:&items ofLength:count];
        
        [self.info creatHuffmanTable:^(JPEGHuffmanTable *table) {
            table.tag = tableTag;
            table.codeLen = lens;
            table.codeValue = items;
            [table initHuffmanTable];
        }];
    }
}

- (void) analyzeDRIWithScanner:(JPEGDataTool *) scanner
{
    uint16_t restart = 0;
    [scanner scanBytes:&restart ofLength:sizeof(restart)];
    self.info.restartMCU = restart;
}

- (void) analyzeSOSWithScanner:(JPEGDataTool *) scanner
{
    uint8_t chromaCount = 0;
    [scanner scanBytes:&chromaCount ofLength:sizeof(chromaCount)];
    
    for (int i = 0; i < chromaCount; i++)
    {
        uint8_t tag = 0;
        [scanner scanBytes:&tag ofLength:sizeof(tag)];
        
        uint8_t tableFlag = 0;
        [scanner scanBytes:&tableFlag ofLength:sizeof(tableFlag)];
        int dcTag = tableFlag >> 4;
        int acTag = tableFlag & 0x0f;
        
        [self.info creatHuffmanIndex:^(JPEGHuffmanIndex *index) {
            index.tag = tag;
            index.dcTag = dcTag;
            index.acTag = 2 + acTag;
        }];
    }
}

- (void) readNextByte
{
    uint8_t byte = [self.scanner extractByteWithBrockRSTn:^(){
        _lastArr[0] = 0;
        _lastArr[1] = 0;
        _lastArr[2] = 0;
    } brockEOI:^(){
        
    }];
    
    self.bitReadTool.byte = byte;
}

- (void) decodeWeight:(uint8_t *) weight
                value:(int16_t *) value
        withHuffTable:(JPEGHuffmanTable *) huffTable
{
    int readSize = 0;
    
    {
        uint16_t decodeByte = 0;
        int codelen = -1;
        
        do
        {
            if (self.bitReadTool.isEnd)
            {
                [self readNextByte];
            }
            [self.bitReadTool spliceNextBitToByte:&decodeByte];
            codelen ++;
            if (codelen > 15)
            {
                return;
            }
        }
        while ([huffTable countOfLen:codelen] == 0 ||
               decodeByte < [huffTable minItemOfIndex:codelen] ||
               decodeByte > [huffTable maxItemOfIndex:codelen]);
        
        // 先读取权指，解析成要间隔的大小和接下来要读取的位数
        uint16_t indexHuffValue = [huffTable codePosOfIndex:codelen] + decodeByte - [huffTable maxItemOfIndex:codelen] - 1;
        uint8_t weightValue = [huffTable valueOfIndex:indexHuffValue];
        
        *weight = weightValue;
    }
    
    readSize = *weight & 0x0f;
    
    // 继续往后读参数
    uint16_t tmpValue = 0;
    int tmpSize = readSize;
    while (tmpSize > 0)
    {
        if (self.bitReadTool.isEnd)
        {
            [self readNextByte];
        }
        tmpSize = [self.bitReadTool spliceBitToByte:&tmpValue withLenght:tmpSize];
    }
    
    if (!(tmpValue >> (readSize - 1)))
    {// 如果首位是0，那么需要将该数所有位取反，然后取负数
        tmpValue = tmpValue ^ 0xffff;
        tmpValue = tmpValue ^ (0xffff << readSize);
        tmpValue = -tmpValue;
    }
    *value = tmpValue;
}

- (void) recodeWeight:(uint8_t *) weight
                value:(int16_t *) value
        withHuffTable:(JPEGHuffmanTable *) huffTable
               toData:(NSMutableData *) mcuData
{
    int16_t valueTmp = *value;
    int16_t newData = 0;
    int size = 0;
    uint8_t weightTmp = 0;
    
    if (weight == NULL)
    {
        int16_t valueTmp = *value;
        while (valueTmp != 0)
        {
            size++;
            valueTmp /= 2;
        }
        valueTmp = *value;
        weightTmp = weightTmp | size;
    }
    else
    {
        weightTmp = *weight;
        size = weightTmp & 0x0f;
    }
    
    if (valueTmp < 0)
    {
        valueTmp = -valueTmp;
        valueTmp = valueTmp ^ (0xffff << size);
        valueTmp = valueTmp ^ 0xffff ;
    }
    newData = valueTmp;
    
    uint16_t code = 0;
    int codeWidth = 0;
    NSRange range = [huffTable.codeValue rangeOfData:[NSData dataWithBytes:&weightTmp length:sizeof(weightTmp)]
                                             options:NSDataSearchBackwards
                                               range:NSMakeRange(0, [huffTable.codeValue length])];
    
    NSUInteger index = range.location;
    if (index == NSNotFound)
    {
        NSAssert(index != NSNotFound, @"First delimiter not found");
    }
    
    for (int i = 0; i < 16; i++)
    {
        if ([huffTable codePosOfIndex:i] >= index + 1)
        {
            codeWidth = i + 1;
            code = [huffTable maxItemOfIndex:i] + index + 1 - [huffTable codePosOfIndex:i];
            break;
        }
    }
    
    [self.bitWriteTool condenseByte:code withLenght:codeWidth callBack:^(uint8_t byte) {
        [mcuData appendBytes:&byte length:sizeof(byte)];
        if (byte == 0xff)
        {
            byte = 0x00;
            [mcuData appendBytes:&byte length:sizeof(byte)];
        }
    }];
    
    if (code != 0)
    {
        [self.bitWriteTool condenseByte:newData withLenght:size callBack:^(uint8_t byte) {
            [mcuData appendBytes:&byte length:sizeof(byte)];
            if (byte == 0xff)
            {
                byte = 0x00;
                [mcuData appendBytes:&byte length:sizeof(byte)];
            }
        }];
    }
}

- (void) carveChroma
{
    if (_info == nil)
    {
        return;
    }
    
    self.chromas.scale = 1;
    self.chromas.size = self.info.size;
    while (!self.scanner.isScanEnd)
    {
        NSData *data = [self carveChromaData];
        [self.chromas.mcuData addObject:data];
    }
    
    NSLog(@"end");
}

- (NSData *) carveChromaData
{
    NSMutableData *data = [NSMutableData data];
    
    for (int i = 0; i < self.info.quantizationIndexs.count; i++)
    {
        JPEGQuantizationIndex *qtIndex = self.info.quantizationIndexs[i];
        JPEGHuffmanIndex *huffIndex = self.info.huffmanIndexs[i];
        
        for (int spIndex = 0; spIndex < qtIndex.sampCount; spIndex ++)
        {
            JPEGHuffmanTable *huffTable = nil;
            int16_t value = 0;
            uint8_t weight = 0;
            
            huffTable = self.info.huffmanTables[@(huffIndex.dcTag)];
            [self decodeWeight:&weight value:&value withHuffTable:huffTable];
            value += _lastArr[i];
            _lastArr[i] = value;
            [self recodeWeight:NULL value:&value withHuffTable:huffTable toData:data];
            
            huffTable = self.info.huffmanTables[@(huffIndex.acTag)];
            
            for (int i = 1; i < 64; i++)
            {
                [self decodeWeight:&weight value:&value withHuffTable:huffTable];
                [self recodeWeight:&weight value:&value withHuffTable:huffTable toData:data];
                if (weight == 0)
                {
                    break;
                }
                
                i += weight >> 4;
            }
        }
    }
    
    return data;
}

@end
