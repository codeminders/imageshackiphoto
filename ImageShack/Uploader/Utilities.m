#import "Utilities.h"
#import "ISConstants.h"

@implementation Utilities

+(NSString *)formatSize:(NSNumber *)number
{
	unsigned long koctet = 1024;
    unsigned long moctet = koctet*1024;
    unsigned long goctet = moctet * 1024;

    if (number == nil)
        return nil;
    NSCell *aCell = [[[NSCell alloc] init] autorelease];
    NSAttributedString *returnString = nil;

    NSNumberFormatter *numberFormat = [[[NSNumberFormatter alloc] init] autorelease];
    if ([number doubleValue] < 1024){
        [numberFormat setFormat:@"#,##0 B"];
        [aCell setFormatter:numberFormat];
        returnString = [[[NSAttributedString alloc] initWithString:[number stringValue]] autorelease];
        [aCell setAttributedStringValue:returnString];
		return [[aCell attributedStringValue] string];
    }
    else if (([number doubleValue] >= 1024) && ([number doubleValue] < moctet))
    {
        [numberFormat setFormat:@"#,##0 KB"];
        [aCell setFormatter:numberFormat];
        returnString = [[[NSAttributedString alloc] initWithString:[[NSNumber numberWithDouble:[number doubleValue]/koctet] stringValue]] autorelease];
        [aCell setAttributedStringValue:returnString];
        return [[aCell attributedStringValue] string];
    }
    else if (([number doubleValue] >= moctet) && ([number doubleValue] < goctet))
    {
        [numberFormat setFormat:@"#,##0.00 MB"];
        [aCell setFormatter:numberFormat];
        returnString = [[[NSAttributedString alloc] initWithString:[[NSNumber numberWithDouble:[number doubleValue]/moctet] stringValue]] autorelease];
        [aCell setAttributedStringValue:returnString];
        return [[aCell attributedStringValue] string];
    }
    else if ([number doubleValue] >= goctet)
    {
        [numberFormat setFormat:@"#,##0.000 GB"];
        [aCell setFormatter:numberFormat];
        returnString = [[[NSAttributedString alloc] initWithString:[[NSNumber numberWithDouble:[number doubleValue]/goctet] stringValue]] autorelease];
        [aCell setAttributedStringValue:returnString];
        return [[aCell attributedStringValue] string];
    }

    return nil;
}

+(NSString *)getBundleVersion
{
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *version = [infoPlist objectForKey:@"CFBundleShortVersionString"];
	return version;
}

+(BOOL)isExceededSizeLimit:(NSString*)filePath
{
	BOOL reply = NO;
	unsigned long length = 0;
	
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	length = [data length];
	if (length > MaxAllowedFileSizeToUpload)
		reply = YES;
	
	return reply;
}

@end

@implementation NSString (XMLParse)
- (NSString *)getValueForAttribute:(NSString*)anAttribute
{
	NSRange range1 = [self rangeOfString:anAttribute];
	if (range1.location == NSNotFound)
		return @"";

	NSString *endAttrib = [NSString stringWithFormat:@"/%@", anAttribute];
	NSRange range2 = [self rangeOfString:endAttrib];
	if (range2.location == NSNotFound)
		return @"";

	unsigned int location = range1.location + range1.length + 1;
	unsigned int length = (range2.location - 1) - location;
	NSRange range3 = NSMakeRange(location, length);
	
	return [self substringWithRange:range3];
}

- (NSString *)getSubstringBetweenLeft:(NSString *)aLeft right:(NSString*)aRight
{
	NSRange range1 = [self rangeOfString:aLeft];
	if (range1.location == NSNotFound)
		return @"";

	NSRange range2 = [self rangeOfString:@";" options:0 
				range:NSMakeRange(range1.location, 
				[self length] - range1.location - 1)];
	if (range2.location == NSNotFound)
		return @"";
	
	unsigned int location = range1.location + range1.length;
	unsigned int length = (range2.location) - location;
	NSRange range3 = NSMakeRange(location, length);

	return [self substringWithRange:range3];
}
@end
