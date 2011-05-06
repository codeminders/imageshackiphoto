#import "ISManager.h"
#import "Utilities.h"
#import "ISConstants.h"
#import "ISXMLHelper.h"
#import "ISKeychainManager.h"
#import "ISStringAdditions.h"

NSString *KeychainItemName = @"ImageShack iPhoto Plugin";
NSString *KeychainItemKind = @"application password";

static ISManager *manager = nil;

//-------------------------------------------------
// Notifications
//-------------------------------------------------
NSString *UsernameChangedNotification = @"UsernameChangedNotification";
NSString *QuickRegisterNotification = @"QuickRegisterNotification";
NSString *DisableButtonsNotification = @"DisableButtonsNotification";
NSString *EnableButtonsNotification = @"EnableButtonsNotification";

@interface ISManager(Private)

@end

@implementation ISManager

+ (ISManager *)manager
{
	if (!manager)
	{
		manager = [[ISManager alloc] init];
	}
	
	return manager;
}

- (id)init
{
	mRequest = [[ImageshackRequest requestWithDelegate:self] retain];
	mIsExportAllowed = YES;
	return [super init];
}

- (void)dealloc
{
	[mRequest release];
	[super dealloc];
}

//Show Qiuck registration window 
- (void)createNewAccount
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter postNotificationName:QuickRegisterNotification object:nil];
}

-(void)showUploadedImages
{
	[self openURL:ImageshackSuccessUploadURL];
}

- (void)openURL:(NSString*)aUrl
{
	CFURLRef urlRef = CFURLCreateWithString(NULL, (CFStringRef)aUrl, NULL);
	OSStatus stat = LSOpenCFURLRef(urlRef, NULL);
	if (stat) 
		NSLog(@"Can't open browser for url %@, reason: %d", aUrl, stat);
	
	CFRelease(urlRef); urlRef = NULL;	
}

- (BOOL)checkIfUserID
{
	BOOL reply = YES;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *userID = [defaults stringForKey:UserIDPreferenceKey];
	if ((userID == NULL) || ([userID length] < 2))
		reply = NO;

	return reply;
}

- (NSString*)getUserID
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *userID = [defaults stringForKey:UserIDPreferenceKey];
	return userID;
}

- (NSString *)getSystemVersion
{
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (NSString *)getPluginVersion
{
	NSDictionary *infoPlist = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSString *version = [infoPlist objectForKey:@"CFBundleVersion"];
	return version;
}

// Set Default values for preferences if the application launchs
// the first and plist-file is absent.
- (void)initDefaultValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *userID = [defaults stringForKey:UserIDPreferenceKey];
	if (!userID)
	{
		[defaults setObject:@"" forKey:UserIDPreferenceKey];
		[defaults setInteger:0 forKey:DefaultScalePreferenceKey];
		[defaults setInteger:1 forKey:DefaultRembarPreferenceKey];
		[defaults setInteger:1 forKey:DefaultPrivacyPreferenceKey];
	}
	else
	{
		NSString *str = [defaults stringForKey:UsernamePreferencesKey];
		if ((str == nil) || ([str isEqualToString:@""]))
		{
			[self setLoginAs:@""];
		}
		else
		{
			[self setLoginAs:str];
		}
	}
}

- (void)setLoginAs:(NSString*)aUsername
{
    if (mUsername) [mUsername release];
    mUsername = [[NSString alloc] initWithString:aUsername];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter postNotificationName:UsernameChangedNotification object:nil];
}

- (NSString *)getUsername
{
	return mUsername;
}

- (NSString *)getSignedString
{
	if ([mUsername compare:@""] == NSOrderedSame)
		return @"Not signed in";
	
	NSMutableString *str = [NSMutableString stringWithString:
				@"Your are signed in as "];
	[str appendString:[self getUsername]];

	return str;
}

- (BOOL)isSignedIn
{
	BOOL reply = YES;
	if ([mUsername isEqualToString:@""])
		reply = NO;
	return reply;
}

- (void)signOut
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	[defaults setObject:@"" forKey:UsernamePreferencesKey];
	[defaults setObject:@"" forKey:UserIDPreferenceKey];
	[self setLoginAs:@""];
}

- (BOOL)isExportAllowed
{
	return mIsExportAllowed;
}

#pragma mark Preferences
- (NSString*)getLastLogin
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *lastLogin = [defaults stringForKey:LastLoginPreferenceKey];
	return lastLogin;
}

