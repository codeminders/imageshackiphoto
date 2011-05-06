#import <Cocoa/Cocoa.h>
#import "ImageshackRequest.h"

extern NSString *UsernameChangedNotification;
extern NSString *QuickRegisterNotification;
extern NSString *DisableButtonsNotification;
extern NSString *EnableButtonsNotification;

@interface ISManager : NSObject 
{
	NSString *mUsername;
	ImageshackRequest *mRequest;
	BOOL mIsExportAllowed;
}

+ (ISManager *)manager;

- (void)checkForUpdates;
- (void)checkForUpdatesInBackground;
- (void)performCheckForUpdates;

- (BOOL)isExportAllowed;
- (void)createNewAccount;
- (void)showUploadedImages;

- (void)openURL:(NSString*)aUrl;

- (BOOL)checkIfUserID;
- (NSString *)getUserID;

- (NSString *)getSystemVersion;
- (NSString *)getPluginVersion;
- (void)initDefaultValues;

- (NSString*)getLastLogin;
- (void)setLastLogin:(NSString *)aLogin;
- (int)isRememberInKeychain;
- (void)setRememberInKeychain:(int)aRemember;

- (void)setLoginAs:(NSString*)aUsername;
- (NSString *)getUsername;
- (NSString *)getSignedString;
- (BOOL)isSignedIn;
- (void)signOut;

-(void)addAccountToKeychain:(NSString *)account password:(NSString *)password;
-(void)removeAccountFromKeychain:(NSString *)account;
-(void)modifyAccountInKeychain:(NSString *)account newPassword:(NSString *)newPassword;
-(NSString *)passwordForAccount:(NSString *)account;

- (void)quickRegistrationWithEmail:(NSString *)email username:(NSString *)username;
- (BOOL)loginByRegCode:(NSString*)aCode;
- (BOOL)loginByUsername:(NSString*)aUsername password:(NSString*)aPassword;

- (NSString *)getRegCodeFromHeader:(NSString*)aHeader;

- (void)showAlertWithMessage:(NSString*)aMessage info:(NSString*)anInfo;
- (void)showAlertConnectionFailed;
- (void)showAlertNoItems;
- (void)showAlertItemsExceedSize:(int)aCount;

@end
