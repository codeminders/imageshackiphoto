#import <Cocoa/Cocoa.h>
#import <HTTPRequest.h>
#import "Image.h"

@interface ImageshackRequest : NSObject 
{
	id m_Delegate;
	ImageshackHTTPRequest * m_HttpRequest;
	NSString *m_Boundary;
	Image* m_Image;
	NSString *m_BatchTags;
}

+ (ImageshackRequest *)requestWithDelegate:(id)aDelegate;

-(ImageshackRequest*)initWithDelegate:(id)aDelegate;
-(BOOL)post:(Image*)imadeItem response:(NSMutableString*)oResponse;
-(BOOL)get:(NSString*)url response:(NSMutableString*)oResponse;
-(BOOL)get:(NSString*)url data:(NSMutableData*)oResponse;
-(BOOL)get:(NSString*)url sresponse:(ISResponse**)oResponse;

-(NSString *)getBoundary;
-(void)setBoundary:(NSString*)str;

-(void)setBatchTags:(NSString *)value;
- (void)dealloc;
@end

@interface ImageshackRequest (DataPreparer)
- (NSMutableData*)internalPreparePOSTData:(Image*)image;
@end

