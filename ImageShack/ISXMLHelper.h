#import <Cocoa/Cocoa.h>

@interface ISXMLHelper : NSObject 
{
	id mXml;
}

- (id)initFromData:(NSData*)aString;
- (void)dealloc;

- (id)getFirstNodeByXPath:(NSString*)xpath;

@end
