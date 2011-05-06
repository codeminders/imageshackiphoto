#import "ImageshackRequest.h"
#import "ISConstants.h"
#import "Utilities.h"
#import "ISManager.h"

#define TIMEOUTINTERVAL  40.0

@implementation ImageshackRequest

+ (ImageshackRequest *)requestWithDelegate:(id)aDelegate
{
	return [[[ImageshackRequest alloc] initWithDelegate:aDelegate] autorelease];
}

-(ImageshackRequest*)initWithDelegate:(id)aDelegate
{
	if ((self = [super init]))
	{
		m_Delegate = [aDelegate retain];
		
		m_HttpRequest = [[ImageshackHTTPRequest requestWithDelegate:m_Delegate 
					timeoutInterval:TIMEOUTINTERVAL] retain];
		
		m_Boundary = [[NSString alloc] initWithFormat:@"%@%d", SEPARATOR, random()];
//		NSLog(m_Boundary);
		m_Image = [[Image alloc]init];
	}
	return self;
}

- (void)setBatchTags:(NSString *)value
{
    if (m_BatchTags) [m_BatchTags release];
    m_BatchTags = [[NSString alloc] initWithString:value];
}

-(BOOL)get:(NSString*)url sresponse:(ISResponse**)oResponse
{
	return [m_HttpRequest GET:url userInfo:nil sresponse:oResponse];
}

-(BOOL)get:(NSString*)url response:(NSMutableString*)oResponse
{
	return [m_HttpRequest GET:url userInfo:nil response:oResponse];
}

-(BOOL)get:(NSString*)url data:(NSMutableData*)oResponse;
{
	return [m_HttpRequest GET:url userInfo:nil data:oResponse];
}

-(BOOL)post:(Image*)imageItem response:(NSMutableString*)oResponse
{		
    // Init m_Image
	if (m_Image) [m_Image release]; // Non-valid Image. Use imageItem instead.
    m_Image = [[Image alloc] initWithContentsOfFile:[imageItem name]];
	[m_Image setScale: [imageItem scaleValue]];
	[m_Image setRembar: [imageItem rembarValue]];
	[m_Image setPrivacy: [imageItem privacy]];

	NSString *tag = [imageItem tagValue];
	if (tag)
		[m_Image setTagValue:tag];
	else
	{
		[m_Image setTagValue:@""];
	}
	
	//PrepareData
	NSData* imageBinary = [NSData dataWithContentsOfFile:[imageItem name]];	
	NSMutableData* theData = [self internalPreparePOSTData:imageItem];

	NSString *lastpart = [[imageItem name] lastPathComponent];
	NSString *extension = [[imageItem name] pathExtension];
	NSString *content_type = @"image/jpeg";
	
	if ([extension isEqualToString:@"png"]) {
		content_type = @"image/png";
	}
	else if ([extension isEqualToString:@"gif"]) {
		content_type = @"image/gif";
	}
	else if ([extension isEqualToString:@"pict"] || [extension isEqualToString:@"pct"]) {
		content_type = @"image/pict";
	}
	else if ([extension isEqualToString:@"bmp"]) {
		content_type = @"image/bmp";
	}
	else if ([extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"] ) {
		content_type = @"image/tiff";
	}
	else if ([extension isEqualToString:@"swf"] || [extension isEqualToString:@"swf"] ) {
		content_type = @"image/swf";
	}
	
	NSString *filename_str = [NSString stringWithFormat:
		@"--%@\r\nContent-Disposition: form-data; name=\"fileupload\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
		m_Boundary, lastpart, content_type];

	[theData appendData:[filename_str dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *endmark = [NSString stringWithFormat: @"\r\n--%@--", m_Boundary];

	[theData appendData:imageBinary];
	[theData appendData:[endmark dataUsingEncoding:NSUTF8StringEncoding]];
	
//	NSString *str = [[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding];
//	NSLog(str);

	return [m_HttpRequest POST:ImageshackServerURL data:theData 
				separator:[self getBoundary] userInfo:nil response:oResponse];
}

-(NSString *)getBoundary
{
	return [NSString stringWithString:m_Boundary];
}

-(void)setBoundary:(NSString*)boundary
{
	if (m_Boundary) [m_Boundary release];
	m_Boundary = [[NSString alloc] initWithString:boundary];
}

- (void)dealloc
{	
	if (m_Delegate)
		[m_Delegate release];
	[m_HttpRequest release];
	if (m_Boundary) [m_Boundary release];
	if (m_Image) [m_Image release];
	if (m_BatchTags) [m_BatchTags release];
	[super dealloc];
}
@end

@implementation ImageshackRequest (DataPreparer)
- (NSMutableData*)internalPreparePOSTData:(Image*)image
{	
	NSMutableData *data=[NSMutableData data];
	NSMutableDictionary *newparam=[NSMutableDictionary dictionary];

	//1.product name
	[newparam setObject:[[ISManager manager] getPluginVersion] forKey:@"uploader"];
	
	//2. public/private
	if ([image privacy] == 1)
		[newparam setObject:@"yes" forKey:@"public"];
	else
		[newparam setObject:@"no" forKey:@"public"];
	
	//3. XML
	[newparam setObject:@"yes" forKey:@"xml"];
	
	//4. Tag
	NSMutableString *str =[NSMutableString stringWithFormat:@"%@",
						[image tagValue]];
	if (m_BatchTags != NULL)
	{
		[str appendString: @" "];  //add space
		[str appendString: m_BatchTags];
	}

	
	[newparam setObject:[NSString stringWithFormat:@"%@", str] forKey:@"tags"];
//	NSLog(str);
		
	//5. Rembar
	int val = [image rembarValue];
	[newparam setObject:[NSString stringWithFormat:@"%d", val] forKey:@"rembar"];

	//6. Scale
	if ([image scaleValue] > 0)
	{
		[newparam setObject:@"1" forKey:@"optimage"];
		NSArray *scaleTypes = [NSArray arrayWithObjects:	
			@"0", @"100x100", @"150x150", @"320x320", @"640x640", @"800x800", 
			@"1024x1024", @"1280x1280", @"1600x1600", @"resample", nil];
		
		NSString* scaleStr = [scaleTypes objectAtIndex:[image scaleValue]];
		[newparam setObject:scaleStr forKey:@"optsize"];
	}

	NSArray *keys=[newparam allKeys];
	unsigned i, c=[keys count];
 	
	for (i=0; i<c; i++)
	{
		NSString *k=[keys objectAtIndex:i];
		NSString *v=[newparam objectForKey:k];
		
		NSString *addstr = [NSString stringWithFormat:
			@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
			[self getBoundary], k, v];

		[data appendData:[addstr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return data;
}

@end
