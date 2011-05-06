#import "ISUploadRequest.h"
#import "ISConstants.h"
#import "ISManager.h"
#import "ISXMLHelper.h"

#include <netinet/in.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>

static CFTimeInterval   sPostTimeout = 60.0;

@interface ISUploadRequest(Private)

-(void)startImageUpload;

-(BOOL)isUploading;
-(void)setIsUploading:(BOOL)v;

-(void)setObserver:(NSObject<ISUploadRequestObserver> *)anObserver;
-(NSObject<ISUploadRequestObserver> *)observer;

-(NSData *)imageData;
-(void)setImageData:(NSData *)imgData;

-(NSMutableData *)response;
-(void)setResponse:(NSMutableData *)data;

-(void)setFilename:(NSString *)filename;
-(void)setKeywords:(NSArray *)kw;

-(void)appendToResponse;
-(void)transferComplete;
-(void)errorOccurred:(CFStreamError *)err;

-(NSString *)validateResponse;

-(void)destroyUploadResources;
-(NSString *)cleanKeywords:(NSArray *)keywords;

//-(NSData *)prepareImageData:(Image *)anImage;
-(NSData *)prepareMediaData:(ISMediaData *)anMedia;

-(NSString *)boundary;
-(void)setBoundary:(NSString*)str;

- (NSString *)getUploadImageUrl;

@end

static double ISUploadProgressTimerInterval = 0.125/2.0;

static const CFOptionFlags DAClientNetworkEvents = 
										kCFStreamEventOpenCompleted     |
										kCFStreamEventHasBytesAvailable |
										kCFStreamEventEndEncountered    |
										kCFStreamEventErrorOccurred;

static void ReadStreamClientCallBack(CFReadStreamRef stream, 
			CFStreamEventType type, void *clientCallBackInfo)
{
	switch (type) 
	{
		case kCFStreamEventHasBytesAvailable:
			[(ISUploadRequest *)clientCallBackInfo appendToResponse];
			break;
		case kCFStreamEventEndEncountered:
			[(ISUploadRequest *)clientCallBackInfo transferComplete];
			break;
		case kCFStreamEventErrorOccurred: {
			CFStreamError err = CFReadStreamGetError(stream);
			NSLog(@"Error occured");
			[(ISUploadRequest *)clientCallBackInfo errorOccurred:&err];
			break;
		} default:
			break;
	}
}

@implementation ISUploadRequest
- (void) messageTimedOut: (NSTimer *) theTimer
{
	[self cancelUpload];
	[[self observer] uploadTimedOut:self];
}

+(ISUploadRequest *)uploadRequest {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self imageData] release];
	[[self response] release];
	[[self filename] release];
	if (mUploadURL) 
		[mUploadURL release];
	[mBatchTag release];
	
	if(mTimeoutTimer)
	{	
		[mTimeoutTimer invalidate];
		[mTimeoutTimer release];
		mTimeoutTimer = nil;
	}
	
	[super dealloc];
}

-(id)init
{
	id obj = [super init];
	[self setBoundary:[[NSString alloc] initWithFormat:@"%@%d", SEPARATOR, random()]];
	[self setPostUploadURL:ImageshackImageUploadHostname];
    response = nil;
    [self setResponse:[[[NSMutableData alloc] init] autorelease]];
	return obj;
}

-(void)setObserver:(NSObject<ISUploadRequestObserver> *)anObserver {
	observer = anObserver;
}

-(NSObject<ISUploadRequestObserver> *)observer {
	return observer;
}

- (void)setPostUploadURL:(NSString*)uploadUrl
{
	if (mUploadURL) [mUploadURL release];
	mUploadURL = [[NSString alloc] initWithString:uploadUrl];
}

-(NSString *)postUploadURL
{
	return mUploadURL;
}

-(NSString *)imageHeadersForRequest:(CFHTTPMessageRef *)myRequest {
	NSDictionary *headers = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(*myRequest);
	NSEnumerator *enumerator = [headers keyEnumerator];
	NSMutableString *result = [NSMutableString string];
	NSString *key;
	while(key = [enumerator nextObject])
		[result appendFormat:@"%@: %@\n", key, [headers objectForKey:key]];
	
	[headers release];
	return result;
}

-(NSString *)cleanNewlines:(NSString *)aString {
	// adding a newline to a header will cause the sent request to be invalid.
	// use carriage returns instead of newlines.
	NSMutableString *cleanedString = [NSMutableString stringWithString:aString];
	[cleanedString replaceOccurrencesOfString: @"\n"
								   withString: @"\r"
									  options: 0
										range: NSMakeRange(0, [cleanedString length])];
	return [NSString stringWithString:cleanedString];
}

