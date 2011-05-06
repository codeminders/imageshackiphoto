#import "ISResponse.h"

@implementation ISResponse

#pragma mark Inits
- (id)init
{
	return [super init];
}

- (id)initWithBody:(NSData *)aBody header:(NSDictionary *)aHeader
{
	[self setBody:aBody];
	[self setHeader:aHeader];

	[super init];
 	return self;
}

- (void)dealloc
{
	[mBody release];
	[mHeader release];
	[super dealloc];
}

#pragma mark Setters/Getters

- (void)setBody:(NSData*)aBody
{
	[mBody release];
	mBody = [[[NSData alloc] initWithData:aBody] retain];
}

- (NSData *)body
{
	return mBody;
}
- (void)setHeader:(NSDictionary*)aHeader
{
	[mHeader release];
	mHeader = [[[NSDictionary alloc] initWithDictionary:aHeader] retain];
}

- (NSDictionary *)header
{
	return mHeader;
}

#pragma mark Conversion
- (NSString *)stringHeader
{
	return [mHeader description];
}
- (NSString *)stringBody
{
	NSString *result = [[[NSString alloc] initWithData:mBody 
				encoding:NSASCIIStringEncoding] autorelease];
	return result;
}
@end
