//
//  ZSSRichTextEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
#import "ZSSBarButtonItem.h"
#import "HRColorUtil.h"
#import "ZSSTextView.h"


@interface UIWebView (HackishAccessoryHiding)
@property (nonatomic, assign) BOOL hidesInputAccessoryView;
@end

@implementation UIWebView (HackishAccessoryHiding)

static const char * const hackishFixClassName = "UIWebBrowserViewMinusAccessoryView";
static Class hackishFixClass = Nil;

- (UIView *)hackishlyFoundBrowserView {
    UIScrollView *scrollView = self.scrollView;
    
    UIView *browserView = nil;
    for (UIView *subview in scrollView.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"UIWebBrowserView"]) {
            browserView = subview;
            break;
        }
    }
    return browserView;
}

- (id)methodReturningNil {
    return nil;
}

- (void)ensureHackishSubclassExistsOfBrowserViewClass:(Class)browserViewClass {
    if (!hackishFixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        IMP nilImp = [self methodForSelector:@selector(methodReturningNil)];
        class_addMethod(newClass, @selector(inputAccessoryView), nilImp, "@@:");
        objc_registerClassPair(newClass);
        
        hackishFixClass = newClass;
    }
}

- (BOOL) hidesInputAccessoryView {
    UIView *browserView = [self hackishlyFoundBrowserView];
    return [browserView class] == hackishFixClass;
}

- (void) setHidesInputAccessoryView:(BOOL)value {
    UIView *browserView = [self hackishlyFoundBrowserView];
    if (browserView == nil) {
        return;
    }
    [self ensureHackishSubclassExistsOfBrowserViewClass:[browserView class]];
	
    if (value) {
        object_setClass(browserView, hackishFixClass);
    }
    else {
        Class normalClass = objc_getClass("UIWebBrowserView");
        object_setClass(browserView, normalClass);
    }
    [browserView reloadInputViews];
}

@end

@interface ZSSRichTextEditor ()
@property (nonatomic, strong) UIScrollView *toolBarScroll;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *toolbarHolder;
@property (nonatomic, strong) NSString *htmlString;
@property (nonatomic, strong) UIWebView *editorView;
@property (nonatomic, strong) ZSSTextView *sourceView;
@property (nonatomic) CGRect editorViewFrame;
@property (nonatomic) BOOL resourcesLoaded;
@property (nonatomic, strong) NSArray *editorItemsEnabled;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSString *selectedLinkURL;
@property (nonatomic, strong) NSString *selectedLinkTitle;
@property (nonatomic, strong) NSString *selectedImageURL;
@property (nonatomic, strong) NSString *selectedImageAlt;
@property (nonatomic, strong) UIBarButtonItem *keyboardItem;
@property (nonatomic, strong) NSMutableArray *customBarButtonItems;
@property (nonatomic, strong) NSMutableArray *customZSSBarButtonItems;
@property (nonatomic, strong) NSString *internalHTML;
@property (nonatomic) BOOL editorLoaded;
- (NSString *)removeQuotesFromHTML:(NSString *)html;
- (NSString *)tidyHTML:(NSString *)html;
- (void)enableToolbarItems:(BOOL)enable;
- (BOOL)isIpad;
@end

