#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#define kMaxImageDataArray	768

int GetRGBBitmapDataSizeForImage(CGImageRef theImage);
void* PrepareBitmapBuffer(CGImageRef theImage, int *size);
void ReleaseBitmapBuffer(void *buffer);
CGContextRef CreateRGBContextForImage(CGImageRef theImage);
void* RGBDataFromImage(CGImageRef theImage, void *buffer, int *size);
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
    void* RGBDataFromNSImage(NSImage *image, void *buffer, int *size);
#endif

@interface ImageDataArray : NSObject {
	UInt64 *mData;
	unsigned mSize;
	QTTime mTime;
}

- (id)init;
- (id)initWithArraySize:(int)size;
- (void)dealloc;
- (void)clear;
- (UInt64)valueAtIndex:(unsigned)index;
- (UInt64)setValueAtIndex:(unsigned)index value:(UInt64)newValue;
- (UInt64)incrementAtIndex:(unsigned)index;
- (unsigned)size;
- (void)forTime:(QTTime)time;
- (QTTime)time;
@end

@interface MovieTimeCache : NSObject
{
    NSMutableDictionary *mDict;
}

+ (MovieTimeCache *)cache;
- (void)dealloc;
- (void)push:(NSString *)name time:(QTTime)curTime;
- (BOOL)lookup:(NSString *)name time:(QTTime*)retTime;

@end