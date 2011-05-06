#import <QuickTime/QuickTime.h>

#import "ISExportController.h"
#import "Utilities.h"
#import "ISRegistrationController.h"
#import "ISQuickRegisterController.h"
#import "ISAlert.h"
#import "ISManager.h"
#import "ISMediaDataFactory.h"

@interface ISExportController (PDE)

- (void)updatePhotoTabWithDefaultValues;
- (BOOL)checkIfItemDublicate: (NSString*)aPath;
- (unsigned)calculateTotalBytes;
- (id)selectedImage;
- (void)showAlertFilesNotAddedViaSize:(int)sizeExceeded viaType:(int)typeUnsupported;
- (void)showRegistrationWindow;

@end

@implementation ISExportController (PDE)

- (void)updatePhotoTabWithDefaultValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	int value = [defaults integerForKey:DefaultScalePreferenceKey];
	[mScalePopup selectItemAtIndex:value];

	value = [defaults integerForKey:DefaultRembarPreferenceKey];
	[mRembarCheckbox setIntValue:value];

	value = [defaults integerForKey:DefaultPrivacyPreferenceKey];
	[mPrivacyRadio setState:NSOnState atRow:value column:0];
}

- (unsigned)calculateTotalBytes
{
	mTotalBytes = 0;
	unsigned oneFile;
	int i, count = [mMediaData count];
	for (i=0; i<count; i++) 
	{
		oneFile = [[mMediaData objectAtIndex:i] bytesCount];
		mTotalBytes += oneFile;
	}
	
	return mTotalBytes;
}

- (unsigned)totalBytes
{
	if (mTotalBytes == 0)
	{
		[self calculateTotalBytes];
	}
	
	return mTotalBytes;
}

- (BOOL)checkIfItemDublicate: (NSString*)aPath
{
	BOOL reply = NO;
	NSComparisonResult comp = NSOrderedAscending;
	int i, count = [mMediaData count];
	for (i=0; i<count; i++) 
	{
		comp = [aPath compare:[[mMediaData objectAtIndex:i] name]];
		if  (comp == NSOrderedSame)
		{
			//This file was added to the list yet. Duplicated.
			reply = YES;
		}
	}
	return reply;
}

- (id)selectedImage
{
    int row = [mTableView selectedRow];
	return row >= 0 ? [mMediaData objectAtIndex:row] : nil;
}

-(void)showAlertFilesNotAddedViaSize:(int)sizeExceeded viaType:(int)typeUnsupported
{
	NSAlert *alertSheet = [[NSAlert alloc] init];
	[alertSheet addButtonWithTitle:@"OK"];
 	
	[alertSheet setAlertStyle:NSInformationalAlertStyle];
	[alertSheet setMessageText:@"Some files were not added."];
	NSString* message1;
	NSString* message2;
	
	if (sizeExceeded > 1)
		message1 = [NSString stringWithFormat:@"%d files were not added because their size exceed 1.5Mb.", sizeExceeded];
	else if (sizeExceeded == 1)
		message1 = [NSString stringWithFormat:@"1 file was not added because its size exceed 1.5Mb."];
	else
		message1 = @" ";

	if (typeUnsupported > 1)
		message2 = [NSString stringWithFormat:@"%d files were not added because they have unsupported type.", typeUnsupported];
	else if (typeUnsupported == 1)
		message2 = [NSString stringWithFormat:@"1 file was not added because it has unsupported type."];
	else
		message2 = @" ";
	
	[alertSheet setInformativeText: [NSString stringWithFormat: @"%@\n%@", message1, message2]];
	[alertSheet beginSheetModalForWindow: [mExportMgr window] 
                           modalDelegate: self 
                          didEndSelector: nil
                             contextInfo: nil];
}

- (void)showAlertAboutConnectionFailed
{
	NSAlert *alertSheet = [[NSAlert alloc] init];
    [alertSheet addButtonWithTitle:@"OK"];
	[alertSheet setAlertStyle:NSInformationalAlertStyle];
	[alertSheet setMessageText:@"Connection error."];
    [alertSheet setInformativeText:@"The files were not uploaded."];
	[alertSheet beginSheetModalForWindow: [mExportMgr window] 
                           modalDelegate: self 
                          didEndSelector: nil
                             contextInfo: nil];
	[self removeUploadedImages];
}