-(void)setLastLogin:(NSString *)aLogin
{
	if (aLogin)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:aLogin forKey:LastLoginPreferenceKey];
	}
}

- (int)isRememberInKeychain
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	int reply = [defaults integerForKey:RememberInKeychainPreferenceKey];
	return reply;
}

- (void)setRememberInKeychain:(int)aRemember
{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:aRemember forKey:RememberInKeychainPreferenceKey];
}

#pragma mark Login
- (void)quickRegistrationWithEmail:(NSString *)email username:(NSString *)username
{
	ImageshackRequest *req = [[ImageshackRequest requestWithDelegate:self] retain];
	
	NSMutableString *serverResponse = [NSMutableString string];
	NSString *url = [[[NSString alloc] initWithFormat:kISQuickRegistraionURL, 
				email, username] autorelease];
	BOOL isConnectionSuceeded = [req get:url response:serverResponse];
	
	NSAlert *alertSheet = [[[NSAlert alloc] init] autorelease];
	[alertSheet addButtonWithTitle:@"OK"];
	[alertSheet setAlertStyle:NSInformationalAlertStyle];

	//Process the response
	if(!isConnectionSuceeded)
	{
		[self showAlertConnectionFailed];
	}
	else if ([serverResponse compare:@"ok"] == NSOrderedSame)
	{
		[self showAlertWithMessage:@"Your ImageShack account has been created succeesfully."
					info:@"Please check your email to get the password. Use your ImageShack username and password or registration code to sign in."];
	}
	else //response = fail:MESSAGE
	{
		NSString *message = [serverResponse substringFromIndex:5];
		[self showAlertWithMessage:message info:@""];
	}
}

- (BOOL)loginByRegCode:(NSString*)aCode
{
	NSString *url = [NSString stringWithFormat:kISLoginByRegCodeURL, aCode];
	NSMutableString *serverResponse = [NSMutableString string];
	BOOL reply = [mRequest get:url response:serverResponse];

	if (reply == YES)
	{
		//parse response to get username
		if (serverResponse)
		{
			NSString *isExist = [serverResponse getValueForAttribute:
						kExistAttribute];
			if ([isExist compare:@"yes"] == NSOrderedSame)
			{
				NSString *username = [serverResponse getValueForAttribute:
						kUsernameAttrubute];
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
				[defaults setObject:username forKey:UsernamePreferencesKey];
				[defaults setObject:aCode forKey:UserIDPreferenceKey];
				[[ISManager manager] setLoginAs:username];
			}
			else
			{
				[self showAlertWithMessage:@"Incorrect registration code"
							info:@"Please specify your ImageShack registration code taken from email."];
			}
		}
	}
	else
	{
		[self showAlertConnectionFailed];
	}

	return reply;
}

- (BOOL)loginByUsername:(NSString*)aUsername password:(NSString*)aPassword
{
	NSString *url = [NSString stringWithFormat:kISLoginByUserPassword, 
				aUsername, aPassword];

	ISResponse *response;
	BOOL reply = [mRequest get:url sresponse:&response];
//	NSLog(@"Body: %@", [response stringBody]);
//	NSLog(@"Header: %@", [response stringHeader]);
	
	if (reply == YES)
	{
		NSString *body = [NSString stringWithString:[response stringBody]];
		if ([body isEqualToString:@"OK"] == YES)
		{
			NSString *code = [self getRegCodeFromHeader:[response stringHeader]];
			if ([code isEqualToString:@""] == NO)
			{
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
				[defaults setObject:code forKey:UserIDPreferenceKey];
				[defaults setObject:aUsername forKey:UsernamePreferencesKey];
				[self setLoginAs:aUsername];
				[self setLastLogin:aUsername];
			}
			else
			{
				[[ISManager manager] setLoginAs:@""];
			}
		}
		else if ([body isEqualToString:@"BADARG"] == YES)
		{
			[self showAlertWithMessage:@"Empty username and/or password."
						info:@"Please specify username and password."];
		}
		else if ([body isEqualToString:@"FAIL"] == YES)
		{
			[self showAlertWithMessage:@"Invalid username and/or password."
						info:@""];
		} 
	}
	else
	{
		[self showAlertConnectionFailed];
	}

	return reply;
}