@implementation ZSSRichTextEditor

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editorLoaded = NO;
    self.shouldShowKeyboard = YES;
    self.formatHTML = YES;
    
    // Source View
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.sourceView = [[ZSSTextView alloc] initWithFrame:frame];
    self.sourceView.hidden = YES;
    self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceView.font = [UIFont fontWithName:@"Courier" size:13.0];
    self.sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.sourceView.autoresizesSubviews = YES;
    self.sourceView.delegate = self;
    [self.view addSubview:self.sourceView];
    
    // Editor View
    self.editorView = [[UIWebView alloc] initWithFrame:frame];
    self.editorView.delegate = self;
    self.editorView.hidesInputAccessoryView = YES;
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    self.editorView.scalesPageToFit = YES;
    self.editorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.editorView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.editorView.scrollView.bounces = NO;
    self.editorView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.editorView];
    
    // Scrolling View
    self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self isIpad] ? self.view.frame.size.width : self.view.frame.size.width - 44, 44)];
    self.toolBarScroll.backgroundColor = [UIColor clearColor];
    self.toolBarScroll.showsHorizontalScrollIndicator = NO;
    
    // Toolbar with icons
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.toolbar.backgroundColor = [UIColor clearColor];
    [self.toolBarScroll addSubview:self.toolbar];
    self.toolBarScroll.autoresizingMask = self.toolbar.autoresizingMask;
    
    // Background Toolbar
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Parent holding view
    self.toolbarHolder = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44)];
    self.toolbarHolder.autoresizingMask = self.toolbar.autoresizingMask;
    [self.toolbarHolder addSubview:self.toolBarScroll];
    [self.toolbarHolder insertSubview:backgroundToolbar atIndex:0];
    
    // Hide Keyboard
    if (![self isIpad]) {
        
        // Toolbar holder used to crop and position toolbar
        UIView *toolbarCropper = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44, 0, 44, 44)];
        toolbarCropper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        toolbarCropper.clipsToBounds = YES;
        
        // Use a toolbar so that we can tint
        UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(-7, -1, 44, 44)];
        [toolbarCropper addSubview:keyboardToolbar];
        
        self.keyboardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSkeyboard.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard)];
        keyboardToolbar.items = @[self.keyboardItem];
        [self.toolbarHolder addSubview:toolbarCropper];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.6f, 44)];
        line.backgroundColor = [UIColor lightGrayColor];
        line.alpha = 0.7f;
        [toolbarCropper addSubview:line];
    }
    [self.view addSubview:self.toolbarHolder];
    
    // Build the toolbar
    [self buildToolbar];
    
    if (!self.resourcesLoaded) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"editor" ofType:@"html"];
        NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
        NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
        NSString *source = [[NSBundle mainBundle] pathForResource:@"ZSSRichTextEditor" ofType:@"js"];
        NSString *jsString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:source] encoding:NSUTF8StringEncoding];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--editor-->" withString:jsString];
        
        [self.editorView loadHTMLString:htmlString baseURL:self.baseURL];
        self.resourcesLoaded = YES;
    }

}


- (void)setEnabledToolbarItems:(ZSSRichTextEditorToolbar)enabledToolbarItems {
    
    _enabledToolbarItems = enabledToolbarItems;
    [self buildToolbar];
    
}


