//
//  ZSSLargeViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 8/13/14.
//  Copyright (c) 2014 Zed Said Studio. All rights reserved.
//

#import "ZSSLargeViewController.h"

@interface ZSSLargeViewController ()

@end

@implementation ZSSLargeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Large";
    
    // HTML Content to set in the editor
    NSString *html = @"<h1>Large Editor</h1>"
    "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam at enim at nibh pulvinar sagittis eu non lacus. Quisque suscipit tempor urna vel pretium. Curabitur id enim auctor, cursus elit ac, porttitor sem. Ut suscipit purus odio, vitae sollicitudin sapien placerat in. Duis adipiscing urna id viverra tincidunt. Duis sit amet adipiscing justo, vitae facilisis ipsum. Vivamus scelerisque justo ut libero dictum, id tempor ipsum tempus. Nam nec dui dapibus, tristique dolor et, sollicitudin enim. Nullam sagittis arcu tortor, mollis porta mi laoreet ac. Proin lobortis bibendum urna, in ultrices dolor hendrerit quis. Morbi felis quam, luctus nec suscipit porttitor, lacinia vitae velit. Nulla ultricies pellentesque porta. <strong>Suspendisse suscipit sagittis metus non rhoncus</strong>.</p>"
    "<p>Phasellus adipiscing justo ipsum, eget feugiat dui elementum id. Pellentesque eu dolor eu arcu bibendum sollicitudin. <em>Aenean ac dolor non lectus laoreet semper at vel est</em>. Curabitur sit amet odio laoreet turpis mattis suscipit at sed lacus. Nunc tincidunt ipsum nulla, ac blandit leo lobortis eu. Curabitur mauris mauris, vestibulum at urna sit amet, condimentum venenatis ante. Nullam a risus nisi. Donec sit amet imperdiet mi.</p>"
    "<p>Sed in lorem luctus lorem feugiat viverra facilisis ut velit. Maecenas convallis leo purus. <strong><em>Integer vestibulum mi eget quam auctor vehicula</em></strong>. Phasellus id eleifend nunc. Mauris pretium blandit orci a accumsan. Aliquam hendrerit sit amet ligula et dignissim. Pellentesque feugiat scelerisque sapien nec scelerisque. Nunc ac placerat lectus. Proin sed dolor in leo congue facilisis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Pellentesque arcu velit, tempus sit amet elit at, aliquet iaculis dolor. Nam eget sollicitudin libero. Mauris dignissim, risus sit amet tempor tempus, risus mauris faucibus massa, sed elementum mauris turpis et arcu.</p>"
    "<p>Aliquam mattis libero arcu, <strong>a ultrices risus mattis sed</strong>. Vivamus facilisis consectetur ipsum at volutpat. Duis eget lorem sodales, congue libero dapibus, dignissim odio. Vivamus hendrerit ante at metus feugiat fringilla. Quisque imperdiet magna in tristique sagittis. Nulla neque turpis, tempus a leo eget, auctor interdum dui. In porta mi non libero lacinia pulvinar. Nunc a augue eget est malesuada eleifend a et orci. Aenean in tempus purus. Curabitur auctor viverra massa. Proin in justo pretium lacus pretium ullamcorper. Morbi elementum leo nibh, quis sodales nibh scelerisque ut.</p>"
    "<p>Mauris sed consequat augue. <strong>Aliquam accumsan erat lacus</strong>, consequat volutpat augue imperdiet vitae. Sed tempus dui quis faucibus tempor. Aliquam ultricies in turpis et vehicula. Suspendisse potenti. Duis iaculis rhoncus enim sed tempus. Cras non metus sed erat accumsan gravida vitae in lacus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Integer vel cursus ligula, a auctor lacus. In rhoncus massa <em>varius sagittis ultrices</em>. Donec aliquam, nisl sit amet hendrerit pretium, lorem quam mollis purus, ac interdum elit mi et neque. Etiam porta rutrum lacinia. Nullam nec vestibulum ligula. Nam nec ipsum odio. Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>";
    
    // Set the HTML contents of the editor
    [self setHTML:html];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