#pragma mark Keychains 
-(NSString *)keychainItemNameForAccount:(NSString *)accountId {
	return [NSString stringWithFormat:@"%@: %@", KeychainItemName, accountId];
}

-(BOOL)passwordExistsInKeychainForAccount:(NSString *)account {
	return [[ISKeychainManager sharedKeychainManager] checkForExistanceOfKeychainItem:[self keychainItemNameForAccount:account] withItemKind:KeychainItemKind forUsername:account];
}

-(void)addAccountToKeychain:(NSString *)account password:(NSString *)password
{
	if([self passwordExistsInKeychainForAccount:account])
		return;

	[[ISKeychainManager sharedKeychainManager] addKeychainItem:[self keychainItemNameForAccount:account] withItemKind:KeychainItemKind forUsername:account withPassword:password];
}

-(void)removeAccountFromKeychain:(NSString *)account
{
	[[ISKeychainManager sharedKeychainManager] deleteKeychainItem:[self keychainItemNameForAccount:account] withItemKind:KeychainItemKind forUsername:account];
}

-(void)modifyAccountInKeychain:(NSString *)account newPassword:(NSString *)newPassword {
	if([self passwordForAccount:account] != nil)
		[[ISKeychainManager sharedKeychainManager] modifyKeychainItem:[self keychainItemNameForAccount:account] withItemKind:KeychainItemKind forUsername:account withNewPassword:newPassword];
	else
		[self addAccountToKeychain:account password:newPassword];
}

-(NSString *)passwordForAccount:(NSString *)account {
	return [[ISKeychainManager sharedKeychainManager] passwordFromKeychainItem:[self keychainItemNameForAccount:account] withItemKind:KeychainItemKind forUsername:account];
}

#pragma mark-
- (NSString *)getRegCodeFromHeader:(NSString*)aHeader
{
	return [aHeader getSubstringBetweenLeft:@"myimages=" right:@";"];
}

#pragma mark Alerts
- (void)showAlertWithMessage:(NSString*)aMessage info:(NSString*)anInfo
{
	NSAlert *alertSheet = [[[NSAlert alloc] init] autorelease];
	[alertSheet addButtonWithTitle:@"OK"];
	[alertSheet setAlertStyle:NSInformationalAlertStyle];
	[alertSheet setMessageText:aMessage];
	[alertSheet setInformativeText:anInfo];
	[alertSheet runModal];
}

- (void)showAlertConnectionFailed
{
	[self showAlertWithMessage:@"You are not connected to Internet or ImageShack server is temporary unavailable."
				info:@"Please check your Internet connection or try again later."];
}

- (void)showAlertNoItems
{
	[self showAlertWithMessage:@"No pictures were selected."
				info:@"Please close Export dialog and select neccessary pictures to upload."];
}

- (void)showAlertItemsExceedSize:(int)aCount
{
	NSString *info;
	if (aCount > 1)
		info = [NSString stringWithFormat:@"%d files were not added because their size exceed 10Mb.", aCount];
	else if (aCount == 1)
		info = [NSString stringWithFormat:@"1 file was not added because its size exceed 10Mb."];
	
	[self showAlertWithMessage:@"Some files were not added." info:info];
}

#pragma mark Update routine
- (void)checkForUpdates
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[NSThread detachNewThreadSelector: @selector(checkForUpdatesInBackground) 
                             toTarget: self 
                           withObject: nil];

	[pool release];
}

- (void)checkForUpdatesInBackground
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	@try
	{
		[self performSelectorOnMainThread: @selector(performCheckForUpdates)
                               withObject: nil
                            waitUntilDone: NO];
	}
	@catch (NSException *exception)
	{
		NSLog(@"ImageShack iPhoto Plugin: Failed to autoupdate. Caught %@: %@", [exception name], [exception  reason]);
	}

	[pool release];
}

