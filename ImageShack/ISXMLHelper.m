#import "ISXMLHelper.h"

@implementation ISXMLHelper

- (id)getFirstNodeByXPath:(NSString*)xpath
{
	NSError* e = nil;
	NSArray* nodes = [mXml nodesForXPath:xpath error:&e];
	return ( [nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
}

- (id)initFromData:(NSData*)aData
{
	[super init];
	NSError *err;
	[mXml release];
	mXml = [[NSXMLDocument alloc] initWithData:aData 
				options:NSXMLNodePreserveWhitespace |NSXMLNodePreserveCDATA |
				NSXMLDocumentTidyXML
				error:&err];
	return self;
}

- (void)dealloc
{
	[mXml release];
	[super dealloc];
}

@end
