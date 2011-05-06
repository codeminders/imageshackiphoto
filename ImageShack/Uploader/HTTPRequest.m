#import "HTTPRequest.h"
#import "ISConstants.h"
#import "Utilities.h"
#import "ISManager.h"

@interface ImageshackHTTPRequest(ImageshackHTTPRequestInternals)
- (void)dealloc;
- (void)reset;
- (void)internalCancel;
- (void)handleTimeout:(NSTimer*)timer;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

@implementation ImageshackHTTPRequest
+ (ImageshackHTTPRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	return [[[ImageshackHTTPRequest alloc] initWithDelegate:aDelegate timeoutInterval:interval] autorelease];
}
- (ImageshackHTTPRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init]))
	{
		m_Delegate = [aDelegate retain];
		m_TimeoutInterval = (interval > 0) ? interval : ImageshackHTTPDefaultTimeoutInterval;
		
		m_Closed = YES;
		m_Connection = nil;
		m_Timer = nil;
		m_UserInfo = nil;
		m_ExpectedLength = 0;
		m_ReceivedData = nil;
	}
	return self;
}

- (BOOL)isClosed
{
	return m_Closed;
}

- (void)cancel
{
	if (!m_Closed) return;
	[self internalCancel];
	
	if ([m_Delegate respondsToSelector:@selector(HTTPRequest:didCancel:)])
	{
		[m_Delegate HTTPRequest:self didCancel:m_UserInfo];
	}
}

- (BOOL)GET:(NSString*)url userInfo:(id)info response:(NSMutableString*)oResponse
{
	NSMutableData *data = [NSMutableData data];
	BOOL reply = [self GET:url userInfo:info data:data]; 
	NSString *str = [[[NSString alloc] initWithData:data 
				encoding:NSASCIIStringEncoding] autorelease];
	[oResponse setString:str];

	return reply;
}

- (BOOL)GET:(NSString*)url userInfo:(id)info data:(NSMutableData*)oResponse
{
	if (!m_Closed) return NO;

	[self reset];
	m_UserInfo = [info retain];
	m_ReceivedData = [[NSMutableData data] retain];

	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url] 
				cachePolicy:NSURLRequestReloadIgnoringCacheData 
				timeoutInterval:m_TimeoutInterval];
				
	NSError* e;
	NSHTTPURLResponse* res;
	NSData* body = [NSURLConnection sendSynchronousRequest:req 
				returningResponse:&res error:&e];

	if (res == nil)//(!m_Connection)
	{
		NSLog(@"Connection failed with code: %d", [e code]);
		[self reset];
		return NO;
	}
	
	//Temp output response header
	NSDictionary *header = [res allHeaderFields];
	ISResponse *response = [[[ISResponse alloc] init] autorelease];
	[response setBody:body];
	[response setHeader:header];
//	NSLog(@"Header %@", [response stringHeader]);
//	NSLog(@"Body %@", [response stringBody]);
	
	[oResponse setData:body];

	if([res statusCode]==200)
		return YES;
	else
	{
		NSLog(@"ImageShack Uploader Plugin: HTTPRequest get status code=%d",[res statusCode]);
		return NO;
	}
}

- (BOOL)GET:(NSString*)url userInfo:(id)info sresponse:(ISResponse**)oResponse
{
	if (!m_Closed) return NO;

	[self reset];
	m_UserInfo = [info retain];
	m_ReceivedData = [[NSMutableData data] retain];

	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url] 
				cachePolicy:NSURLRequestUseProtocolCachePolicy 
				timeoutInterval:m_TimeoutInterval];
	NSError* e;
	NSHTTPURLResponse* res;
	NSData* body = [NSURLConnection sendSynchronousRequest:req 
				returningResponse:&res error:&e];

	if (res == nil)//(!m_Connection)
	{
		NSLog(@"Connection failed with code: %d", [e code]);
		[self reset];
		return NO;
	}
	
	//Temp output response header
	NSDictionary *header = [res allHeaderFields];
	*oResponse = [[[ISResponse alloc] initWithBody:body header:header] 
				autorelease];

//	[oResponse setBody:body];
//	[oResponse setHeader:header];
//	NSLog(@"Header %@", [response stringHeader]);
//	NSLog(@"Body %@", [response stringBody]);

	if([res statusCode]==200)
		return YES;
	else
	{
		NSLog(@"ImageShack Uploader Plugin: HTTPRequest get status code=%d",[res statusCode]);
		return NO;
	}
}

