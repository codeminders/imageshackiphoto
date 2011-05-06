#import <Cocoa/Cocoa.h>
#import "ISMediaData.h"

@interface ISImageData : ISMediaData {
@private
	NSImage	*mImage;
}

- (void)dealloc;
- (id)media;
- (id)previewMedia;
- (BOOL)canScale;

@end
