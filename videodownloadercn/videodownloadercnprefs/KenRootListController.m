#include "KenRootListController.h"
#include <spawn.h>

//system函数执行命令的替换方法
extern char **environ;
void run_cmd(char *cmd)
{
	pid_t pid;
	char *argv[] = {"sh", "-c", cmd, NULL};
	int status;

	status = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, environ);
	if (status == 0)
	{
		if (waitpid(pid, &status, 0) == -1)
		{
			perror("waitpid");
		}
	}
}

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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://kinkenyuen.top"]];
}

-(void)killSpringBoard {
	// system("killall SpringBoard");
	run_cmd("killall -9 SpringBoard");
}

- (void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/kinkenyuen?locale.x=zh_XC"]];
}

- (void)donateViaAlipay {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://qr.alipay.com/fkx09489hyqmmiun6rns211"]];
}

@end
