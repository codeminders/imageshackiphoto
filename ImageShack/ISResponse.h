#import <Cocoa/Cocoa.h>

@interface ISResponse : NSObject
{
	NSData *mBody;
	NSDictionary *mHeader;
}

- (id)init;
- (void)dealloc;

- (id)initWithBody:(NSData *)aBody header:(NSDictionary *)aHeader;

- (void)setBody:(NSData *)aBody;
- (NSData *)body;
- (void)setHeader:(NSDictionary *)aHeader;
- (NSDictionary *)header;

- (NSString *)stringHeader;
- (NSString *)stringBody;
@end