- (void)showAlertAboutSucceedUpload
{
	ISAlert *alert = [[ISAlert alloc] init];
	[alert runModal];
}

- (void)showRegistrationWindow
{
	ISRegistrationController *reg = [[ISRegistrationController alloc] init];
	[NSApp beginSheet: [reg window]
       modalForWindow: [mExportMgr window]
        modalDelegate: self
       didEndSelector: @selector(loginDidEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

@end

@implementation ISExportController

- (void)awakeFromNib
{
	NSNotificationCenter *center;
	center = [NSNotificationCenter defaultCenter];
	[center addObserver: self 
               selector: @selector(usernameDidChange:)
                   name: UsernameChangedNotification
                 object: nil];
				
	[center addObserver: self 
               selector: @selector(showQuickRegistration:)
                   name: QuickRegisterNotification
                 object: nil];

	[center addObserver: self 
               selector: @selector(disableExportButton)
                   name: DisableButtonsNotification
                 object: nil];

	[center addObserver: self 
               selector: @selector(enableExportButton)
                   name: EnableButtonsNotification
                 object: nil];
	//Prefs
	[[ISManager manager] initDefaultValues];

	mFileArray = [[[NSMutableArray alloc] init] retain];
	mMediaData = [[NSMutableArray alloc] init];

	[self reloadFileList];
	
	mRequest = [[ImageshackRequest requestWithDelegate:self] retain];
	
	[self updatePhotoTabWithDefaultValues];

	NSImageCell  *imageCell = [[[NSImageCell alloc] init] autorelease];
	[imageCell setImageScaling:NSScaleProportionally];
	NSTableColumn *imageColumn = [mTableView tableColumnWithIdentifier:@"first"];
	[imageColumn setDataCell:imageCell];

	NSPoint defaultPosition = NSMakePoint(0, 0);
	[mScroll scrollPoint:defaultPosition];
}

- (id)initWithExportImageObj:(id <ExportImageProtocol>)obj
{
	if((self = [super init]) == nil)
		return nil; // fail!

	mStatus = kOtherErrors;
	mExportMgr = obj;
	mProgress.message = Nil;
	mProgressLock = [[NSLock alloc] init];
	mFirstRun = YES;
	mIsShowAlertAboutExceed = NO;
	return self;
}

- (void)dealloc
{
	[mExportDir release];
	[mMediaData release];
	[mRequest release];
	
	[mProgressLock release];
	mProgressLock=nil;
	[mProgress.message release];

	[super dealloc];
}

// getters/setters
- (NSString *)exportDir
{
	return mExportDir;
}

- (void)setExportDir:(NSString *)dir
{
	[mExportDir release];
	mExportDir = [dir retain];
}

// protocol implementation
- (NSView <ExportPluginBoxProtocol> *)settingsView
{
	return mSettingsBox;
}

- (NSView *)firstView
{
	return mFirstView;
}

- (void)viewWillBeActivated
{
	if(mPrefsWasInited)
		[self setValuesForPrefControls]; //re-read default settings (to cancel what user haveselected in the previous session and didn't save)		

	if ([self checkIfFileListNeededUpdate] == YES)
	{
		[self reloadFileList];
	}

	if (mIsShowAlertAboutExceed)
	{
		[[ISManager manager] showAlertItemsExceedSize:mExceededFiles];
		mIsShowAlertAboutExceed = NO;
	}
	
	if(mFirstRun==YES)
		[[ISManager manager] checkForUpdates];		
	
	if([[ISManager manager] isExportAllowed]==NO)
	{
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 0.3 // scheduled since we also want "normal" run loop mode.
                                                          target: self 
                                                        selector: @selector(tryDisableExportButton:)
                                                        userInfo: nil
                                                         repeats: NO];
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
		
	}
	mFirstRun = NO;
}

- (void)tryDisableExportButton:(NSTimer *)aTimer
{
	[self disableExportButton];
}

- (void)viewWillBeDeactivated
{
}

-(void)disableExportButton
{
	[mExportMgr disableControls];
}

-(void)enableExportButton
{
	[mExportMgr enableControls];
}

- (BOOL)validateUserCreatedPath:(NSString*)path
{
	return YES;
}

- (NSString *)requiredFileType
{
	if([mExportMgr imageCount] > 1)
		return @"";
	else
		return @"jpg";
}

- (BOOL)wantsDestinationPrompt
{
	return NO;
}

- (NSString*)getDestinationPath
{
	return NSHomeDirectory();
}

- (NSString *)defaultFileName
{
	return nil;
}

- (NSString *)defaultDirectory
{
	return NSHomeDirectory();
}

- (BOOL)treatSingleSelectionDifferently
{
	return NO;
}

- (BOOL)handlesMovieFiles
{
	return YES;
}

- (void)clickExport
{
	[mExportMgr clickExport];
}

- (void)startExport:(NSString *)path
{
	if ([mMediaData count] <= 0)
	{
		[[ISManager manager] showAlertNoItems];
		return;
	}
	
	if ([[ISManager manager] checkIfUserID] == NO)
	{
		mStatus = kTryToUpload; 
		[self showRegistrationWindow];
		return;
	}

	[mExportMgr startExport];
}

- (void)performUpload
{
	[self calculateTotalBytes];
	[self lockProgress];
	mProgress.indeterminateProgress = NO;
	mProgress.totalItems = (unsigned long)[self totalBytes]/1024;
	[mProgress.message autorelease];
	mProgress.message = @"Uploading";
	[self unlockProgress];

	id selection = [self selectedImage];
	if (selection != NULL)
    {
        if ([mTagView string] != nil)
            [selection setTagValue: [mTagView string]];
    }
	int count = [mMediaData count];
	mUploadedItem = 0;
	mCurUploadedBytes = 0;
	mCurUploadedBytesForFile = 0;
	mStatus = kUploading;

	ISMediaData *theMedia;	// Media file for upploding
	for (mCurUploadedItem=0; mCurUploadedItem < count; mCurUploadedItem++) 
	{
		if (mStatus == kUploading)
		{
			theMedia = [mMediaData objectAtIndex:mCurUploadedItem];
			ISUploadRequest *request = [ISUploadRequest uploadRequest];
			[request setBatchTags:[mBatchTag string]];
			[request uploadMediaData:theMedia observer:self];
			mCurUploadedBytes += mCurUploadedBytesForFile;
			mUploadedItem++;
		}
	}
	return; 
}

- (void)performExport:(NSString *)path
{
	[self performUpload];
}

-(void)unlockProgress
{
	if(mProgressLock)
		[mProgressLock unlock];
}

-(void)lockProgress
{
	if(mProgressLock)
		[mProgressLock lock];
}

- (ExportPluginProgress *)progress
{
	return &mProgress;
}

- (void)cancelExport
{
	if (mStatus == kNoConnection)
	{
		[self showAlertAboutConnectionFailed];
	}

	@synchronized (self)
	{
		mStatus = kCancelExport;
	}
	
//	if(mRequest)
//		[mRequest cancelUpload];
}

- (NSString *)name
{
	return @"ImageShack Uploader";
}

-(void)removeUploadedImages
{
}

- (BOOL)checkIfFileListNeededUpdate
{
	int count = [mExportMgr imageCount];
	if (count != [mFileArray count])
		return YES;
	
	int i;
	for (i=0; i< count; i++)
	{
		NSString *fileName1 = [mExportMgr imagePathAtIndex:i];
		NSString *fileName2 = [mFileArray objectAtIndex:i];
		if ([fileName1 compare:fileName2] != NSOrderedSame)
			return YES;
	}
	return NO;
}

- (void)reloadFileList
{
	NSMutableArray *thePreviewArray = [NSMutableArray array];
	[mFileArray removeAllObjects];
	[mMediaData removeAllObjects];

	int i;
	int count = [mExportMgr imageCount];
	for (i=0; i< count; i++)
	{
		[mFileArray addObject:[mExportMgr sourcePathAtIndex:i]];
		[thePreviewArray addObject:[mExportMgr thumbnailPathAtIndex:i]];
	}

	[self addItemsToPhotoArray:mFileArray preview:thePreviewArray];
	[mImageView setImage:[[mMediaData lastObject] previewMedia]];
}

- (void)addItemsToPhotoArray:(NSArray*)filesList preview:(NSArray*)previewList
{
	int i;
	mExceededFiles = 0;
	int typeUnsupported = 0;
	NSString *filePath;
	NSString *previewPath;
	
	for (i = 0; i < [filesList count]; i++)
	{
		filePath = [filesList objectAtIndex:i];
		previewPath = [previewList objectAtIndex:i];
		
		if (filePath != NULL)
		{
		
#if 0
//AD: No more size limit check (bug #4610)		
			//Check for size limit
			if ([Utilities isExceededSizeLimit:filePath] == YES)
			{
				mExceededFiles++;
				continue;
			}
#endif			
			if ([self addItemToPhotoArray:filePath preview:previewPath] == NO)
			{
				// if Image was not created
				typeUnsupported++;
				NSLog(@"File %@ was not added because has unsupported type.", filePath);
			}
		}
	}
	
	if (mExceededFiles > 0)
	{
		mIsShowAlertAboutExceed = YES;
	}
	
	[mTableView noteNumberOfRowsChanged];
	[mTableView selectRowIndexes: [NSIndexSet indexSetWithIndex:[mMediaData count]-1] 
			byExtendingSelection: NO];
	//[mTableView editColumn:0 row:[mImages count]-1 withEvent:nil select:NO];
	[mTableView editColumn:0 row:[mMediaData count]-1 withEvent:nil select:NO];
	[mTableView reloadData]; //update selection
}

-(BOOL)addItemToPhotoArray:(NSString*)filePath preview:(NSString*)previewPath
{
	BOOL successed = NO;
    
	// Create media file data used ISMediaDataFactory
	ISMediaDataFactory *theFactory = [ISMediaDataFactory factory];
	ISMediaData *theMedia = [theFactory createMediaData:filePath];
	
	// Validate media object and add it to mMediaData array
	if (theMedia != NULL)
	{
		[mMediaData addObject:theMedia];
		[[mMediaData lastObject] setPreviewPath:previewPath];
		successed = YES;
	}
	return successed;
}

#pragma mark Preferences
- (void)setValuesForPrefControls 
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	int value = [defaults integerForKey:DefaultScalePreferenceKey];
	[mPrefScalePopup selectItemAtIndex:value];
	
	value = [defaults integerForKey:DefaultRembarPreferenceKey];
	[mPrefRembarCheckbox setIntValue:value];
	
	value = [defaults integerForKey:DefaultPrivacyPreferenceKey];
	[mBatchRadio setState:NSOnState atRow:value column:0];

	mPrefsWasInited = YES; //to avoid repeat inginitialization of prefs controls states while navigating between tabs
}

- (void)saveDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[mPrefScalePopup indexOfSelectedItem] forKey:DefaultScalePreferenceKey];
	[defaults setInteger:[mPrefRembarCheckbox intValue] forKey:DefaultRembarPreferenceKey];
	[defaults setInteger:[mBatchRadio selectedRow] forKey:DefaultPrivacyPreferenceKey];
}

