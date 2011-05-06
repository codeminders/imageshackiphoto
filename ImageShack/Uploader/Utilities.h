#import <Cocoa/Cocoa.h>

@interface Utilities : NSObject {
}

+(NSString *)formatSize:(NSNumber *)number;
+(NSString *)getBundleVersion;
+(BOOL)isExceededSizeLimit:(NSString*)filePath;

@end

@interface NSString (XMLParse)

- (NSString *)getValueForAttribute:(NSString*)anAttribute;
- (NSString *)getSubstringBetweenLeft:(NSString *)aLeft right:(NSString*)aRight;

@end
