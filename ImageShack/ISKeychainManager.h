#import <Cocoa/Cocoa.h>
@interface ISKeychainManager : NSObject {

}

/*!
    @method     sharedKeychainManager
    @abstract   Returns the singleton manager.
*/
+(ISKeychainManager *)sharedKeychainManager;

/*!
    @method     keychainItemsForKind:
    @abstract   Returns an array of keychain items for the specified kind string.
    @discussion Each item in the array is simply a string indicating the name of a keychain item.
*/
-(NSArray *)keychainItemsForKind:(NSString *)itemKind;

/*!
    @method     checkForExistanceOfKeychainItem:withItemKind:forUsername:
    @abstract   Returns YES if the keychain item exists or NO otherwise.
*/
-(BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

/*!
	@method     deleteKeychainItem:withItemKind:forUsername:
	@abstract   Attempts to delete the specified keychain item. Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

 /*!
	@method     modifyKeychainItem:withItemKind:forUsername:withNewPassword:
	@abstract   Attempts to modify the specified keychain item. Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword;

 /*!
	@method     addKeychainItem:withItemKind:forUsername:withPassword:
	@abstract   Adds the specified item to the keychain.  Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password;

/*!
    @method     passwordFromKeychainItem:withItemKind:forUsername:
    @abstract   Returns the password for the specified item or nil if the item does not exist.
*/
-(NSString *)passwordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

@end
