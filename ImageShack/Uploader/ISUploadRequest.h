#import <Cocoa/Cocoa.h>
#import "ISMediaData.h"

@class ISUploadRequest;

// protocol for monitoring an upload
@protocol ISUploadRequestObserver
-(void)uploadMadeProgress:(ISUploadRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes;
-(void)uploadFailed:(ISUploadRequest *)request withError:(NSString *)reason;
-(void)uploadTimedOut:(ISUploadRequest *)request;
-(void)uploadCanceled:(ISUploadRequest *)request;
-(void)uploadComplete:(ISUploadRequest *)request;
-(void)uploadCompleteWaitingForServerToResponse:(ISUploadRequest *)request;
@end

@interface ISUploadRequest : NSObject {
	CFRunLoopRef uploadRunLoop;
	CFReadStreamRef readStream;
	
	NSObject<ISUploadRequestObserver> *observer;
	BOOL isUploading;
	NSMutableData *response;
	NSString *mUploadURL;
	NSData *imageData;
	NSString *filename;
	NSArray *keywords;
	NSString *mBoundary;
	NSString *mBatchTag;
	NSTimer *mTimeoutTimer;
	int mLastBytesWritten;
}

+(ISUploadRequest *)uploadRequest;
-(void)uploadMediaData:(ISMediaData *)theMedia observer:(NSObject<ISUploadRequestObserver> *)anObserver;


-(void)cancelUpload;
-(NSData *)responseData;

// the parameters set data for the upload
-(NSString *)filename;
-(NSData *)imageData; 
-(NSArray *)keywords;

-(void)setBatchTags:(NSString *)value;
-(NSString *)batchTag;
-(void)setPostUploadURL:(NSString *)uploadUrl;

@end
