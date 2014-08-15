//
//  ZSSRichTextEditorViewController.h
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRColorPickerViewController.h"

/**
 *  The types of toolbar items that can be added
 */
typedef NS_ENUM(NSInteger, ZSSRichTextEditorToolbar) {
    ZSSRichTextEditorToolbarBold = 1,
    ZSSRichTextEditorToolbarItalic = 1 << 0,
    ZSSRichTextEditorToolbarSubscript = 1 << 1,
    ZSSRichTextEditorToolbarSuperscript = 1 << 2,
    ZSSRichTextEditorToolbarStrikeThrough = 1 << 3,
    ZSSRichTextEditorToolbarUnderline = 1 << 4,
    ZSSRichTextEditorToolbarRemoveFormat = 1 << 5,
    ZSSRichTextEditorToolbarJustifyLeft = 1 << 6,
    ZSSRichTextEditorToolbarJustifyCenter = 1 << 7,
    ZSSRichTextEditorToolbarJustifyRight = 1 << 8,
    ZSSRichTextEditorToolbarJustifyFull = 1 << 9,
    ZSSRichTextEditorToolbarH1 = 1 << 10,
    ZSSRichTextEditorToolbarH2 = 1 << 11,
    ZSSRichTextEditorToolbarH3 = 1 << 12,
    ZSSRichTextEditorToolbarH4 = 1 << 13,
    ZSSRichTextEditorToolbarH5 = 1 << 14,
    ZSSRichTextEditorToolbarH6 = 1 << 15,
    ZSSRichTextEditorToolbarTextColor = 1 << 16,
    ZSSRichTextEditorToolbarBackgroundColor = 1 << 17,
    ZSSRichTextEditorToolbarUnorderedList = 1 << 18,
    ZSSRichTextEditorToolbarOrderedList = 1 << 19,
    ZSSRichTextEditorToolbarHorizontalRule = 1 << 20,
    ZSSRichTextEditorToolbarIndent = 1 << 21,
    ZSSRichTextEditorToolbarOutdent = 1 << 22,
    ZSSRichTextEditorToolbarInsertImage = 1 << 23,
    ZSSRichTextEditorToolbarInsertLink = 1 << 24,
    ZSSRichTextEditorToolbarRemoveLink = 1 << 25,
    ZSSRichTextEditorToolbarQuickLink = 1 << 26,
    ZSSRichTextEditorToolbarUndo = 1 << 27,
    ZSSRichTextEditorToolbarRedo = 1 << 28,
    ZSSRichTextEditorToolbarViewSource = 1 << 29,
    ZSSRichTextEditorToolbarAll = 1 << 30,
    ZSSRichTextEditorToolbarNone = 1 << 31,
    ZSSRichTextEditorToolbarParagraph = 1 << 32,
};

@class ZSSBarButtonItem;

/**
 *  The viewController used with ZSSRichTextEditor
 */
@interface ZSSRichTextEditor : UIViewController <UIWebViewDelegate, HRColorPickerViewControllerDelegate, UITextViewDelegate>


/**
 *  The base URL to use for the webView
 */
@property (nonatomic, strong) NSURL *baseURL;

/**
 *  If the HTML should be formatted to be pretty
 */
@property (nonatomic) BOOL formatHTML;

/**
 *  If the keyboard should be shown when the editor loads
 */
@property (nonatomic) BOOL shouldShowKeyboard;

/**
 *  Toolbar items to include
 */
@property (nonatomic) ZSSRichTextEditorToolbar enabledToolbarItems;

/**
 *  Color to tint the toolbar items
 */
@property (nonatomic, strong) UIColor *toolbarItemTintColor;

/**
 *  Color to tint selected items
 */
@property (nonatomic, strong) UIColor *toolbarItemSelectedTintColor;

/**
 *  Sets the HTML for the entire editor
 *
 *  @param html  HTML string to set for the editor
 *
 */
- (void)setHTML:(NSString *)html;

/**
 *  Returns the HTML from the Rich Text Editor
 *
 */
- (NSString *)getHTML;

/**
 *  Inserts HTML at the caret position
 *
 *  @param html  HTML string to insert
 *
 */
- (void)insertHTML:(NSString *)html;

/**
 *  Manually focuses on the text editor
 */
- (void)focusTextEditor;

/**
 *  Manually dismisses on the text editor
 */
- (void)blurTextEditor;

/**
 *  Shows the insert image dialog with optinal inputs
 *
 *  @param url The URL for the image
 *  @param alt The alt for the image
 */
- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt;

/**
 *  Inserts an image
 *
 *  @param url The URL for the image
 *  @param alt The alt attribute for the image
 */
- (void)insertImage:(NSString *)url alt:(NSString *)alt;

/**
 *  Shows the insert link dialog with optional inputs
 *
 *  @param url   The URL for the link
 *  @param title The tile for the link
 */
- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title;

/**
 *  Inserts a link
 *
 *  @param url The URL for the link
 *  @param title The title for the link
 */
- (void)insertLink:(NSString *)url title:(NSString *)title;

/**
 *  Gets called when the insert URL picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertURLAlternatePicker;

/**
 *  Gets called when the insert Image picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertImageAlternatePicker;

/**
 *  Dismisses the current AlertView
 */
- (void)dismissAlertView;

/**
 *  Add a custom UIBarButtonItem
 */
- (void)addCustomToolbarItemWithButton:(UIButton*)button;

@end
