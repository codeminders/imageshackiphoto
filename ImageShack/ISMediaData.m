#import "ISMediaData.h"
#import "ISConstants.h"

@interface ISMediaData (Private)

- (void)setMediaType:(MediaType)type;

@end


@implementation ISMediaData (Private)

- (void)setMediaType:(MediaType)type
{
	if (mMediaType.className)
		[mMediaType.className release];
	if (mMediaType.typeName)
		[mMediaType.typeName release];
	
	mMediaType.className = [[NSString stringWithString:type.className] retain];
	mMediaType.typeName = [[NSString stringWithString:type.typeName] retain];
	
	if (mMimeType)
		[mMimeType release];
	mMimeType = [[NSString stringWithFormat:@"%@/%@", mMediaType.className, mMediaType.typeName] retain];
}

@end

@implementation ISMediaData

- (id)initWithFilePath:(NSString *)filePath type:(MediaType)type;
{
	self = [super init];
	if (self != nil) {
		mMediaType.className = nil;
		mMediaType.typeName = nil;
		[self setMediaType:type];
		[self setNameValue:filePath];
		[self setScale: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultScalePreferenceKey]];
		[self setRembar: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultRembarPreferenceKey]];
		[self setPrivacy: [[NSUserDefaults standardUserDefaults] integerForKey:DefaultPrivacyPreferenceKey]];
		[self setUploaded:NO];
        [self setTagValue:@""];
	}
	return self;
}

- (void)dealloc
{
	if (mMediaType.className)
		[mMediaType.className release];
	if (mMediaType.typeName)
		[mMediaType.typeName release];
	// Release type
	if (mMimeType)
		[mMimeType release];
	// Release file path
	if (mFilePath)
		[mFilePath release];
	// Release preview file path
	if (mPreviewPath)
		[mPreviewPath release];
	// Release preview image object
	if (mPreviewImage)
		[mPreviewImage release];
	[super dealloc];
}

- (MediaType)type
{
	return mMediaType;
}

- (NSString *)mimeType
{
	return mMimeType;
}

- (NSString *)name
{
	return mFilePath;
}

- (void)setNameValue:(NSString *)value
{
	if (mFilePath) [mFilePath release];
	mFilePath = [[NSString alloc] initWithString:value];
}

- (NSImage *)previewImage
{
	if (!mPreviewImage)
	{
		mPreviewImage = [[[NSImage alloc] initWithContentsOfFile:
						  [self previewPath]] retain];
		//	NSLog(@"requested preview: %@", [self previewPath]); TODO. Check for performance
	}
	return mPreviewImage;
}

- (NSString *)previewPath
{
	return [[mPreviewPath retain] autorelease];
}

- (void)setPreviewPath:(NSString *)fileName
{
	if (mPreviewPath) [mPreviewPath release];
	mPreviewPath = [[NSString alloc] initWithString:fileName];
}

- (NSString *)tagValue 
{
	return mTag;
}

- (void)setTagValue:(NSString *)value
{
	if (!value)
		value = @"";
    
	if (mTag) [mTag release];
    mTag = [[NSString alloc] initWithString:value];
}

- (int)scaleValue
{
	return mScaleID;
}

- (void)setScale:(int)scaleID
{
	mScaleID = scaleID;
}

- (int)rembarValue
{
	return mRembarValue;
}

- (void)setRembar:(int)value
{
	mRembarValue = value;
}

- (int)privacy
{
	return mPrivacy;
}

- (void)setPrivacy:(int)value
{
	mPrivacy = value;
}

- (BOOL)uploaded
{
	return mUploaded;
}

- (void)setUploaded:(BOOL)value
{
	mUploaded = value;
}

- (unsigned)bytesCount
{
	if (mBytes == 0)
	{
		NSData *data = [NSData dataWithContentsOfFile:[self name]];
		mBytes = [data length];
	}
	
	return mBytes;
}

- (id)media
{
	return nil;
}

- (id)previewMedia
{
	return nil;
}

- (BOOL)canScale
{
	return NO;
}

@end
