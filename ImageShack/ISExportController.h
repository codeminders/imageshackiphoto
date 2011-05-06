#import <Cocoa/Cocoa.h>
#import "ExportPluginProtocol.h"
#import "ImageshackRequest.h"
#import "ISConstants.h"
#import "SecurityInterface/SFKeychainSettingsPanel.h"
#import "ISUploadRequest.h"

enum StatusCode
{
	kOtherErrors,
	kNoConnection,
	kUploadSucceeded,
	kTryToUpload,
	kUploading,
	kCancelExport,
	kNotSigned
};

@interface ISExportController : NSObject <ExportPluginProtocol, ISUploadRequestObserver> 
{
	id <ExportImageProtocol> mExportMgr;
	
	IBOutlet NSBox <ExportPluginBoxProtocol> *mSettingsBox;
	IBOutlet NSControl *mFirstView;
			
	NSString *mExportDir;
	
	ExportPluginProgress mProgress;
	NSLock *mProgressLock;
	int mStatus;
	
	// Interfaces
	IBOutlet NSButton *mSignButton;
	IBOutlet NSTextField *mSignText;
	IBOutlet NSProgressIndicator *mProgressIndicator;
	IBOutlet NSTextField *mUploadMsg;	
	IBOutlet NSTextView *mTagView;
	IBOutlet NSTableView *mTableView;
	IBOutlet NSImageView *mImageView;
	IBOutlet NSButton *mMinusButton;
	IBOutlet NSPopUpButton *mScalePopup;
	IBOutlet NSButton *mRembarCheckbox;
	IBOutlet NSMatrix *mPrivacyRadio;
	IBOutlet NSMatrix *mBatchRadio;
	IBOutlet NSTabView *mTab;
	IBOutlet NSTextView *mBatchTag;
	IBOutlet NSTextField *mTagsText;
	IBOutlet NSTextField *mScalePopupText;
	IBOutlet NSTextField *mPrivacyText;
	IBOutlet NSTextField *mBytesText;
	IBOutlet NSTextField *mTotalText;
	IBOutlet NSScrollView *mScroll;
	IBOutlet NSPopUpButton *mPrefScalePopup;
	IBOutlet NSMatrix *mPrefPrivacyRadio;
	IBOutlet NSButton *mPrefRembarCheckbox;
	IBOutlet NSTextView *mPrefTagView;
	IBOutlet NSButton *mCheckForUpdate;
	IBOutlet NSButton *mRemeberSettingsButton; 
	IBOutlet NSButton *mApplyBatchButton;
	 
	int progressIndicatorCount;
	int mUploadedItem;
	unsigned long mTotalBytes;
	unsigned int mAddedFileCount;
	
	ImageshackRequest *mRequest;
	
	// TODO: Release these objects after exporting
	//NSMutableArray *mImages;
	NSMutableArray *mMediaData;
	NSMutableArray *mFileArray;
	
	BOOL mPrefsWasInited;
	int mCurUploadedItem;
	unsigned mCurUploadedBytes;
	unsigned mCurUploadedBytesForFile;
	BOOL mFirstRun;
	int mExceededFiles;
	BOOL mIsShowAlertAboutExceed;
}

// overrides
- (void)awakeFromNib;
- (void)dealloc;

- (void)setValuesForPrefControls;
- (void)performUpload;
- (void)removeUploadedImages;
- (BOOL)checkIfFileListNeededUpdate;
- (void)reloadFileList;

// getters/setters
- (NSString *)exportDir;
- (void)setExportDir:(NSString *)dir;

//Actions
- (IBAction)clickMinus:(id)sender;
- (IBAction)clickSign:(id)sender;
- (IBAction)clickPrivacy:(id)sender;
- (IBAction)clickRembar:(id)sender;
- (IBAction)clickImageSize:(id)sender;
- (IBAction)clickCheckForUpdate:(id)sender;
- (IBAction)clickRememberSetting:(id)sender;
- (IBAction)clickApplyBatchSettings:(id)sender;

//TableView callbacks
- (int)numberOfRowsInTableView: (NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView 
    objectValueForTableColumn:(NSTableColumn *)column 
    row:(int)row;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

-(void)tryDisableExportButton:(NSTimer *)aTimer;
-(void)disableExportButton;
-(void)enableExportButton;

- (void)addItemsToPhotoArray:(NSArray*)filesList preview:(NSArray*)previewList;
- (BOOL)addItemToPhotoArray:(NSString*)filePath preview:(NSString*)previewPath;

@end
