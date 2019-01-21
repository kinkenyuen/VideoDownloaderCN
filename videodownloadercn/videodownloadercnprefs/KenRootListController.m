#include "KenRootListController.h"

@implementation KenRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

/**
 插件设置中点击ButtoonCell触发的方法
 */
- (void)gotoMyPage {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.jianshu.com/u/4fcc843d9f5d/"]];
}

-(void)killSpringBoard {
	system("killall SpringBoard");
}

@end
