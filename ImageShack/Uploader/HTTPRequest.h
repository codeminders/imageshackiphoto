#import <Cocoa/Cocoa.h>
#import "ISResponse.h"

@interface ImageshackHTTPRequest : NSObject
{
	id m_Delegate;
	NSTimeInterval m_TimeoutInterval;

	BOOL m_Closed;
	NSURLConnection *m_Connection;
	NSTimer *m_Timer;
	id m_UserInfo;
	size_t m_ExpectedLength;
	NSMutableData *m_ReceivedData;
}
+ (ImageshackHTTPRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (ImageshackHTTPRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (BOOL)isClosed;
- (void)cancel;
- (BOOL)GET:(NSString*)url userInfo:(id)info response:(NSMutableString*)oResponse;
- (BOOL)GET:(NSString*)url userInfo:(id)info data:(NSMutableData*)oResponse;
- (BOOL)GET:(NSString*)url userInfo:(id)info sresponse:(ISResponse**)oResponse;
- (BOOL)POST:(NSString*)url data:(NSData*)data separator:(NSString*)separator 
			userInfo:(id)info response:(NSMutableString*)oResponse;


        size_t _dataSize;
        size_t _bytesSent;
        CFReadStreamRef _stream;
        NSMutableData *_response;

@end

#define ImageshackHTTPDefaultTimeoutInterval  10.0			// 10 seconds

@interface NSObject (ImageshackHTTPReqestDelegate)
- (void)HTTPRequest:(ImageshackHTTPRequest*)request didCancel:(id)userinfo;
- (void)HTTPRequest:(ImageshackHTTPRequest*)request didFetchData:(NSData*)data userInfo:(id)userinfo;
- (void)HTTPRequest:(ImageshackHTTPRequest*)request didTimeout:(id)userinfo;
- (void)HTTPRequest:(ImageshackHTTPRequest*)request error:(NSError*)err userInfo:(id)userinfo;
- (void)HTTPRequest:(ImageshackHTTPRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo;
@end
