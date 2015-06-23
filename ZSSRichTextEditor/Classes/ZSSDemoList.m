//
//  ZSSDemoList.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 8/12/14.
//  Copyright (c) 2014 Zed Said Studio. All rights reserved.
//

#import "ZSSDemoList.h"
#import "ZSSDemoViewController.h"
#import "ZSSColorViewController.h"
#import "ZSSLargeViewController.h"
#import "ZSSPlaceholderViewController.h"
#import "ZSSSelectiveViewController.h"
#import "ZSSCustomButtonsViewController.h"

@interface ZSSDemoList ()
@property (nonatomic) BOOL isIPad;
@end

@implementation ZSSDemoList

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"ZSSRichTextEditor Demo";
    
    self.isIPad = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad );
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //if (self.isIPad) return 6;
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellID = @"Cell Identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Standard";
        cell.detailTextLabel.text = @"Default implementation";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Toolbar Colors";
        cell.detailTextLabel.text = @"Custom button and selected button colors";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Selective Buttons";
        cell.detailTextLabel.text = @"Pick and choose the features you want";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Custom Buttons";
        cell.detailTextLabel.text = @"Add your own customized toolbar button";
    } else if (indexPath.row == 4) {
        cell.textLabel.text = @"Large";
        cell.detailTextLabel.text = @"A large amount of content in the editor";
    } else if (indexPath.row == 5) {
        cell.textLabel.text = @"iPad Form Style Modal";
        cell.detailTextLabel.text = @"Shows a form style modal on the iPad";
    }
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        ZSSDemoViewController *demo1 = [[ZSSDemoViewController alloc] init];
        [self.navigationController pushViewController:demo1 animated:YES];
    } else if (indexPath.row == 1) {
        ZSSColorViewController *demo2 = [[ZSSColorViewController alloc] init];
        [self.navigationController pushViewController:demo2 animated:YES];
    } else if (indexPath.row == 2) {
        ZSSSelectiveViewController *demo3 = [[ZSSSelectiveViewController alloc] init];
        [self.navigationController pushViewController:demo3 animated:YES];
    } else if (indexPath.row == 3) {
        ZSSCustomButtonsViewController *demo4 = [[ZSSCustomButtonsViewController alloc] init];
        [self.navigationController pushViewController:demo4 animated:YES];
    } else if (indexPath.row == 4) {
        ZSSLargeViewController *demo5 = [[ZSSLargeViewController alloc] init];
        [self.navigationController pushViewController:demo5 animated:YES];
    } else if (indexPath.row == 5) {
        ZSSDemoViewController *demo1 = [[ZSSDemoViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:demo1];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nav animated:YES completion:nil];
    }
    
}

@end
