#import <Cocoa/Cocoa.h>

static inline BOOL IsEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

@interface NSString (SMEDataAdditions)

-(NSString *)urlEscapedString;
-(NSComparisonResult)compareVersionToVersion:(NSString *)aVersion;

@end