-(NSString *)cleanKeywords:(NSArray *)theKeywords {
	return [NSString stringWithFormat:@"\"%@\"", [theKeywords componentsJoinedByString:@"\" \""]];
}

-(void)uploadMediaData:(ISMediaData *)theMedia observer:(NSObject<ISUploadRequestObserver> *)anObserver
{
	NSData *theData = [self prepareMediaData:theMedia];
	
	MediaType type = [theMedia type];
	if ([type.className compare:@"image"] == NSOrderedSame ||
		[type.className compare:@"application"] == NSOrderedSame)
    {
        NSString *addr = [self getUploadImageUrl];
        [self setPostUploadURL:addr];
        [addr release];
		//[self setPostUploadURL:ImageshackImageUploadHostname];
    }
	else if ([type.className compare:@"video"] == NSOrderedSame)
		[self setPostUploadURL:ImageshackVideoUploadHostname];
	
    NSLog(@"%@\n", [self postUploadURL]);
    
	[self setImageData:theData];
	[self setFilename:[theMedia name]];
	[self setObserver:anObserver];	
	
	[self startImageUpload];
}

-(void)startImageUpload
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
//	NSLog(@"Posting image %@ to %@ ", [self filename], [self postUploadURL]);
	
	NSURL *requestUrl = [NSURL URLWithString:[self postUploadURL]];
	CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
				CFSTR("POST"), (CFURLRef)requestUrl, kCFHTTPVersion1_1);

	NSString *headerfield=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [self boundary]];
	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Type"), (CFStringRef)headerfield);

	headerfield = [NSString stringWithFormat: @"Imageshack Mac Uploader %@ (MacOS %@)",
					[[ISManager manager] getPluginVersion],
					[[ISManager manager] getSystemVersion]
				  ];

	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)headerfield);
//	NSLog(@"Image headers: %@", [self imageHeadersForRequest:&myRequest]);
	CFHTTPMessageSetBody(myRequest, (CFDataRef)[self imageData]);
	
//	NSString *str = [[[NSString alloc] initWithData:[self imageData] 
//				encoding:NSASCIIStringEncoding] autorelease];
//	NSLog(@"Body: %@", str);
	
	readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, myRequest);
	CFRelease(myRequest);
	
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};
	if (!CFReadStreamSetClient(readStream, DAClientNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
		CFRelease(readStream);
		readStream = NULL;
		NSLog(@"CFReadStreamSetClient returned null on start of upload");
		[pool release];
		return;
	}
	
	CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	uploadRunLoop = CFRunLoopGetCurrent();

	@synchronized(self) 
	{
		[self setIsUploading:YES];
		mLastBytesWritten = 0;
	}
	
	CFReadStreamOpen(readStream);
	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];
	
	mTimeoutTimer = [NSTimer
							scheduledTimerWithTimeInterval: sPostTimeout
							target: self
							selector: @selector(messageTimedOut:)
							userInfo: nil
							repeats: NO];
	[mTimeoutTimer retain];
	
	// CFRunLoop is not toll-free bridges to NSRunLoop
	while ([self isUploading])
        CFRunLoopRun();
		
	[pool release];
}

-(void)beingUploadProgressTracking {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:ISUploadProgressTimerInterval target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:uploadProgressTimer forMode:NSModalPanelRunLoopMode];
	
	while ( [[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode
									 beforeDate:[NSDate distantFuture]] &&
		   [self isUploading]);
	
	[pool release];
}

-(void)updateProgress:(NSArray *)args {
	[[self observer] uploadMadeProgress:self bytesWritten:[[args objectAtIndex:0] intValue]
						   ofTotalBytes:[[args objectAtIndex: 1] intValue]];										 
}

-(void)trackUploadProgress:(NSTimer *)timer 
{
	if(![self isUploading] || readStream == NULL) 
	{
		[timer invalidate];
		return;
	}
	
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty (readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, 3, &bytesWritten);
	CFRelease(bytesWrittenProperty);
	
	if(mLastBytesWritten == bytesWritten && bytesWritten >= [[self imageData] length]) //no change
		return;
	
	[mTimeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow: sPostTimeout]];
	
	@synchronized(self)
	{
		mLastBytesWritten = bytesWritten;
	}
	
	//NSLog(@"Postpone timer: %d (%d)", bytesWritten, [[self imageData] length]);
	
	if(bytesWritten >= [[self imageData] length])
	{
		[timer invalidate];
		[mTimeoutTimer invalidate];
		[[self observer] uploadCompleteWaitingForServerToResponse:self];
		//[mTimeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow: sPostTimeout*5]]; //wait until server proceed with request
	}
	else
		[[self observer] uploadMadeProgress:self bytesWritten:bytesWritten ofTotalBytes:[[self imageData] length]];
}

