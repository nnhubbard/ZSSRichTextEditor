ZSSRichTextEditor
=============

`ZSSRichTextEditor` is a beautiful Rich Text `WYSIWYG Editor` for `iOS`. It includes all of the standard editor tools one would expect from a `WYSIWYG` editor as well as an amazing source view with syntax highlighting.

![Toolbar](http://f.cl.ly/items/0L3c0N3u142Q2S0v1Y0o/demo1.gif "Toolbar")

Using the Editor
---

The editor is used how any other text input area in iOS is used. A selection of text or content is made, then tapping on the toolbar item below will apply that style. A Source View is also included, you can make changes and this will be reflected in the editor preview.

![Editor](http://cl.ly/image/3i41403g200B/demo.gif "Editor")

Colors
---

We wanted to have a really beautiful color picker to make changing colors really simple. So, we used the open-source HRColorPicker which was exactly what we were looking for. Choosing colors for text or background is simple and seamless.

![Colors](http://f.cl.ly/items/3D1k3v1E2L0g2z2j3b1M/demo3.gif "Colors")

How It Works
---

Just subclass `ZSSRichTextEditor` and use the following:

```objective-c
// HTML Content to set in the editor
NSString *html = @"<!-- This is an HTML comment -->"
"<p>This is a test of the <strong>ZSSRichTextEditor</strong> by <a title=\"Zed Said\" href=\"http://www.zedsaid.com\">Zed Said Studio</a></p>";

// Set the base URL if you would like to use relative links, such as to images.
self.baseURL = [NSURL URLWithString:@"http://www.zedsaid.com"];

// If you want to pretty print HTML within the source view.
self.formatHTML = YES;

// set the initial HTML for the editor
[self setHTML:html];
```

If you want to retrieve the HTML from the editor:
```objective-c
// Returns an NSString
[self getHTML];
```

Insert HTML at the current caret position:
```objective-c
NSString *html = @"<strong>I love cats!</strong>";
[self insertHTML:html];
```

Change the tint color of the toolbar buttons:
```objective-c
// Set the toolbar item color
self.toolbarItemTintColor = [UIColor greenColor];

// Set the toolbar selected color
self.toolbarItemSelectedTintColor = [UIColor redColor];
```

Show only specified buttons in the toolbar:
```objective-c
self.enabledToolbarItems = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarH1, ZSSRichTextEditorToolbarParagraph];
```

Insert Link and Insert Image
---

If you want to manually insert a link or image where the cursor is, you can use the following methods:

**Insert Image**
```objective-c
- (void)insertImage:(NSString *)url alt:(NSString *)alt;
```

**Insert Link**
```objective-c
- (void)insertLink:(NSString *)url title:(NSString *)title;
```

Custom Pickers
---

You can implement your own pickers for images and links if you have an alternate method that you are wanting to use. E.g., uploading an image from your camera roll then inserting the URL.

When the alternate picker icon (crosshair) is tapped it will call the corresponding method, which you need to override in your `ZSSRichTextEditor` subclass (see example project):

```objective-c
- (void)showInsertURLAlternatePicker {
    
    [self dismissAlertView];
    
    // Show your custom picker
    
}


- (void)showInsertImageAlternatePicker {
    
    [self dismissAlertView];
    
    // Show your custom picker
    
}
```

Custom Toolbar Buttons
---

```objective-c
UIButton *myButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, buttonWidth, 28.0f)];
[myButton setTitle:@"My Button" forState:UIControlStateNormal];
[myButton addTarget:self
             action:@selector(didTapCustomToolbarButton:)
   forControlEvents:UIControlEventTouchUpInside];

[self addCustomToolbarItemWithButton:myButton];

```

Supported Functions
---

ZSSRichTextEditor has the following functions:

*   Bold
*   Italic
*   Subscript
*   Superscript
*   Strikethrough
*   Underline
*   Remove Formatting
*   Justify Left
*   Justify Center
*   Justify Right
*   Justify Full
*   Paragraph
*   Heading 1
*   Heading 2
*   Heading 3
*   Heading 4
*   Heading 5
*   Heading 6
*   Undo
*   Redo
*   Unordered List
*   Ordered List
*   Indent
*   Outdent
*   Insert Image
*   Insert Link
*   Quick Link
*   Unlink
*   Horizontal Rule
*   View Source
*   Text Color
*   Background Color

Requirements
--------------
`ZSSRichTextEditor` requires iOS7 as well as `CoreGraphics.framework` and `CoreText.framework`.

**When using `ZSSRichTextEditor` in your own project, XCode will automatically add `ZSSRichTextEditor.js` to compile sources under build phases, this will cause `ZSSRichTextEditor` to not work correctly as the javascript file won't be included in your app. Instead, remove it from compile sources and add it to copy bundle resources.**

Attribution
--------------

`ZSSRichTextEditor` uses portions of code from the following sources:

| Component     | Description   | License  |
| :------------- |:-------------| :-----|
| [CYRTextView](https://github.com/illyabusigin/CYRTextView)      | CYRTextView is a UITextView subclass that implements a variety of features that are relevant to a syntax or code text view. | [MIT](https://github.com/illyabusigin/CYRTextView/blob/master/LICENSE) |
| [HRColorPicker](https://github.com/hayashi311/Color-Picker-for-iOS)      | Simple color picker for iPhone      |   [BSD](https://github.com/hayashi311/Color-Picker-for-iOS/blob/master/ColorPicker/HRColorPickerView.h) |
| [jQuery](https://jquery.com)      | jQuery is a fast, small, and feature-rich JavaScript library.      |   [MIT](http://jquery.org/license) |
| [JS Beautifier](https://github.com/einars/js-beautify)      | Makes ugly Javascript pretty      |   [MIT](https://github.com/einars/js-beautify/blob/master/LICENSE) |

Contact
--------------
Visit us online at [http://www.zedsaid.com](http://www.zedsaid.com) or [@zedsaid](https://twitter.com/zedsaid).
