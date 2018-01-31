//
//  JPEGImageInfo.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 17/2/14.
//  Copyright © 2017年 B_Sui. All rights reserved.
//

#import "JPEGImageInfo.h"

@interface JPEGImageInfo ()

@property (nonatomic, strong) NSMutableArray *indexOfQuantization;
@property (nonatomic, strong) NSMutableDictionary *tableOfQuantization;

@property (nonatomic, strong) NSMutableArray *indexOfHuffman;
@property (nonatomic, strong) NSMutableDictionary *tableOfHuffman;

@end

@implementation JPEGImageInfo

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

#pragma mark - quantization table

- (NSMutableArray *) indexOfQuantization
{
    if (!_indexOfQuantization)
    {
        _indexOfQuantization = [NSMutableArray array];
    }
    return _indexOfQuantization;
}

- (NSArray *) quantizationIndexs
{
    return _indexOfQuantization;
}

- (void) creatQuantizationIndex:(void (^)(JPEGQuantizationIndex *index)) comp
{
    JPEGQuantizationIndex *index = [[JPEGQuantizationIndex alloc] init];
    if (comp)
    {
        comp(index);
    }
    [self.indexOfQuantization addObject:index];
}

- (NSMutableDictionary *) tableOfQuantization
{
    if (!_tableOfQuantization)
    {
        _tableOfQuantization = [NSMutableDictionary dictionary];
    }
    return _tableOfQuantization;
}

- (NSDictionary *) quantizationTables
{
    return _tableOfQuantization;
}

- (void) creatQuantizationTable:(void (^)(JPEGQuantizationTable *table)) comp
{
    JPEGQuantizationTable *table = [[JPEGQuantizationTable alloc] init];
    if (comp)
    {
        comp(table);
    }
    [self.tableOfQuantization setObject:table forKey:@(table.tag)];
}

#pragma mark - huffman table

- (NSMutableArray *) indexOfHuffman
{
    if (!_indexOfHuffman)
    {
        _indexOfHuffman = [NSMutableArray array];
    }
    return _indexOfHuffman;
}

- (NSArray *) huffmanIndexs
{
    return _indexOfHuffman;
}

- (void) creatHuffmanIndex:(void (^)(JPEGHuffmanIndex *index)) comp
{
    JPEGHuffmanIndex *index = [[JPEGHuffmanIndex alloc] init];
    if (comp)
    {
        comp(index);
    }
    [self.indexOfHuffman addObject:index];
}

- (NSMutableDictionary *) tableOfHuffman
{
    if (!_tableOfHuffman)
    {
        _tableOfHuffman = [NSMutableDictionary dictionary];
    }
    return _tableOfHuffman;
}

- (NSDictionary *) huffmanTables
{
    return _tableOfHuffman;
}

- (void) creatHuffmanTable:(void (^)(JPEGHuffmanTable *table)) comp
{
    JPEGHuffmanTable *table = [[JPEGHuffmanTable alloc] init];
    if (comp)
    {
        comp(table);
    }
    [self.tableOfHuffman setObject:table forKey:@(table.tag)];
}

@end
