#import <Cocoa/Cocoa.h>

@interface ISAlert : NSWindowController 
{
	IBOutlet NSButton *mOKButton;
	IBOutlet NSButton *mCancelButton;
	
	NSModalSession mSession;
}

- (IBAction)clickOnOK:(id)sender;
- (IBAction)clickOnCancel:(id)sender;

- (void)runModal;
@end
