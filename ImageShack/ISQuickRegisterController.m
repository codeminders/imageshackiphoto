#import "ISQuickRegisterController.h"
#import "ISManager.h"

@implementation ISQuickRegisterController

-(NSString *)windowNibName
{
	return @"QuickReg";
}

- (void)dealloc
{
	[super dealloc];
}

- (IBAction)clickCancel:(id)sender
{
	[NSApp endSheet:mWindow];
}

- (IBAction)clickRegister:(id)sender
{
	[NSApp endSheet:mWindow];
	NSString *email = [mEmailTextView stringValue];
	NSString *username = [mUsernameTextView stringValue];
	[[ISManager manager] quickRegistrationWithEmail:email username:username];
}


@end