#pragma mark Actions
- (IBAction)clickMinus:(id)sender
{	
	int row = [mTableView selectedRow];
    
    if (row >= 0) 
	{
		[mMediaData removeObjectAtIndex:row];
        [mTableView reloadData];

		int selectedRow = ((row >= [mMediaData count]) ? row-1 : row);
		if (selectedRow > -1)
		{
			[mTableView selectRow: selectedRow byExtendingSelection:NO];
			[mImageView setImage:[[mMediaData objectAtIndex:selectedRow] previewMedia]];
		}
	}
	
	if ([mMediaData count] <= 0)
	{
		[self disableExportButton];
	}
}

- (IBAction)clickSign:(id)sender
{
	if ([[ISManager manager] isSignedIn] == NO)
	{
		mStatus = kOtherErrors;
		[self showRegistrationWindow];
	}
	else
		[[ISManager manager] signOut];
}

- (IBAction)clickImageSize:(id)sender
{
	id selection = [self selectedImage];
	if (selection != NULL)
	{
		[selection setScale:[mScalePopup indexOfSelectedItem]];
	}
}

- (IBAction)clickRembar:(id)sender
{
	id selection = [self selectedImage];
	if (selection != NULL)
	{
		[selection setRembar:[mRembarCheckbox intValue]];
	}
}

