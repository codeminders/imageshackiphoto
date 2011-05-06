#import "Image.h"
#import "ISConstants.h"

@implementation Image

- (id)initWithContentsOfFile:(NSString *)fileName;
{

	// In the first we have to check if file is image or has another supported type
	// If non-supported type our class is not created
	if (([self isSupportedType:fileName] == NO))
	{
		return NULL;
	}

	[self setNameValue:fileName];
	[self setScale: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultScalePreferenceKey]];
	[self setRembar: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultRembarPreferenceKey]];
	[self setPrivacy: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultPrivacyPreferenceKey]];
	[self setUploaded:NO];	
	return self;
}

- (void)dealloc
{
	if (m_Tag) [m_Tag release];
	if (m_Name) [m_Name release];
	[m_Image release];
	[m_PreviewImage release];
	[super dealloc];
}

-(NSImage *)image
{
	if (!m_Image)
	{
		m_Image = [[[NSImage alloc] initWithContentsOfFile:
				[self name]] retain];
	}
	return m_Image;
}

-(NSImage *)previewImage
{
	if (!m_PreviewImage)
	{
		m_PreviewImage = [[[NSImage alloc] initWithContentsOfFile:
					[self previewPath]] retain];
//	NSLog(@"requested preview: %@", [self previewPath]); TODO. Check for performance
	}
	return m_PreviewImage;
}

-(NSString *)previewPath
{
	return [[m_PreviewPath retain] autorelease];
}
-(void)setPreviewPath:(NSString *)fileName
{
	if (m_PreviewPath) [m_PreviewPath release];
	m_PreviewPath = [[NSString alloc] initWithString:fileName];
}

-(NSString *)name
{
	return m_Name;
}

-(void)setNameValue:(NSString *)value
{
	if (m_Name) [m_Name release];
	m_Name = [[NSString alloc] initWithString:value];
}

- (NSString *)tagValue 
{
	return m_Tag;
}

- (void)setTagValue:(NSString *)value
{
	if (!value)
	{
		value = @"";
	}
    
	if (m_Tag) [m_Tag release];
    m_Tag = [[NSString alloc] initWithString:value];
}

-(int)scaleValue
{
	return m_ScaleID;
}

-(void)setScale:(int)scaleID
{
	m_ScaleID = scaleID;
}

-(int)rembarValue
{
	return m_RembarValue;
}

-(void)setRembar:(int)value
{
	m_RembarValue = value;
}

-(int)privacy
{
	return m_Privacy;
}
-(void)setPrivacy:(int)value
{
	m_Privacy = value;
}

-(BOOL)uploaded
{
	return m_Uploaded;
}
-(void)setUploaded:(BOOL)value
{
	m_Uploaded = value;
}

-(unsigned)bytesCount
{
	if (m_Bytes == 0)
	{
		NSData *data = [NSData dataWithContentsOfFile:[self name]];
		m_Bytes = [data length];
	}
	
	return m_Bytes;
}

// Check if non-image files (like .swf). Return YES if file is .jpg, .png, pict...
-(BOOL)isImageFile:(NSString *)fileName
{
	return YES;
}

-(BOOL)isSupportedType:(NSString *)fileName
{
	BOOL reply = YES;
	NSString *ext = [fileName pathExtension];
	if (([ext caseInsensitiveCompare: @"pict"] == NSOrderedSame) ||
		([ext caseInsensitiveCompare: @"pct"] == NSOrderedSame) ||
		([ext caseInsensitiveCompare: @"icns"] == NSOrderedSame))
		reply = NO;		
	return reply;
}

@end
