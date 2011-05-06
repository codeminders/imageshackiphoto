#import "ISRegistrationController.h"
#import "ISManager.h"
#import "ISConstants.h"
#import "Utilities.h"

@implementation ISRegistrationController

-(NSString *)windowNibName
{
	return @"Registration";
}

- (void)windowDidLoad
{
	NSString *userID = [self getUserID];
	if (userID)
	{
		[mRegCodeView setStringValue:userID];
	}
	
	NSString *lastLogin = [[ISManager manager] getLastLogin];
	if (lastLogin)
	{
		NSString *password = [[ISManager manager] passwordForAccount:lastLogin];
		if (password)
		{
			[mUserView setStringValue:lastLogin];
			[mPasswordView setStringValue:password];
		}
	}
	
	BOOL isRemember = [[ISManager manager] isRememberInKeychain];
	[mSaveKeychain setIntValue:isRemember];
}

- (void)dealloc
{
	[super dealloc];
}

- (IBAction)cancelLoginSheet:(id)sender
{
	[NSApp endSheet:mRegPanel];
}

- (IBAction)createNewAccount:(id)sender
{
	[NSApp endSheet:mRegPanel];

	[[ISManager manager] createNewAccount];
}

- (IBAction)clickOnSign:(id)sender
{
	//Save registration code into defaults
	int selectedRow = [mRadio selectedRow];
	if (selectedRow == 1)
	{
		[self loginByUserPassword];
	}
	else
	{
		[self loginByRegCode];
	}
	
	[NSApp endSheet:mRegPanel];
}

- (IBAction)clickRememberInKeychain:(id)sender
{
	[[ISManager manager] setRememberInKeychain:[mSaveKeychain intValue]];
}

- (IBAction)clickRadio:(id)sender
{
	int selectedRow = [mRadio selectedRow];
	if (selectedRow == 1)
	{
		[mRegCodeView setEnabled:NO];
		[[self window] makeFirstResponder:mRegCodeView];
		[mPasswordView setEnabled:YES];
		[mUserView setEnabled:YES];
		[mSaveKeychain setEnabled:YES];
	}
	else
	{
		[mRegCodeView setEnabled:YES];
		[mPasswordView setEnabled:NO];
		[mUserView setEnabled:NO];
		[mSaveKeychain setEnabled:NO];
	}
}

- (NSString*)getUserID
{
	return [[ISManager manager] getUserID];
}

- (NSString*)parseUserID
{
	NSString* inStr = [[[NSString alloc] initWithString:[mRegCodeView stringValue]] autorelease];
	if ([inStr hasPrefix:RegistrationCodePrefix] == YES)
	{
		//it is registration link so it needs to find account id
		NSString* accountID = [[[NSString alloc] initWithString:[inStr substringFromIndex:
				[RegistrationCodePrefix length]]] autorelease];
		NSLog (accountID);
		return accountID;
	}

	return inStr;
}

- (BOOL)loginByRegCode
{
	//Check for valid reg data
	NSString *userID = [self parseUserID];
	BOOL reply = [[ISManager manager] loginByRegCode:userID];
	return reply;
}

- (BOOL)loginByUserPassword
{	
	NSString *username = [NSString stringWithString:
				[mUserView stringValue]];
	NSString *password = [NSString stringWithString:
				[mPasswordView stringValue]];
	BOOL reply= [[ISManager manager] loginByUsername:username password:password];
	
	if (reply == YES)
	{
		if ([mSaveKeychain intValue] == 1)
		{
			[[ISManager manager] addAccountToKeychain:username password:password];
		}
		else
		{
			[[ISManager manager] removeAccountFromKeychain:username];
		}
	}
	
	return reply;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	NSString *account = [mUserView stringValue];
	if (account)
	{
		NSString *password = [[ISManager manager] passwordForAccount:account];
		if (password)
		{
			[mPasswordView setStringValue:password];
		}
		else
		{
			[mPasswordView setStringValue:@""];
		}
	}
}

@end