-(void)transferComplete
{
    NSString *error = [self validateResponse];
    if (error != nil)
    {
        [[self observer] uploadFailed:self withError:error];
    }
    else
    {
        if(mTimeoutTimer)
        {	
            [mTimeoutTimer invalidate];
            [mTimeoutTimer release];
            mTimeoutTimer = nil;
        }
        [[self observer] uploadComplete:self];
    }
	[self destroyUploadResources];
}

-(void)destroyUploadResources {
	@synchronized(self) 
	{
		[self setIsUploading:NO];
	}
	
	if(readStream != NULL) {
		CFReadStreamUnscheduleFromRunLoop(readStream, uploadRunLoop, kCFRunLoopCommonModes);
		CFReadStreamClose(readStream);
		CFRelease(readStream);
		readStream = NULL;
	}
	
	if(uploadRunLoop != NULL) {
		CFRunLoopStop(uploadRunLoop);
		uploadRunLoop = NULL;
	}
	
	[self setResponse:nil];
	
	if(mTimeoutTimer)
	{	
		[mTimeoutTimer invalidate];
		[mTimeoutTimer release];
		mTimeoutTimer = nil;
	}
}

-(NSString *)errorDescriptionForError:(CFStreamError *)err {
	
	if(err->domain == kCFStreamErrorDomainPOSIX) {
		return [NSString stringWithFormat:@"%d : %s", err->error, strerror(err->error)];
	} else if (err->domain == kCFStreamErrorDomainMacOSStatus) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Mac Error", @"Mac Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainNetDB) {
		return [NSString stringWithFormat:@"%d: %s", err->error, hstrerror(err->error)];
	} else if (err->domain == kCFStreamErrorDomainMach) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Mach Error", @"Mach Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainHTTP) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"HTTP Error", @"HTTP Error"), err->error ];
	}  else if (err->domain == kCFStreamErrorDomainSOCKS) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"SOCKS Error", @"SOCKS Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainSystemConfiguration) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"System Configuration error", @"System Configuration error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainSSL) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"SSL error", @"SSL error"), err->error ];
	} else {
		return [NSString stringWithFormat:@"%d", err->error];
	}
	
}

-(void)cancelUpload 
{
	@synchronized(self) 
	{
		if(![self isUploading])
			return;
		[self setIsUploading:NO];		
	}
	[[self observer] uploadCanceled:self];	
	[self destroyUploadResources];
}

-(void)appendToResponse {
	UInt8 buffer[4096];
	
	if(![self isUploading])
		return;
	
	CFIndex bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer));
	
	if (bytesRead < 0)
		NSLog(@"Warning: Error (< 0b from CFReadStreamRead");
	else
		[[self response] appendBytes:(void *)buffer length:(unsigned)bytesRead];
}

// Validate response and return error string if response are invalid
-(NSString *)validateResponse
{
    NSString *error = nil;
    
    ISXMLHelper *xml = [[ISXMLHelper alloc] initFromData:[self response]];
    if (xml)
    {
        NSXMLNode *node = [xml getFirstNodeByXPath:kResponseErrorNodeXPath];
        if (node)
            error = [[[NSString alloc] initWithString:[node stringValue]] autorelease];
        [xml release];
    }
    return error;
}

-(void)errorOccurred: (CFStreamError *)err {
	NSString *errorText = [self errorDescriptionForError:err];
	[[self observer] uploadFailed:self withError:errorText];
	[self destroyUploadResources];
}

-(NSMutableData *)response {
	return response;
}

-(void)setResponse:(NSMutableData *)data {
	if(data != response) {
		[response release];
		response = [data retain];
	}
}

-(NSData *)responseData {
	return [NSData dataWithData:[self response]];
}

-(NSData *)imageData {
	return imageData;
}

