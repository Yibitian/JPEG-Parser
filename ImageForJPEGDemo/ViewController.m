//
//  ViewController.m
//  ImageForJPEGDemo
//
//  Created by B_Sui on 16/9/8.
//  Copyright © 2016年 B_Sui. All rights reserved.
//

#import "ViewController.h"
#import "JPEGImageDataParser.h"

@interface ViewController () <JPEGImageDataParserDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imageView];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    [btn addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"start" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btn.center = self.view.center;
    [self.view addSubview:btn];
}

- (void) startButtonTouch:(UIButton *) btn
{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Space5.jpg"];
    
    NSOperationQueue *op = [[NSOperationQueue alloc] init];
    [op addOperationWithBlock:^{
        JPEGImageDataParser *parser = [[JPEGImageDataParser alloc] init];
        parser.delegate = self;
        [parser openFile:path];
    }];
}

- (void) imageMake:(UIImage *) image
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.imageView.image = image;
    }];
}

@end
