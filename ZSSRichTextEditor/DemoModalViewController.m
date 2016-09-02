//
//  DemoModalViewController.m
//  ZSSRichTextEditor
//
//  Created by Will Swan on 02/09/2016.
//  Copyright © 2016 Zed Said Studio. All rights reserved.
//

#import "DemoModalViewController.h"

@interface DemoModalViewController ()

@end

@implementation DemoModalViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //Back Button
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 100.0f, 44.0f)];
    [button setTitle:@"Back" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

- (void)dismiss {
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
