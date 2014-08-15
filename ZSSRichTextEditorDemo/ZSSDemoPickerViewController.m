//
//  ZSSDemoPickerViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 1/30/14.
//  Copyright (c) 2014 Zed Said Studio. All rights reserved.
//

#import "ZSSDemoPickerViewController.h"


@interface ZSSDemoPickerViewController ()
@property (nonatomic, strong) UITextField *textField;
@end

@implementation ZSSDemoPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = @"Picker";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveURL)];
    self.navigationItem.rightBarButtonItem = save;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width - 40, 40)];
    self.textField.text = !self.isInsertImagePicker ? @"http://www.apple.com" : @"http://fineprintnyc.com/images/blog/history-of-apple-logo/apple-logo-2.jpg";
    self.textField.layer.borderColor = [UIColor grayColor].CGColor;
    self.textField.layer.borderWidth = 0.5f;
    self.textField.clearButtonMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.textField];
    
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveURL {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    ZSSDemoViewController *vc = self.demoView;
    if (!self.isInsertImagePicker) {
        [vc showInsertLinkDialogWithLink:self.textField.text title:nil];
    } else {
        [vc showInsertImageDialogWithLink:self.textField.text alt:nil];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
