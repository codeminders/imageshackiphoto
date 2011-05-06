#import <Cocoa/Cocoa.h>

// Data mimetype
// 	image/png
//	className - image
//	typeName - png
typedef struct MediaType {
	NSString *className;
	NSString *typeName;
} MediaType;

@interface ISMediaData : NSObject {
@private
	NSString *mMimeType;
	MediaType mMediaType;
	NSString *mFilePath;
	NSString *mPreviewPath;
	bool mUploaded;
	unsigned mBytes;
	NSString *mTag;
	int mScaleID;
	int mRembarValue;
	int mPrivacy;
	
@protected
	NSImage *mPreviewImage;
}

- (id)initWithFilePath:(NSString *)filePath type:(MediaType)type;
- (void)dealloc;
- (MediaType)type;
- (NSString *)mimeType;
- (NSString *)previewPath;
- (void)setPreviewPath:(NSString *)value;
- (NSString *)name;
- (void)setNameValue:(NSString *)value;
- (NSString *)tagValue;
- (void)setTagValue:(NSString *)value;
- (int)scaleValue;
- (void)setScale:(int)scaleID;
- (int)rembarValue;
- (void)setRembar:(int)value;
- (int)privacy;
- (void)setPrivacy:(int)value;
- (BOOL)uploaded;
- (void)setUploaded:(BOOL)value;
- (unsigned)bytesCount;
- (NSImage *)previewImage;
- (id)media;
- (id)previewMedia;
- (BOOL)canScale;

@end;