- (void)performCheckForUpdates
{
	NSMutableData *serverResponse = [NSMutableData data];
	BOOL isRequestSucceeded = [mRequest get:NewVersionURL data:serverResponse];
	
	/* - in response
	<product>
        <name>PRODUCT NAME</name>
        <url>URL TO DOWNLOAD LATEST VERSION</url> 
        <versions>
            [<version id="ID" type="MANDATORY|OPTIONAL">
                <released>YYYY-MM-DD</released>
                [<description content-type="text|html">SHORT VERSION DESCRIPTION</description>]+
            </version>]+
        </versions>
    </product>
	*/
	
	//for debug purposes
	//NSData *tempData = [NSData dataWithContentsOfFile:@"/Volumes/Leopard/q.txt"];
	
	NSAlert *alertSheet = [[[NSAlert alloc] init] autorelease];
	[alertSheet addButtonWithTitle:@"OK"];
	[alertSheet setAlertStyle:NSInformationalAlertStyle];

	if(isRequestSucceeded /*|| YES*/)
	{
		//for debug
		//NSString *strResponse = [[[NSString alloc] initWithData:serverResponse 
		//		encoding:NSASCIIStringEncoding] autorelease];
		//NSLog(@"Autoupdate response: %@", strResponse);
		
		//parse response and fetch latest version id
		ISXMLHelper *xml = [[[ISXMLHelper alloc] initFromData:serverResponse/*tempData*/]
					autorelease];
		
		if(xml==nil)
		{
			NSLog(@"ImageShack iPhoto plugin: Autoupdate - can't init xml from response.");
			return;
		}
		
		NSString *str = [[xml getFirstNodeByXPath:@"//versions/version/@id"] stringValue];
		if(str==nil)
		{
			NSLog(@"ImageShack iPhoto plugin: Autoupdate received invalid response.");
			return;
		}
		
		//NSLog(@"VERSION %@", str);
		//NSLog([[xml getFirstNodeByXPath:@"//product/url"] stringValue]);

		//compare if version is equal to getPluginVersion
		//if YES - show alert with single button Ok and text 'You are running the newest version of ImageShack iPhoto Plugin'
		//if NO - show alert with two buttons (Ok, Cancel) and text: 'There are newer version is available: %@. Press ok to download it or cancel todo it later'
		//	if user click Ok - open default web browser to: [[xml getFirstNodeByXPath:@"//product/url"] stringValue];
		
		NSString *localVersion =[self getPluginVersion];
		if([localVersion compareVersionToVersion:str] == NSOrderedAscending)
		{
			
			str = [[xml getFirstNodeByXPath:@"//versions/version/description"] stringValue];
			if(str==nil)
				str=@"";
			
			NSString *text;
			if([str length]<1)
				text = [NSString stringWithFormat:@"Press OK button to download latest version or press Cancel to download later."];
			else
				text = [NSString stringWithFormat:@"Press OK button to download latest version or press Cancel to download later.\n\nUpdate information: %@", str];
			
			[alertSheet setMessageText:@"There is a newest version of ImageShack iPhoto plugin available."];
			[alertSheet setInformativeText:text];
			[alertSheet addButtonWithTitle:@"Cancel"];
			int result = [alertSheet runModal];

			//bug 2703
			//If user was offered update which was marked as "Mandatory" and refused to
			//install it, EXPORT button should be disable and plugin should not try to upload
			//to imageshack.
			//Natalia says: always disable export button, if mandatory update is available
			NSString* versionStatus = [[xml getFirstNodeByXPath:@"//versions/version/@type"] stringValue];
			if(versionStatus == nil)
			{
				NSLog(@"ImageShack iPhoto Plugin: can't get version type. Autoupdate stopped.");
				return;
			}

			versionStatus = [versionStatus lowercaseString];
			if([versionStatus compare:@"mandatory"] == NSOrderedSame)
			{
				NSLog(@"ImageShack iPhoto plugin: since there is new mandatory update is available - please update your plugin in order to export.");

				NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
				[defaultCenter postNotificationName:DisableButtonsNotification object:nil];

				mIsExportAllowed = NO;
			}

			//if 'Ok' - open default browser to url specified in response xml
			if (result == NSAlertFirstButtonReturn)
			{
				str = [[xml getFirstNodeByXPath:@"//product/url"] stringValue];
				[self openURL:str];
			}
			else if(mIsExportAllowed == NO) //show alert only if update is mandatory and user declined to update
			{
				NSAlert *alert = [[[NSAlert alloc] init] autorelease];
				[alert addButtonWithTitle:@"OK"];
				[alert setAlertStyle:NSInformationalAlertStyle];
				[alert setMessageText:@"Update is required."];
				[alert setInformativeText:@"Please update to the latest plugin version in order to export images."];
				[alert runModal];
			}
		}
	}
	else
	{
		NSLog(@"ImageShack iPhoto plugin: Autoupdate failed - connection error.");
	}
}
@end
