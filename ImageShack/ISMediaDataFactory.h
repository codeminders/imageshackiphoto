#import <Cocoa/Cocoa.h>
#import "ISMediaData.h"

@interface ISMediaDataFactory : NSObject {
    NSDictionary   *mTypes;
}

+ (ISMediaDataFactory *)factory;
- (id)init;
- (void)dealloc;
- (ISMediaData *)createMediaData:(NSString *)filePath;
- (MediaType)fileMediaType:(NSString *)filePath;

@end