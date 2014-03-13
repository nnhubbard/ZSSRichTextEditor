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
[self setHtml:html];
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