- (void)setToolbarItemTintColor:(UIColor *)toolbarItemTintColor {
    
    _toolbarItemTintColor = toolbarItemTintColor;
    
    // Update the color
    for (ZSSBarButtonItem *item in self.toolbar.items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    self.keyboardItem.tintColor = toolbarItemTintColor;
    
}


- (void)setToolbarItemSelectedTintColor:(UIColor *)toolbarItemSelectedTintColor {
    
    _toolbarItemSelectedTintColor = toolbarItemSelectedTintColor;
    
}


- (void)setPlaceholderText {
    
    NSString *js = [NSString stringWithFormat:@"zss_editor.setPlaceholder(\"%@\");", self.placeholder];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
}

- (void)setFooterHeight:(float)footerHeight {

    NSString *js = [NSString stringWithFormat:@"zss_editor.setFooterHeight(\"%f\");", footerHeight];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setContentHeight:(float)contentHeight {
    
    NSString *js = [NSString stringWithFormat:@"zss_editor.contentHeight = %f;", contentHeight];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}


- (NSArray *)itemsForToolbar {
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    // None
    if(_enabledToolbarItems & ZSSRichTextEditorToolbarNone)
    {
        return items;
    }
    
    // Bold
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarBold || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *bold = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSbold.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setBold)];
        bold.label = @"bold";
        [items addObject:bold];
        
    }
    
    // Italic
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarItalic || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *italic = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSitalic.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setItalic)];
        italic.label = @"italic";
        [items addObject:italic];
    }
    
    // Subscript
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarSubscript || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *subscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsubscript.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setSubscript)];
        subscript.label = @"subscript";
        [items addObject:subscript];
    }
    
    // Superscript
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarSuperscript || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *superscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsuperscript.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setSuperscript)];
        superscript.label = @"superscript";
        [items addObject:superscript];
    }
    
    // Strike Through
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarStrikeThrough || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *strikeThrough = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSstrikethrough.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setStrikethrough)];
        strikeThrough.label = @"strikeThrough";
        [items addObject:strikeThrough];
    }
    
    // Underline
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarUnderline || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *underline = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunderline.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setUnderline)];
        underline.label = @"underline";
        [items addObject:underline];
    }
    
    // Remove Format
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarRemoveFormat || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *removeFormat = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSclearstyle.png"] style:UIBarButtonItemStylePlain target:self action:@selector(removeFormat)];
        removeFormat.label = @"removeFormat";
        [items addObject:removeFormat];
    }
    
    // Undo
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarUndo || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *undoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSundo.png"] style:UIBarButtonItemStylePlain target:self action:@selector(undo:)];
        undoButton.label = @"undo";
        [items addObject:undoButton];
    }
    
    // Redo
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarRedo || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *redoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSredo.png"] style:UIBarButtonItemStylePlain target:self action:@selector(redo:)];
        redoButton.label = @"redo";
        [items addObject:redoButton];
    }
    
    // Align Left
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarJustifyLeft || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *alignLeft = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSleftjustify.png"] style:UIBarButtonItemStylePlain target:self action:@selector(alignLeft)];
        alignLeft.label = @"justifyLeft";
        [items addObject:alignLeft];
    }
    
    // Align Center
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarJustifyCenter || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *alignCenter = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSScenterjustify.png"] style:UIBarButtonItemStylePlain target:self action:@selector(alignCenter)];
        alignCenter.label = @"justifyCenter";
        [items addObject:alignCenter];
    }
    
    // Align Right
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarJustifyRight || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *alignRight = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSrightjustify.png"] style:UIBarButtonItemStylePlain target:self action:@selector(alignRight)];
        alignRight.label = @"justifyRight";
        [items addObject:alignRight];
    }
    
    // Align Justify
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarJustifyFull || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *alignFull = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSforcejustify.png"] style:UIBarButtonItemStylePlain target:self action:@selector(alignFull)];
        alignFull.label = @"justifyFull";
        [items addObject:alignFull];
    }
    
    // Paragraph
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarParagraph || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *paragraph = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSparagraph.png"] style:UIBarButtonItemStylePlain target:self action:@selector(paragraph)];
        paragraph.label = @"p";
        [items addObject:paragraph];
    }
    
    // Header 1
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH1 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h1 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh1.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading1)];
        h1.label = @"h1";
        [items addObject:h1];
    }
    
    // Header 2
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH2 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h2 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh2.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading2)];
        h2.label = @"h2";
        [items addObject:h2];
    }
    
    // Header 3
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH3 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h3 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh3.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading3)];
        h3.label = @"h3";
        [items addObject:h3];
    }
    
    // Heading 4
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH4 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h4 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh4.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading4)];
        h4.label = @"h4";
        [items addObject:h4];
    }
    
    // Header 5
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH5 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h5 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh5.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading5)];
        h5.label = @"h5";
        [items addObject:h5];
    }
    
    // Heading 6
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarH6 || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *h6 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh6.png"] style:UIBarButtonItemStylePlain target:self action:@selector(heading6)];
        h6.label = @"h6";
        [items addObject:h6];
    }
    
    // Text Color
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarTextColor || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *textColor = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSStextcolor.png"] style:UIBarButtonItemStylePlain target:self action:@selector(textColor)];
        textColor.label = @"textColor";
        [items addObject:textColor];
    }
    
    // Background Color
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarBackgroundColor || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *bgColor = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSbgcolor.png"] style:UIBarButtonItemStylePlain target:self action:@selector(bgColor)];
        bgColor.label = @"backgroundColor";
        [items addObject:bgColor];
    }
    
    // Unordered List
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarUnorderedList || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *ul = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunorderedlist.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setUnorderedList)];
        ul.label = @"unorderedList";
        [items addObject:ul];
    }
    
    // Ordered List
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarOrderedList || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *ol = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSorderedlist.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setOrderedList)];
        ol.label = @"orderedList";
        [items addObject:ol];
    }
    
    // Horizontal Rule
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarHorizontalRule || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *hr = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSShorizontalrule.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setHR)];
        hr.label = @"horizontalRule";
        [items addObject:hr];
    }
    
    // Indent
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarIndent || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *indent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSindent.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setIndent)];
        indent.label = @"indent";
        [items addObject:indent];
    }
    
    // Outdent
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarOutdent || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *outdent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSoutdent.png"] style:UIBarButtonItemStylePlain target:self action:@selector(setOutdent)];
        outdent.label = @"outdent";
        [items addObject:outdent];
    }
    
    // Image
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarInsertImage || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *insertImage = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSimage.png"] style:UIBarButtonItemStylePlain target:self action:@selector(insertImage)];
        insertImage.label = @"image";
        [items addObject:insertImage];
    }
    
    // Insert Link
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarInsertLink || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *insertLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSlink.png"] style:UIBarButtonItemStylePlain target:self action:@selector(insertLink)];
        insertLink.label = @"link";
        [items addObject:insertLink];
    }
    
    // Remove Link
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarRemoveLink || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *removeLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunlink.png"] style:UIBarButtonItemStylePlain target:self action:@selector(removeLink)];
        removeLink.label = @"removeLink";
        [items addObject:removeLink];
    }
    
    // Quick Link
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarQuickLink || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *quickLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSquicklink.png"] style:UIBarButtonItemStylePlain target:self action:@selector(quickLink)];
        quickLink.label = @"quickLink";
        [items addObject:quickLink];
    }
    
    // Show Source
    if (_enabledToolbarItems & ZSSRichTextEditorToolbarViewSource || _enabledToolbarItems & ZSSRichTextEditorToolbarAll) {
        ZSSBarButtonItem *showSource = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSviewsource.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showHTMLSource:)];
        showSource.label = @"source";
        [items addObject:showSource];
    }
     
    return [NSArray arrayWithArray:items];
    
}