- (NSMutableData*)internalPreparePOSTData:(ISMediaData *)media
{	
	NSMutableDictionary *newparam=[NSMutableDictionary dictionary];
	
	//1.product name
	[newparam setObject:[[ISManager manager] getPluginVersion] forKey:@"uploader"];

	//2. product key
	[newparam setObject:kImageshakPlugInKey forKey:@"key"];
	
	NSString* myID = [[ISManager manager] getUserID];
	[newparam setObject:myID forKey:@"cookie"];
	
	//headerfield = [NSString stringWithFormat:@"imgshck=%@; myimages=%@; rem_bar=1; flashInstalled=0",myID, myID];	
	//headerfield = [NSString stringWithFormat:@"imgshck=%@; myimages=%@",myID, myID];	
	
	//3. public/private
	if ([media privacy] == 1)
		[newparam setObject:@"yes" forKey:@"public"];
	else
		[newparam setObject:@"no" forKey:@"public"];
	
	//4. XML
	[newparam setObject:@"yes" forKey:@"xml"];
	
	//5. Tag
	NSMutableString *str =[NSMutableString stringWithFormat:@"%@", [media tagValue]];
	if ([self batchTag] != NULL)
	{
		[str appendString: @" "];  //add space
		[str appendString: [self batchTag]];
	}
	
	[newparam setObject:[NSString stringWithFormat:@"%@", str] forKey:@"tags"];
	
	//6. Rembar
	if ([media canScale])
	{
		int val = [media rembarValue];
		[newparam setObject:[NSString stringWithFormat:@"%d", val] forKey:@"rembar"];
	}
	
	//7. Scale
	if ([media canScale] && [media scaleValue] > 0)
	{
		[newparam setObject:@"1" forKey:@"optimage"];
		NSArray *scaleTypes = [NSArray arrayWithObjects:	
							   @"0", @"100x100", @"150x150", @"320x320", @"640x640", @"800x800", 
							   @"1024x1024", @"1280x1280", @"1600x1600", @"resample", nil];
		
		NSString* scaleStr = [scaleTypes objectAtIndex:[media scaleValue]];
		[newparam setObject:scaleStr forKey:@"optsize"];
	}
	
	NSArray *keys=[newparam allKeys];
	unsigned i, c=[keys count];
 	NSMutableData *data=[NSMutableData data];
	
	for (i=0; i<c; i++)
	{
		NSString *k=[keys objectAtIndex:i];
		NSString *v=[newparam objectForKey:k];
		
		NSString *addstr = [NSString stringWithFormat:
							@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
							[self boundary], k, v];
		
		[data appendData:[addstr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return data;
}

-(NSData *)prepareMediaData:(ISMediaData *)anMedia
{
	NSData* imageBinary = [NSData dataWithContentsOfFile:[anMedia name]]; //TODO: release this data
	NSMutableData* theData = [self internalPreparePOSTData:anMedia];
	
	NSString *lastpart = [[anMedia name] lastPathComponent];
	NSString *content_type = [anMedia mimeType];

	NSString *filename_str = [NSString stringWithFormat:
							  @"--%@\r\nContent-Disposition: form-data; name=\"fileupload\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
							  [self boundary], lastpart, content_type];
	NSString *endmark = [NSString stringWithFormat: @"\r\n--%@--", [self boundary]];

	[theData appendData:[filename_str dataUsingEncoding:NSUTF8StringEncoding]];
	[theData appendData:imageBinary];
	[theData appendData:[endmark dataUsingEncoding:NSUTF8StringEncoding]];
	
	return theData;
}

-(void)setImageData:(NSData *)imgData 
{
	if(imageData != imgData) {
		[imageData release];
		imageData = [imgData retain];
	}
}

-(BOOL)isUploading 
{
	return isUploading;
}

-(void)setIsUploading:(BOOL)v 
{
	isUploading = v;
}

-(NSString *)filename 
{
	return filename;
}

-(void)setFilename:(NSString *)fn 
{
	if(fn != filename) 
    {
		[filename release];
		filename = [fn retain];
	}
}

-(NSArray *)keywords 
{
	return keywords;
}

-(void)setKeywords:(NSArray *)kw 
{
	if(kw != keywords) 
    {
		[keywords release];
		keywords = [kw retain];
	}
}

-(NSString *)boundary
{
	return [NSString stringWithString:mBoundary];
}

- (NSString *)getUploadImageUrl
{
    NSMutableArray *address = [NSMutableArray array];
    struct hostent *host_entry;
    host_entry = gethostbyname((char*)[ImageshackHostName cStringUsingEncoding:NSASCIIStringEncoding]);
    if (host_entry) 
    {
        struct in_addr ip_addr;
        char **ptr;
        
        ptr = host_entry->h_addr_list;
        while (*ptr) 
        {
            memcpy((void*)&ip_addr, *ptr, host_entry->h_length);
            [address addObject:[NSString stringWithCString:inet_ntoa(ip_addr) encoding:NSASCIIStringEncoding]];
            ptr++;
        }
    }
    NSString *uploadAddr = nil;
    if (address && ([address count] > 0))
    {
        int index = random() % [address count];
        uploadAddr = [[NSString alloc] initWithFormat:@"http://%@%@", [address objectAtIndex:index], ImageshackImageUploadAPIPath];
    }
    if (uploadAddr == nil)
        uploadAddr = [[NSString  alloc] initWithString:ImageshackImageUploadHostname];
    return uploadAddr;
}

-(void)setBoundary:(NSString*)boundary
{
	if (mBoundary) [mBoundary release];
	mBoundary = [[NSString alloc] initWithString:boundary];
}

- (void)setBatchTags:(NSString *)value
{
    if (mBatchTag) [mBatchTag release];
    mBatchTag = [[NSString alloc] initWithString:value];
}

-(NSString *)batchTag
{
	return mBatchTag;
}

@end
