#import "ISVideoData.h"
#import "MovieUtils.h"

@interface ISVideoData (Private)

- (ImageDataArray *)histogramForImage:(CGImageRef)theImage;
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
- (ImageDataArray *)histogramForImage2:(NSImage *)theImage;
#endif
- (ImageDataArray *)medianFromHist:(NSMutableArray *)hists;
- (ImageDataArray *)getClosest:(NSMutableArray *)hists median:(ImageDataArray *)medians;
- (NSImage *)makeSimplePreview;
- (NSImage *)makePreview;

@end

#pragma mark Private section
@implementation ISVideoData (Private)

- (ImageDataArray *)histogramForImage:(CGImageRef)theImage
{
	ImageDataArray *hist = [[ImageDataArray alloc] init];
	
	size_t width = CGImageGetWidth(theImage);
	size_t height = CGImageGetHeight(theImage);
    
	int	i, j, size;
	char *data;
	
    // Prepare buffer for image data
	data = PrepareBitmapBuffer(theImage, &size);
	if (data != NULL)
	{
        // Get ARGB data from image
		if (RGBDataFromImage(theImage, data, &size))
		{
			int index = 0;
            // Create histogram for current image
			for (i = 0; i < height; ++i)
			{
				for (j = 0; j < width; ++j)
				{
					index++; // Pass alpha component
					[hist incrementAtIndex: data[index++]];         // R
					[hist incrementAtIndex: data[index++] + 256];   // G + 256
					[hist incrementAtIndex: data[index++] + 512];   // B + 512
				}
			}
		}
        // Release image data buffer
		ReleaseBitmapBuffer(data);
		data = NULL;
	}
	return hist;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
- (ImageDataArray *)histogramForImage2:(NSImage *)theImage
{
	ImageDataArray *hist = [[ImageDataArray alloc] init];
	NSSize imgSize = [theImage size];
    
	size_t width = (size_t)imgSize.width;
	size_t height = (size_t)imgSize.height;
    
	int	i, j, size;
	char *data;
	
    // Prepare buffer for image data
    size = width * height * 4;
	data = malloc(size);
	if (data != NULL)
	{
        memset(data, 0, size);
        // Get ARGB data from image
		if (RGBDataFromNSImage(theImage, data, &size))
		{
			int index = 0;
            // Create histogram for current image
			for (i = 0; i < height; ++i)
			{
				for (j = 0; j < width; ++j)
				{
					index++; // Pass alpha component
					[hist incrementAtIndex: data[index++]];         // R
					[hist incrementAtIndex: data[index++] + 256];   // G + 256
					[hist incrementAtIndex: data[index++] + 512];   // B + 512
				}
			}
		}
        // Release image data buffer
        free(data);
		data = NULL;
	}
	return hist;
}
#endif

- (ImageDataArray *)medianFromHist:(NSMutableArray *)hists
{
	ImageDataArray *median = [[ImageDataArray alloc] init];
	
	int i, j, count = [hists count];
	for (i = 0; i < count; ++i)
	{
		for (j = 0; j < kMaxImageDataArray; ++j)
		{
			ImageDataArray *hist = [hists objectAtIndex:i];
			
			[median setValueAtIndex:j value:[median valueAtIndex:j] + [hist valueAtIndex:j]];
		}
	}
	for (j = 0; j < kMaxImageDataArray; ++j)
	{
		[median setValueAtIndex:j value:[median valueAtIndex:j] / count];
	}
	return median;
}

- (ImageDataArray *)getClosest:(NSMutableArray *)hists median:(ImageDataArray *)medians
{
	int count = [hists count];
	ImageDataArray *diffs = [[ImageDataArray alloc] initWithArraySize:count];
	int i, j;
	
	count = [hists count];
	for (i = 0; i < count; ++i)
	{
		ImageDataArray *hist = [hists objectAtIndex:i];
        
		UInt64 sum = 0;
		for (j = 0; j < kMaxImageDataArray; ++j)
		{
			UInt64 localDiff = ([medians valueAtIndex:j] - [hist valueAtIndex:j]);
			sum += (localDiff * localDiff);
		}
		[diffs setValueAtIndex:i value:sum];
	}
	
	UInt64 min = UINT64_C(932838457459459);
	int min_n = count;
	
	for (i = 0; i < count; ++i)
	{
		if ([diffs valueAtIndex:i] < min)
		{
			min = [diffs valueAtIndex:i];
			min_n = i;
		}
	}
	[diffs release];
	return [hists objectAtIndex:min_n];
}

- (NSImage *)makeSimplePreview
{
    QTMovie *theMovie = [self media];
    
    if (!theMovie)
        return nil;
    
    return [theMovie posterImage];
}

- (NSImage *)makePreview
{
    QTMovie *theMovie = [self media];
    
    if (!theMovie)
        return nil;

    QTTime time;
    
    if ([[MovieTimeCache cache] lookup:[self name] time:&time] == NO)
    {
        // Goto beginning of movie
        [theMovie gotoBeginning];
        
        // Check movie size
        NSValue *attr = [theMovie attributeForKey:QTMovieCurrentSizeAttribute];
        NSSize sizeAttr = [attr sizeValue];
        if (sizeAttr.width == 0.0 || sizeAttr.height == 0)
            return [theMovie currentFrameImage];
        
        // Create local autorelease pool
        NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
        NSMutableArray *hists = [[NSMutableArray alloc] init];
        
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
//        NSDictionary *frameAttr = [NSDictionary dictionaryWithObject: QTMovieFrameImageTypeCGImageRef 
//                                                              forKey: QTMovieFrameImageType];
        NSDictionary *frameAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                        QTMovieFrameImageTypeCGImageRef, QTMovieFrameImageType,
                                        [NSNumber numberWithBool:NO], QTMovieFrameImageDeinterlaceFields,
                                        nil
                                   ];
#endif
        int counter = 0;
        
        // Check first 75 frames
        while (counter < 75)
        {
            // Get image at current time
            time = [theMovie currentTime];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
            CGImageRef image = (CGImageRef)[theMovie frameImageAtTime: time 
                                                       withAttributes: frameAttr 
                                                                error: NULL];
#else
            NSImage *image = [theMovie frameImageAtTime:time];
#endif
            if (image)
            {
                // Create histogram for current image
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
                ImageDataArray *hist = [self histogramForImage:image];
#else
                ImageDataArray *hist = [self histogramForImage2:image];
#endif
                if (hist)
                {
                    // Set time for histogram and add it to hists array
                    [hist forTime:time];
                    [hists addObject:hist];
                    [hist autorelease];
                }
            }
            // Goto next frame
            [theMovie stepForward];
            counter++;
        }
        
        if ([hists count] > 0)
        {
            ImageDataArray *hist = nil;
            
            if ([hists count] == 1)
                hist = [hists objectAtIndex:0];
            else
            {
                ImageDataArray *median = [self medianFromHist:hists];
                hist = [self getClosest:hists median:median];
                [median release];
            }
            
            if (hist)
            {
                if ([hist valueAtIndex:0xff] == (sizeAttr.width * sizeAttr.height))
                {
                    [theMovie gotoBeginning];
                    time = [theMovie currentTime];
                }
                else
                {
                    time = [hist time];
                }
            }
        }
        else
        {
            [theMovie gotoBeginning];
            time = [theMovie currentTime];
        }
        
        [hists release];						// Release hists array
        [localPool release];					// Release local pool
        
        [[MovieTimeCache cache] push:[self name] time:time];
    }
    return [theMovie frameImageAtTime:time];
}

@end


#pragma mark Public section
@implementation ISVideoData

- (void)dealloc
{
	if (mMovie)
		[mMovie dealloc];
	[super dealloc];
}

- (id)media
{
	if (!mMovie)
	{
		mMovie = [[[QTMovie alloc] initWithFile:[self name] error:NULL] retain];
	}
	return mMovie;
}

- (id)previewMedia	
{
	return [self previewImage];
}

- (NSImage *)previewImage
{
	if (!mPreviewImage)
	{
        NSImage *preview = [self makeSimplePreview];
        if (preview)
            mPreviewImage = [preview retain];
	}
	return mPreviewImage;
}

- (int)scaleValue
{
	return 0;
}

- (int)rembarValue
{
	return 0;
}

@end
