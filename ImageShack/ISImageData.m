#import "ISImageData.h"

@implementation ISImageData

- (void)dealloc
{
	if (mImage)
		[mImage release];
	[super dealloc];
}

- (id)media
{
	if (!mImage)
	{
		mImage = [[[NSImage alloc] initWithContentsOfFile:[self name]] retain];
	}
	return mImage;
}

- (id)previewMedia
{
	return [self media];
}

- (BOOL)canScale
{
	return YES;
}

@end