- (BOOL)POST:(NSString*)url data:(NSData*)data separator:(NSString*)separator 
	userInfo:(id)info response:(NSMutableString*)oResponse
{
//	NSLog(@"Post");
	if (!m_Closed) return NO;

	[self reset];
	m_UserInfo = [info retain];
	
	m_ReceivedData = [[NSMutableData data] retain];

	NSMutableURLRequest *req=[[[NSMutableURLRequest alloc] init] autorelease];
	[req setURL:[NSURL URLWithString:url]];
	//NSLog(url);
	[req setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[req setTimeoutInterval:m_TimeoutInterval];
	[req setHTTPMethod:@"POST"];

	//Prepare header
	NSString *header=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", separator];
	[req setValue:header forHTTPHeaderField:@"Content-Type"];
	
	NSString* myID = [[ISManager manager] getUserID];
	if ((myID == NULL) || ([myID length] < 2))
	{
		//Default user is used for Debug version only. In release version 
		// the alert is shown if there is incorrect UserID.
		NSLog(@"Using default userID:99c6af0fa436d47f56979763cdd7c658, for user dmitry_kl@gmx.net. this is for debug only.");
		header = [NSString stringWithFormat:@"imgshck=99c6af0fa436d47f56979763cdd7c658; myimages=99c6af0fa436d47f56979763cdd7c658; flashInstalled=0"];	
	}
	else
		header = [NSString stringWithFormat:@"imgshck=%@; myimages=%@; rem_bar=1; flashInstalled=0",myID, myID];	
	
	[req setValue:header forHTTPHeaderField:@"Cookie"];
	
	header = [NSString stringWithFormat: @"Imageshack Mac Uploader %@ (MacOS %@)",
				[[ISManager manager] getPluginVersion],
				[[ISManager manager] getSystemVersion]];

	[req setValue:header forHTTPHeaderField:@"User-Agent"]; 

	[req setHTTPBody:data];
	
	NSError* e;
	NSURLResponse* res;	
	NSData* body = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&e];

	NSString *str = [[[NSString alloc] initWithData:body 
				encoding:NSASCIIStringEncoding] autorelease];
	
	if (res == nil)//(!m_Connection)
	{
		[self reset];
		NSLog(@"Connection failed");
		return NO;
	}

//	NSLog(@"GET response: ");
	[oResponse setString:str];
//	NSLog(oResponse);

	return YES;
}
@end

@implementation ImageshackHTTPRequest(ImageshackHTTPRequestInternals)
- (void)dealloc
{
	if (!m_Closed) [self internalCancel];
	
	if (m_Delegate) [m_Delegate release];
	if (m_Connection) [m_Connection release];
	if (m_Timer) [m_Timer release];
	if (m_UserInfo) [m_UserInfo release];
	if (m_ReceivedData) [m_ReceivedData release];
	[super dealloc];
}
- (void)internalCancel
{
	[m_Connection cancel];
	[m_Timer invalidate];
	m_Closed = YES;	
}

- (void)reset
{
	if (!m_Closed) [self cancel];
	
	m_Closed = YES;
	m_ExpectedLength = 0;

	if (m_Connection)
	{
		[m_Connection release];
		m_Connection = nil;
	}
	if (m_Timer) 
	{
		if ([m_Timer isValid])
		{
			[m_Timer invalidate];
		}
		[m_Timer release];
		m_Timer = nil;
	}
	if (m_UserInfo) 
	{
		[m_UserInfo release];
		m_UserInfo = nil;
	}
	if (m_ReceivedData)
	{
		[m_ReceivedData release];
		m_ReceivedData = nil;
	}
}
- (void)handleTimeout:(NSTimer*)timer
{
	if ([m_Delegate respondsToSelector:@selector(HTTPRequest:didTimeout:)]) 
	{
		[m_Delegate HTTPRequest:self didTimeout:m_UserInfo];
	}
	
	[self internalCancel];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[m_ReceivedData setLength:0];
	m_ExpectedLength = (size_t)[response expectedContentLength];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[m_ReceivedData appendData:data];
	[m_Timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:m_TimeoutInterval]];	
	if ([m_Delegate respondsToSelector:@selector(HTTPRequest:progress:expectedTotal:userInfo:)]) 
	{
		[m_Delegate HTTPRequest:self progress:[m_ReceivedData length] expectedTotal:m_ExpectedLength userInfo:m_UserInfo];
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (m_Timer) [m_Timer invalidate];
	m_Closed = YES;

	if ([m_Delegate respondsToSelector:@selector(HTTPRequest:didFetchData:userInfo:)]) 
	{
		[m_Delegate HTTPRequest:self didFetchData:m_ReceivedData userInfo:m_UserInfo];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (m_Timer) [m_Timer invalidate];
	m_Closed = YES;

	if ([m_Delegate respondsToSelector:@selector(HTTPRequest:error:userInfo:)])
	{
		[m_Delegate HTTPRequest:self error:error userInfo:m_UserInfo];
	}
}
@end
