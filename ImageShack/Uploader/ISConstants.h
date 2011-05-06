#import <Cocoa/Cocoa.h>
#import <HTTPRequest.h>
#import <ImageshackRequest.h>

#define ImageshackSuccessUploadURL @"http://my.imageshack.us/v_images.php"
//#define NewVersionURL @"http://toolbar.imageshack.us/macuploader/update-%@.php"
//#define NewVersionURL @"http://downloads.imageshack.us/iphotoplugin/version.xml"
#define NewVersionURL @"http://toolbar.imageshack.us/iphotoplugin/version.xml"

#define ImageshackServerURL	@"http://imageshack.us/"
#define ImageshackHostName	@"www.imageshack.us" 

#define ImageshackImageUploadHostname @"http://www.imageshack.us/upload_api.php"
#define ImageshackImageUploadAPIPath @"/upload_api.php"
#define ImageshackVideoUploadHostname @"http://render.imageshack.us/upload_api.php"

#define ImageshackRegisterUserURL @"http://profile.imageshack.us/registration"
#define ImageshackMyImages @"http://my.imageshack.us/v_images.php"
#define ImageshackMySlideshow @"http://my.imageshack.us/slideshow/my_shows.php"
#define ImageshackMyAccount @"http://profile.imageshack.us/prefs/index.php"
#define ImageshackFAQ @"http://reg.imageshack.us/content.php?page=faq"

#define RegistrationCodePrefix @"http://my.yfrog.com/setlogin.php?login="

#define kISQuickRegistraionURL @"http://my.imageshack.us/registration/quickreg.php?email=%@&username=%@"
#define kISLoginByRegCodeURL @"http://reg.imageshack.us/setlogin.php?login=%@&xml=yes"
#define kISLoginByUserPassword @"http://my.imageshack.us/auth.php?username=%@&password=%@"

#define kImageshakPlugInKey	@"1678IJNXba550bf63f33430bc8f10570565406c3"

#define SEPARATOR @"B-O-U-N-D-A-R-Y"

#define kResponseErrorNodeXPath @"/links/error"

#define kUsernameAttrubute @"username"
#define kExistAttribute @"exists"

//#define ImageshackServerURL	@"http://172.18.0.14/1.ashx" //Debug
//#define ImageshackServerURL	@"http://172.18.0.10/1.ashx"
//#define ImageshackServerURL	@"http://192.168.0.1/1.ashx"

#define MaxAllowedFileSizeToUploadNotLogged		5242880  //1024*1024*5
#define MaxAllowedFileSizeToUpload				10485760 //1024*1024*10

enum
{
	INVALID_USER_ID = 0,
	UPLOADING_SUCCESSED = 1,
	UPLOADING_ERROR = 2
};

extern NSString *const UserIDPreferenceKey;
extern NSString *const UsernamePreferencesKey;
extern NSString *const DefaultScalePreferenceKey;
extern NSString *const DefaultRembarPreferenceKey;
extern NSString *const DefaultPrivacyPreferenceKey;
extern NSString *const LastLoginPreferenceKey;
extern NSString *const RememberInKeychainPreferenceKey;
extern NSString *const NoBatchConfirmationPreferenceKey;
extern NSString *const OverrideIndividualPreferenceKey;