- (void)buildToolbar {
    
    // Check to see if we have any toolbar items, if not, add them all
    NSArray *items = [self itemsForToolbar];
    if (items.count == 0 && !(_enabledToolbarItems & ZSSRichTextEditorToolbarNone)) {
        _enabledToolbarItems = ZSSRichTextEditorToolbarAll;
        items = [self itemsForToolbar];
    }
    
    if (self.customZSSBarButtonItems != nil) {
        items = [items arrayByAddingObjectsFromArray:self.customZSSBarButtonItems];
    }
    
    // get the width before we add custom buttons
    CGFloat toolbarWidth = items.count == 0 ? 0.0f : (CGFloat)(items.count * 39) - 10;
    
    if(self.customBarButtonItems != nil)
    {
        items = [items arrayByAddingObjectsFromArray:self.customBarButtonItems];
        for(ZSSBarButtonItem *buttonItem in self.customBarButtonItems)
        {
            toolbarWidth += buttonItem.customView.frame.size.width + 11.0f;
        }
    }
    
    self.toolbar.items = items;
    for (ZSSBarButtonItem *item in items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    
    self.toolbar.frame = CGRectMake(0, 0, toolbarWidth, 44);
    self.toolBarScroll.contentSize = CGSizeMake(self.toolbar.frame.size.width, 44);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Editor Interaction

- (void)focusTextEditor {
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"zss_editor.focusEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)blurTextEditor {
    NSString *js = [NSString stringWithFormat:@"zss_editor.blurEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setHTML:(NSString *)html {
    
    self.internalHTML = html;
    
    if (self.editorLoaded) {
        [self updateHTML];
    }
    
}

- (void)updateHTML {
    
    NSString *html = self.internalHTML;
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:self.sourceView.text];
	NSString *trigger = [NSString stringWithFormat:@"zss_editor.setHTML(\"%@\");", cleanedHTML];
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (NSString *)getHTML {
    NSString *html = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getHTML();"];
    html = [self removeQuotesFromHTML:html];
    html = [self tidyHTML:html];
	return html;
}


- (void)insertHTML:(NSString *)html {
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
	NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (NSString *)getText {
    return [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getText();"];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)showHTMLSource:(ZSSBarButtonItem *)barButtonItem {
    if (self.sourceView.hidden) {
        self.sourceView.text = [self getHTML];
        self.sourceView.hidden = NO;
        barButtonItem.tintColor = [UIColor blackColor];
        self.editorView.hidden = YES;
        [self enableToolbarItems:NO];
    } else {
        [self setHTML:self.sourceView.text];
        barButtonItem.tintColor = [self barButtonItemDefaultColor];
        self.sourceView.hidden = YES;
        self.editorView.hidden = NO;
        [self enableToolbarItems:YES];
    }
}

- (void)removeFormat {
    NSString *trigger = @"zss_editor.removeFormating();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignLeft {
    NSString *trigger = @"zss_editor.setJustifyLeft();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignCenter {
    NSString *trigger = @"zss_editor.setJustifyCenter();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignRight {
    NSString *trigger = @"zss_editor.setJustifyRight();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignFull {
    NSString *trigger = @"zss_editor.setJustifyFull();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setBold {
    NSString *trigger = @"zss_editor.setBold();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setItalic {
    NSString *trigger = @"zss_editor.setItalic();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSubscript {
    NSString *trigger = @"zss_editor.setSubscript();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnderline {
    NSString *trigger = @"zss_editor.setUnderline();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSuperscript {
    NSString *trigger = @"zss_editor.setSuperscript();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setStrikethrough {
    NSString *trigger = @"zss_editor.setStrikeThrough();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnorderedList {
    NSString *trigger = @"zss_editor.setUnorderedList();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOrderedList {
    NSString *trigger = @"zss_editor.setOrderedList();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setHR {
    NSString *trigger = @"zss_editor.setHorizontalRule();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setIndent {
    NSString *trigger = @"zss_editor.setIndent();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOutdent {
    NSString *trigger = @"zss_editor.setOutdent();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading1 {
    NSString *trigger = @"zss_editor.setHeading('h1');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading2 {
    NSString *trigger = @"zss_editor.setHeading('h2');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading3 {
    NSString *trigger = @"zss_editor.setHeading('h3');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading4 {
    NSString *trigger = @"zss_editor.setHeading('h4');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading5 {
    NSString *trigger = @"zss_editor.setHeading('h5');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading6 {
    NSString *trigger = @"zss_editor.setHeading('h6');";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)paragraph {
    NSString *trigger = @"zss_editor.setParagraph();";
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)textColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 1;
    colorPicker.title = NSLocalizedString(@"Text Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)bgColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 2;
    colorPicker.title = NSLocalizedString(@"BG Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)setSelectedColor:(UIColor*)color tag:(int)tag {
   
    NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
    NSString *trigger;
    if (tag == 1) {
        trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
    } else if (tag == 2) {
        trigger = [NSString stringWithFormat:@"zss_editor.setBackgroundColor(\"%@\");", hex];
    }
	[self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (void)undo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.undo();"];
}

- (void)redo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.redo();"];
}

- (void)insertLink {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Show the dialog for inserting or editing a link
    [self showInsertLinkDialogWithLink:self.selectedLinkURL title:self.selectedLinkTitle];
    
}


- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedLinkURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
    self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    self.alertView.tag = 2;
    UITextField *linkURL = [self.alertView textFieldAtIndex:0];
    linkURL.placeholder = NSLocalizedString(@"URL (required)", nil);
    if (url) {
        linkURL.text = url;
    }
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png"] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertURLAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    linkURL.rightView = am;
    linkURL.rightViewMode = UITextFieldViewModeAlways;
    
    UITextField *alt = [self.alertView textFieldAtIndex:1];
    alt.secureTextEntry = NO;
    alt.placeholder = NSLocalizedString(@"Title", nil);
    if (title) {
        alt.text = title;
    }
    
    [self.alertView show];
    
}


- (void)insertLink:(NSString *)url title:(NSString *)title {
    
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}


- (void)updateLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)dismissAlertView {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
}

- (void)addCustomToolbarItemWithButton:(UIButton *)button
{
    if(self.customBarButtonItems == nil)
    {
        self.customBarButtonItems = [NSMutableArray array];
    }
    
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28.5f];
    [button setTitleColor:[self barButtonItemDefaultColor] forState:UIControlStateNormal];
    [button setTitleColor:[self barButtonItemSelectedDefaultColor] forState:UIControlStateHighlighted];
    
    ZSSBarButtonItem *barButtonItem = [[ZSSBarButtonItem alloc] initWithCustomView:button];
    
    [self.customBarButtonItems addObject:barButtonItem];
    
    [self buildToolbar];
}

- (void)addCustomToolbarItem:(ZSSBarButtonItem *)item {
    
    if(self.customZSSBarButtonItems == nil)
    {
        self.customZSSBarButtonItems = [NSMutableArray array];
    }
    [self.customZSSBarButtonItems addObject:item];
    
    [self buildToolbar];
}


- (void)removeLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.unlink();"];
}//end

- (void)quickLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.quickLink();"];
}

- (void)insertImage {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    [self showInsertImageDialogWithLink:self.selectedImageURL alt:self.selectedImageAlt];
    
}

- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
    self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    self.alertView.tag = 1;
    UITextField *imageURL = [self.alertView textFieldAtIndex:0];
    imageURL.placeholder = NSLocalizedString(@"URL (required)", nil);
    if (url) {
        imageURL.text = url;
    }
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png"] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertImageAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    imageURL.rightView = am;
    imageURL.rightViewMode = UITextFieldViewModeAlways;
    imageURL.clearButtonMode = UITextFieldViewModeAlways;
    
    UITextField *alt1 = [self.alertView textFieldAtIndex:1];
    alt1.secureTextEntry = NO;
    UIView *test = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    test.backgroundColor = [UIColor redColor];
    alt1.rightView = test;
    alt1.placeholder = NSLocalizedString(@"Alt", nil);
    alt1.clearButtonMode = UITextFieldViewModeAlways;
    if (alt) {
        alt1.text = alt;
    }
    
    [self.alertView show];
    
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateToolBarWithButtonName:(NSString *)name {
    
    // Items that are enabled
    NSArray *itemNames = [name componentsSeparatedByString:@","];
    
    // Special case for link
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
    for (NSString *linkItem in itemNames) {
        NSString *updatedItem = linkItem;
        if ([linkItem hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [linkItem stringByReplacingOccurrencesOfString:@"link:" withString:@""];
        } else if ([linkItem hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([linkItem hasPrefix:@"image:"]) {
            updatedItem = @"image";
            self.selectedImageURL = [linkItem stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([linkItem hasPrefix:@"image-alt:"]) {
            self.selectedImageAlt = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        } else {
            self.selectedImageURL = nil;
            self.selectedImageAlt = nil;
            self.selectedLinkURL = nil;
            self.selectedLinkTitle = nil;
        }
        [itemsModified addObject:updatedItem];
    }
    itemNames = [NSArray arrayWithArray:itemsModified];
   
    self.editorItemsEnabled = itemNames;
    
    // Highlight items
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if ([itemNames containsObject:item.label]) {
            item.tintColor = [self barButtonItemSelectedDefaultColor];
        } else {
            item.tintColor = [self barButtonItemDefaultColor];
        }
    }//end
    
}
    

#pragma mark - UITextView Delegate
    
- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}


#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *urlString = [[request URL] absoluteString];
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		return NO;
	} else if ([urlString rangeOfString:@"callback://"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"callback://" withString:@""];
        [self updateToolBarWithButtonName:className];
        
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
        
    } else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        
        NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        [self editorDidScrollWithPosition:position];
        
    }
    
    return YES;
    
}//end


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.editorLoaded = YES;
    //[self setPlaceholderText];
    if (!self.internalHTML) {
        self.internalHTML = @"";
    }
    [self updateHTML];
    if (self.shouldShowKeyboard) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self focusTextEditor];
        });
    }
}


