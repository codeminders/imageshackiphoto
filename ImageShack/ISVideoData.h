#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "ISMediaData.h"

@interface ISVideoData : ISMediaData {
@private
	QTMovie	*mMovie;
}

- (void)dealloc;
- (id)media;
- (id)previewMedia;
- (int)scaleValue;
- (int)rembarValue;
@end