- (IBAction)clickPrivacy:(id)sender
{
	id selection = [self selectedImage];
	if (selection != NULL)
	{
		[selection setPrivacy:[mPrivacyRadio selectedRow]];
	}	
}

#pragma mark Batch tab controls
- (IBAction)clickRememberSetting:(id)sender
{
	[self saveDefaults];
}

- (IBAction)clickApplyBatchSettings:(id)sender
{
	// Set batch privacy for all items
	int i, count = [mMediaData count];
	for (i=0; i<count; i++) 
	{
		[[mMediaData objectAtIndex:i] setRembar:[mPrefRembarCheckbox intValue]];
		[[mMediaData objectAtIndex:i] setScale:[mPrefScalePopup indexOfSelectedItem]];
		[[mMediaData objectAtIndex:i] setPrivacy:[mBatchRadio selectedRow]];
	}
}

- (IBAction)clickCheckForUpdate:(id)sender
{
	[[ISManager manager] checkForUpdates];
}

#pragma mark Notifications
//--------------------------------------------------------
// Notification recieved
//--------------------------------------------------------
- (void)usernameDidChange:(NSNotification *)note 
{
	[mSignText setStringValue:[[ISManager manager] getSignedString]];
	if ([[ISManager manager]isSignedIn] == YES)
	{
		[mSignButton setTitle:@"Sign Out"];
	}
	else
	{
		[mSignButton setTitle:@"Sign In"];
	}
}