#pragma mark - Callbacks

// Blank implementation
- (void)editorDidScrollWithPosition:(NSInteger)position {
    
    
}


#pragma mark - AlertView

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if (alertView.tag == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        if ([textField.text length] == 0 || [textField2.text length] == 0) {
            return NO;
        }
    } else if (alertView.tag == 2) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0) {
            return NO;
        }
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            UITextField *imageURL = [alertView textFieldAtIndex:0];
            UITextField *alt = [alertView textFieldAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            UITextField *linkURL = [alertView textFieldAtIndex:0];
            UITextField *title = [alertView textFieldAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
        }
    }
    
}


#pragma mark - Asset Picker

- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}


- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}


#pragma mark - Keyboard status

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // convert from screen coordinates to self.view coordinates, as the bottom of self.view might not be at the bottom of the view
    // also rotates the coordinates correctly in iOS<8
    CGRect keyboardEndInView = [self.view convertRect:keyboardEnd fromView:nil];

    // Toolbar Sizes
    CGFloat sizeOfToolbar = self.toolbarHolder.frame.size.height;
    
    // Keyboard Size
    CGFloat keyboardTopYInView = keyboardEndInView.origin.y;
    keyboardTopYInView = MAX(0, keyboardTopYInView);

    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
	if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            // Toolbar
            CGRect frame = self.toolbarHolder.frame;
            frame.origin.y = keyboardTopYInView - sizeOfToolbar;
            self.toolbarHolder.frame = frame;
            
            // Editor View
            const int extraHeight = 10;

            CGRect editorFrame = self.editorView.frame;
            editorFrame.size.height = keyboardTopYInView - sizeOfToolbar - extraHeight;
            self.editorView.frame = editorFrame;
            self.editorViewFrame = self.editorView.frame;
            self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
            self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            // Source View
            CGRect sourceFrame = self.sourceView.frame;
            sourceFrame.size.height = keyboardTopYInView - sizeOfToolbar - extraHeight;
            self.sourceView.frame = sourceFrame;
            
            // Provide editor with keyboard hegiht and aditor view height
            [self setFooterHeight:(self.view.frame.size.height - keyboardTopYInView - 8)];
            [self setContentHeight: self.editorViewFrame.size.height];
            
        } completion:nil];
        
	} else {
        
		[UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            CGRect frame = self.toolbarHolder.frame;
            frame.origin.y = keyboardTopYInView;
            self.toolbarHolder.frame = frame;
            
            // Editor View
            CGRect editorFrame = self.editorView.frame;
            editorFrame.size.height = self.view.frame.size.height;
            self.editorView.frame = editorFrame;
            self.editorViewFrame = self.editorView.frame;
            self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
            self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            // Source View
            CGRect sourceFrame = self.sourceView.frame;
            sourceFrame.size.height = self.view.frame.size.height;
            self.sourceView.frame = sourceFrame;
            
        } completion:nil];
        
	}//end
    
}


#pragma mark - Utilities

- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}//end


- (NSString *)tidyHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br />"];
    html = [html stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
    if (self.formatHTML) {
        html = [self.editorView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"style_html(\"%@\");", html]];
    }
    return html;
}//end


- (UIColor *)barButtonItemDefaultColor {
    
    if (self.toolbarItemTintColor) {
        return self.toolbarItemTintColor;
    }
    
    return [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}


- (UIColor *)barButtonItemSelectedDefaultColor {
    
    if (self.toolbarItemSelectedTintColor) {
        return self.toolbarItemSelectedTintColor;
    }
    
    return [UIColor blackColor];
}


- (BOOL)isIpad {
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}//end


- (NSString *)stringByDecodingURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}
    

- (void)enableToolbarItems:(BOOL)enable {
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if (![item.label isEqualToString:@"source"]) {
            item.enabled = enable;
        }
    }
}


@end
