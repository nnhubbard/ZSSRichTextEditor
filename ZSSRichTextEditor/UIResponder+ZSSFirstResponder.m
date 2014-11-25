#import "UIResponder+ZSSFirstResponder.h"


static __weak id zss_currentFirstResponder = nil;


@implementation UIResponder (ZSSFirstResponder)

+ (void)zss_resignFirstResponder {

	[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

+ (UIResponder *)zss_currentFirstResponder {

	zss_currentFirstResponder = nil;
	[[UIApplication sharedApplication] sendAction:@selector(zss_findFirstResponder) to:nil from:nil forEvent:nil];
	return zss_currentFirstResponder;
}

- (void)zss_findFirstResponder {

	zss_currentFirstResponder = self;
}

+ (BOOL)zss_isInResponderChain:(UIResponder *)responder {

	id firstResponder = [UIResponder zss_currentFirstResponder];
	return [UIResponder zss_isInResponderChain:responder responderInFirstResponderChain:firstResponder];
}

+ (BOOL)zss_isInResponderChain:(UIResponder *)responderToCheck responderInFirstResponderChain:(UIResponder *)responderInFirstResponderChain {

	if (responderInFirstResponderChain == nil) {
		return NO;
	}

	if (responderToCheck == responderInFirstResponderChain) {
		return YES;
	}

	UIResponder *nextResponder = [responderInFirstResponderChain nextResponder];
	return [UIResponder zss_isInResponderChain:responderToCheck responderInFirstResponderChain:nextResponder];
}

@end
