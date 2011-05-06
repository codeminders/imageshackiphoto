#import <Cocoa/Cocoa.h>

@interface Image : NSObject 
{
@private
	NSImage *m_Image;
	NSImage *m_PreviewImage;
	NSString *m_Tag;
	int m_ScaleID;
	int m_RembarValue;
	int m_Privacy;
	bool m_Uploaded;
	unsigned m_Bytes;
	NSString *m_Name;
	NSString *m_PreviewPath;
}

- (id)initWithContentsOfFile:(NSString *)fileName;

-(NSString *)previewPath;
-(void)setPreviewPath:(NSString *)value;
-(NSString *)name;
-(void)setNameValue:(NSString *)value;
-(NSString *)tagValue;
-(void)setTagValue:(NSString *)value;
-(int)scaleValue;
-(void)setScale:(int)scaleID;
-(int)rembarValue;
-(void)setRembar:(int)value;
-(int)privacy;
-(void)setPrivacy:(int)value;
-(BOOL)uploaded;
-(void)setUploaded:(BOOL)value;
-(unsigned)bytesCount;
-(NSImage *)image;
-(NSImage *)previewImage;

-(BOOL)isImageFile:(NSString *)fileName;
-(BOOL)isSupportedType:(NSString *)fileName;

@end
