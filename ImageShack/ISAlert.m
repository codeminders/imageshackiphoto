#import "ISAlert.h"
#import "ISManager.h"

@interface ISAlert(Private)
-(void)goAway;
@end

@implementation ISAlert(Private)
-(void)goAway
{
	if (mSession!= 0)
		[NSApp endModalSession:mSession];
	
	[self close];
} 
@end

@implementation ISAlert

-(NSString *)windowNibName
{
	return @"Alert";
}

-(void)runModal
{
	mSession = 0;
	mSession = [NSApp beginModalSessionForWindow:[self window]];
}

- (IBAction)clickOnOK:(id)sender
{
	[[ISManager manager] showUploadedImages];		

	[self goAway];
}

- (IBAction)clickOnCancel:(id)sender
{
	[self goAway];
}

@end