- (void)showQuickRegistration:(NSNotification *)note
{
	ISQuickRegisterController *reg = [[ISQuickRegisterController alloc] init];	
	[NSApp beginSheet: [reg window]
        modalForWindow: [mExportMgr window]
        modalDelegate: self
       didEndSelector: @selector(quickRegisterDidEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

#pragma mark TableView callbacks
// ----------------------- NSTableView delegate methods-----------------------
//TableView callbacks
- (int)numberOfRowsInTableView: (NSTableView *)tableView;
{
	return [mMediaData count];
}

- (float)tableView:(NSTableView *)aTable heightOfRow:(int)aRow
{
	return 86;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{	
	return [[mMediaData objectAtIndex:row] previewImage];
}

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:
				(NSCell *)cell rect:(NSRectPointer)rect 
				tableColumn:(NSTableColumn *)tc 
				row:(int)row 
				mouseLocation:(NSPoint)mouseLocation
{
	return [[mMediaData objectAtIndex:row] name];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
 //   NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    id selection = [self selectedImage];
    
    if (selection != NULL)
	{
		[mMinusButton setEnabled:YES];

		NSString* theTag = [[self selectedImage] tagValue];
		if (theTag)
			[mTagView setString:theTag];
		else
			[mTagView setString:@""];
		
		[mScalePopup selectItemAtIndex:[selection scaleValue]];		
		[mRembarCheckbox setIntValue:[selection rembarValue]];
		[mPrivacyRadio setState:NSOnState atRow:[selection privacy] column:0];
		[mImageView setImage:[selection previewMedia]];
		[mScalePopup setEnabled:[[self selectedImage] canScale]];
		[mRembarCheckbox setEnabled:[[self selectedImage] canScale]];
		
		//Switch tabView to Photo tab if non-Photo
		if ([mTab indexOfTabViewItem:[mTab selectedTabViewItem]] > 0)
			[mTab selectTabViewItemAtIndex:0];
    }
	else 
	{
        [mMinusButton setEnabled:NO];
		[mImageView setImage:nil];
    }
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	id selection = [self selectedImage];
    
    if (selection != NULL)
	{
		NSString* str = [[NSString alloc] initWithString:[mTagView string]];
		[selection setTagValue: str];
	}
	return YES;
}

#pragma mark Tab View callbacks
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	int curTab = [mTab indexOfTabViewItem:tabViewItem];
	
	if (curTab == 0)
	{
		//Photo tab
		id selection = [self selectedImage];
    
		if (selection == NULL)
		{
			//Photo tab
			[mTableView reloadData];
			if ([mMediaData count] > 0)
				[mTableView selectRow: 0 byExtendingSelection:NO];
		}
	}
	else if (curTab == 1)
	{
		//Batch tab
		[mTableView deselectAll:self];
		if(mPrefsWasInited==NO)
			[self setValuesForPrefControls];
	}
	else
	{
		//Prefs tab
		[mTableView deselectAll:self];
		[self setValuesForPrefControls];
	}
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	return YES;
}

-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];

	if (([[ISManager manager] isSignedIn] == YES) && (mStatus == kTryToUpload))
	{
		[self startExport:@""];
	}
}

-(void)quickRegisterDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
}

