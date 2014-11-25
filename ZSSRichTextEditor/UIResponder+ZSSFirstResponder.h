// taken from
// http://stackoverflow.com/a/14135456/354018
// http://stackoverflow.com/a/11768282/354018

@interface UIResponder (ZSSFirstResponder)

+ (void)zss_resignFirstResponder;
+ (UIResponder *)zss_currentFirstResponder;
+ (BOOL)zss_isInResponderChain:(UIResponder *)responder;

@end
