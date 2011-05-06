#import <Cocoa/Cocoa.h>

@interface ISQuickRegisterController : NSWindowController
{
	IBOutlet NSWindow  *mWindow;
	IBOutlet NSTextField *mEmailTextView;
	IBOutlet NSTextField *mUsernameTextView;
	IBOutlet NSButton *mSignButton;
	IBOutlet NSButton *mCancelButton;	
}
-(void)dealloc;

- (IBAction)clickCancel:(id)sender;
- (IBAction)clickRegister:(id)sender;

@end