#pragma mark Timer
-(void)uploadCanceled:(ISUploadRequest *)request
{
}

-(void)uploadCompleteWaitingForServerToResponse:(ISUploadRequest *)request
{
	[self lockProgress]; 
	[mProgress.message autorelease];

	//mProgress.message = [[NSString stringWithFormat:
	//					  @"Image %d of %d uploaded. Processing on the server...", 
	//					  mCurUploadedItem + 1, [mImages count]] retain];

	mProgress.message = [[NSString stringWithFormat:
						  @"Image %d of %d uploaded. Processing on the server...", 
						  mCurUploadedItem + 1, [mMediaData count]] retain];
	[self unlockProgress];
}


-(void)uploadComplete:(ISUploadRequest *)request
{
	if (mStatus == kCancelExport)
	{
		[request cancelUpload];
		return;
	}
	
	if ((mStatus != kCancelExport) &&
		((mCurUploadedBytes + mCurUploadedBytesForFile) >= [self totalBytes]))
	{
		mStatus = kUploadSucceeded;
		[self showAlertAboutSucceedUpload];
		[self lockProgress]; 
		[mProgress.message autorelease]; 
		mProgress.message = [[NSString stringWithFormat:@"Upload complete"] retain];
		mProgress.shouldStop = YES; 
		[self unlockProgress];
	}
}

-(void)uploadMadeProgress:(ISUploadRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes
{
	if (mStatus == kCancelExport)
	{
		[request cancelUpload];
		return;
	}

//	NSLog(@"All files bytes: %d", [self totalBytes]);
//	NSLog(@"Bytes written: %d Total: %ld", numberOfBytes, totalBytes);
//	NSLog(@"Current uploaded bytes: %d", mCurUploadedBytes);
	
	mCurUploadedBytesForFile = totalBytes;
	unsigned theAllFilesKBytes = [self totalBytes]/1024;
	unsigned theCurUploadedKBytes = (mCurUploadedBytes+numberOfBytes)/1024;
	
	if (theCurUploadedKBytes > theAllFilesKBytes)
		theCurUploadedKBytes = theAllFilesKBytes;
		
	[self lockProgress];
	mProgress.currentItem = (unsigned long)theCurUploadedKBytes;
	[mProgress.message autorelease];
	/*
	mProgress.message = [[NSString stringWithFormat:
				@"Image %d of %d. Uploaded %d Kb of %d Kb.", 
				mCurUploadedItem + 1, [mImages count],
				theCurUploadedKBytes, theAllFilesKBytes] retain];
	 */
	mProgress.message = [[NSString stringWithFormat:
						  @"Image %d of %d. Uploaded %d Kb of %d Kb.", 
						  mCurUploadedItem + 1, [mMediaData count],
						  theCurUploadedKBytes, theAllFilesKBytes] retain];
	[self unlockProgress];
}

-(void)uploadFailed:(ISUploadRequest *)request withError:(NSString *)reason
{
	NSLog(@"Error: %@", reason);
	
	mStatus = kNoConnection;
	[request cancelUpload];

	[self lockProgress]; 
	[mProgress.message autorelease]; 
	mProgress.message = [[NSString stringWithFormat:@"Connection error"] retain]; 
	mProgress.shouldCancel = YES; 
	[self unlockProgress]; 
}

-(void)uploadTimedOut:(ISUploadRequest *)request
{
	NSLog(@"Upload timeout");
	
	mStatus = kNoConnection;
	
	[self lockProgress]; 
	[mProgress.message autorelease]; 
	mProgress.message = [[NSString stringWithFormat:@"Connection timeout"] retain]; 
	mProgress.shouldCancel = YES; 
	[self unlockProgress]; 
}

@end
