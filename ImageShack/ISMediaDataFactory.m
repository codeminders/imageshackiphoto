#import "ISMediaDataFactory.h"
#import "ISMediaData.h"
#import "ISImageData.h"
#import "ISVideoData.h"

static ISMediaDataFactory *mediaDataFactory = nil;

@implementation ISMediaDataFactory

// Class method. Return instance of MediaDataFactory class.
+ (ISMediaDataFactory *)factory
{
	if (mediaDataFactory == nil)
		mediaDataFactory = [[ISMediaDataFactory alloc] init];
	return mediaDataFactory;
}

- (id)init
{
	// Call parent init method
	self = [super init];
	if (self) {
		// Init private data
		NSArray *extensions = [NSArray arrayWithObjects: 
								@"jpg",	@"jpeg", @"png", @"gif", 
								@"bmp", @"tiff", @"tif", @"swf",
								@"pdf",	@"flv",	 @"mp4", @"m4v",
								@"wmv",	@"3gp",  @"avi", @"mov",
								@"mkv",	nil];
		// Mimetypes					
		NSArray *mimeTypes = [NSArray arrayWithObjects: 
								@"image/jpeg",		@"image/jpeg",	@"image/png",	@"image/gif", 
								@"image/bmp",		@"image/tiff",	@"image/tiff",	@"application/x-shockwave-flash",
								@"application/pdf",	@"video/x-flv", @"video/mp4",	@"video/x-m4v",
								@"video/x-ms-wmv",	@"video/3gpp",	@"video/avi",	@"video/quicktime",
								@"video/x-matroska",nil];
		
		mTypes = [[NSDictionary dictionaryWithObjects:mimeTypes forKeys:extensions] retain];
	}
	return self;
}

- (void)dealloc
{
	if (mTypes)
		[mTypes release];
	[super dealloc];
}

- (ISMediaData *)createMediaData:(NSString *)filePath
{
	MediaType type = [self fileMediaType:filePath];
	ISMediaData *theMedia = nil;
	
	if (type.className != nil && type.typeName != nil) 
    {
		if ([type.className compare:@"video"] == NSOrderedSame) 
        {
			theMedia = [[[ISVideoData alloc] initWithFilePath:filePath type:type] autorelease];
		}
		else if ([type.className compare:@"image"] == NSOrderedSame) 
        {
			theMedia = [[[ISImageData alloc] initWithFilePath:filePath type:type] autorelease];
		}
	}
	return theMedia;
}

- (MediaType)fileMediaType:(NSString *)filePath
{
	MediaType type;
	
	type.className = nil;
	type.typeName = nil;
	// Get file extensions
	NSString *extension = [filePath pathExtension];
	if (extension != nil && [extension length] > 0) 
    {
		// Find mimeType in type dictionary by file extension
		NSString *mimeType = [mTypes objectForKey:[extension lowercaseString]];
		if (mimeType != nil) 
        {
			// separate mime class name and mime type name
			NSArray *components = [mimeType componentsSeparatedByString:@"/"];

			if (components != nil && [components count] == 2) 
            {
				type.className = [components objectAtIndex:0];
				type.typeName = [components objectAtIndex:1];
			}
		}
	}
	return type;
}

@end