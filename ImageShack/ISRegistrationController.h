#import <Cocoa/Cocoa.h>

@interface ISRegistrationController : NSWindowController 
{
	//login code
	IBOutlet NSWindow *mRegPanel;
	IBOutlet NSButton *mNewAccount;
	IBOutlet NSTextField *mRegCodeView;
	IBOutlet NSSecureTextField *mPasswordView;
	IBOutlet NSTextField *mUserView;
	IBOutlet NSMatrix *mRadio;
	IBOutlet NSButton *mSaveKeychain;
}
- (void)dealloc;

- (void)windowDidLoad;
- (IBAction)cancelLoginSheet:(id)sender;
- (IBAction)createNewAccount:(id)sender;
- (IBAction)clickOnSign:(id)sender;
- (IBAction)clickRadio:(id)sender;
- (IBAction)clickRememberInKeychain:(id)sender;

- (NSString*)getUserID;
- (NSString*)parseUserID;

- (BOOL)loginByRegCode;
- (BOOL)loginByUserPassword;

- (void)controlTextDidEndEditing:(NSNotification *)notification;
@end
