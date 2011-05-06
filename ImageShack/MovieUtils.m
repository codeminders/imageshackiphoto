#import "MovieUtils.h"

static MovieTimeCache *timeCache = nil;

// Calculate buffer size for image raw data
int GetRGBBitmapDataSizeForImage(CGImageRef theImage)
{
	size_t width = CGImageGetWidth(theImage);
	size_t height = CGImageGetHeight(theImage);
	
	return width * height * 4;
}

// Allocate memory for raw data of image
// Return pointer to memory block and size of block
void* PrepareBitmapBuffer(CGImageRef theImage, /* out */int *size)
{
	int bitmapBytesCount = GetRGBBitmapDataSizeForImage(theImage);
	
	// Allocate memory
	void *bitmapData = malloc(bitmapBytesCount);
	
	// Set data size
	if (bitmapData && size)
		*size = bitmapBytesCount;

	// Clear data
	memset(bitmapData, 0, bitmapBytesCount);
	return bitmapData;
}

// Release buffer
void ReleaseBitmapBuffer(void *buffer)
{
	if (buffer)
		free(buffer);
}

// Create graphic context for image
// Return new context. Context must be released by user.
CGContextRef CreateRGBContextForImage(CGImageRef theImage)
{
	CGContextRef	context;
	CGColorSpaceRef	colorSpace;
	int				bitmapBytesCount, bitmapBytesPerRow;
	void*			bitmapData;
	
	// Create RGB color space
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	if (!colorSpace)
	{
		NSLog(@"Could not create color space\n");
		return NULL;
	}
	
	size_t width = CGImageGetWidth(theImage);
	size_t height = CGImageGetHeight(theImage);
	
	bitmapBytesPerRow = (width * 4);
	bitmapBytesCount = bitmapBytesPerRow * height;
	
	// Allocate memory for bitmap data
	bitmapData = malloc(bitmapBytesCount);
	if (!bitmapData)
	{
		NSLog(@"Could not allocate memory for bitmap data\n");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}
	
	// Create RGB context for image
	context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
	if (!context)
	{
		NSLog(@"Could not create context\n");
		free(bitmapData);
	}
	CGColorSpaceRelease(colorSpace);
	return context;
}

// Get image raw data
// Return buffer pointer. If error return NULL.
void* RGBDataFromImage(CGImageRef theImage, void *buffer, int *size)
{
	if (!buffer || !size)
		return NULL;

	int bufferSize = GetRGBBitmapDataSizeForImage(theImage);
	if (*size < bufferSize)
		return NULL;
	
	CGContextRef context = CreateRGBContextForImage(theImage);
	if (!context)
		return NULL;
	
	size_t width = CGImageGetWidth(theImage);
	size_t height = CGImageGetHeight(theImage);
	CGRect rect = {{0, 0}, {width, height}};
	
	CGContextDrawImage(context, rect, theImage);
	
	void *data = CGBitmapContextGetData(context);
	if (data)
	{
		memcpy(buffer, data, bufferSize);
		*size = bufferSize;
	}
	CGContextRelease(context);
	if (data)
		free(data);
	return buffer;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
void* RGBDataFromNSImage(NSImage *image, void *buffer, int *size)
{
    NSSize imgSize = [image size];
    size_t pixelWidth = (size_t)imgSize.width;
    size_t pixelHeight = (size_t)imgSize.height;
    
    CGColorSpaceRef	colorSpace;
    
	// Create RGB color space
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	if (!colorSpace)
	{
		NSLog(@"Could not create color space\n");
		return NULL;
	}
    
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL, 
                                                   pixelWidth,  
                                                   pixelHeight, 
                                                   8 /*bitsPerComponent*/, 
                                                   0, 
                                                   colorSpace, 
                                                   kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapCtx flipped:NO]];
    [image drawInRect:NSMakeRect(0,0, pixelWidth, pixelHeight) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    int bufferSize = pixelWidth * pixelHeight * 4;
	void *data = CGBitmapContextGetData(bitmapCtx);
	if (data)
	{
		memcpy(buffer, data, bufferSize);
		*size = bufferSize;
	}
	CGContextRelease(bitmapCtx);
	CGColorSpaceRelease(colorSpace);
    
    return buffer;
}
#endif

#pragma mark ImageDataArray
@implementation ImageDataArray

- (id)init
{
	return [self initWithArraySize:kMaxImageDataArray];
}

- (id)initWithArraySize:(int)size
{
	mData = NULL;
	self = [super init];
	if (self)
	{
		mData = (UInt64*) malloc(size * sizeof(UInt64));
		if (!mData)
			return nil;
		mSize = (unsigned)size;
		[self clear];
	}
	return self;
}

- (void)dealloc
{
	if (mData)
	{
		free(mData);
		mData = NULL;
	}
	[super dealloc];
}

- (void)clear
{
	if (mData)
		memset(mData, 0, mSize * sizeof(UInt64));
}

- (UInt64)valueAtIndex:(unsigned)index
{
	if (mData && index < mSize)
		return mData[index];
	return UINT64_MAX;
}

- (UInt64)setValueAtIndex:(unsigned)index value:(UInt64)newValue
{
	if (mData && index < mSize)
	{
		mData[index] = newValue;
		return newValue;
	}
	return UINT64_MAX;
}

- (UInt64)incrementAtIndex:(unsigned)index
{
	if (mData && index < mSize)
	{
		mData[index] += 1;
		return mData[index];
	}
	return UINT64_MAX;
}

- (unsigned)size
{
	return mSize;
}

- (void)forTime:(QTTime)time
{
	mTime = time;
}

- (QTTime)time
{
	return mTime;
}

@end

@implementation MovieTimeCache

// Create object
+ (MovieTimeCache *)cache
{
    if (!timeCache)
        timeCache = [[MovieTimeCache alloc] init];
    return timeCache;
}

- (void)dealloc
{
    if (mDict)
    {
        [mDict release];
        mDict = nil;
    }
    [super dealloc];
}

- (void)push:(NSString *)name time:(QTTime)curTime
{
    if (!mDict)
        mDict = [[NSMutableDictionary alloc] init];
    
    if (mDict)
    {
        NSValue *value = [NSValue valueWithQTTime:curTime];
        [mDict setObject:value forKey:name];
    }
}

- (BOOL)lookup:(NSString *)name time:(QTTime*)retTime
{
    if (!retTime || !mDict || !name)
        return NO;
    
    NSValue *value = [mDict objectForKey:name];
    if (!value)
        return NO;
    *retTime = [value QTTimeValue];
    return YES;
}

@end