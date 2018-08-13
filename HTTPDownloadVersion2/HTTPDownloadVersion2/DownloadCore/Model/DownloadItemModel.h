//
//  DownloadItemModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadPriority.h"

typedef NS_ENUM(NSUInteger, DownloadState) {
    DownloadStatePending = 0,
    DownloadStateDownloading,
    DownloadStatePause,
    DownloadStateComplete,
    DownloadStateError
};

@protocol DownloadItemDelegate <NSObject>

@optional

/**
 It will be call before item start download, or resume download (after pause)
 */
- (void)itemWillStartDownload;

/**
 It will be call after download finish

 @param success download item is success
 @param error error if have
 */
- (void)itemDidFinishDownload:(BOOL)success withError:(NSError *)error;


/**
 It will be call before download pause
 */
- (void)itemWillPauseDownload;

/**
 It will be call before download cancel
 */
- (void)itemWillCancelDownload;

/**
 It will be call every progress of download item is updated

 @param progress progress of download item
 */
- (void)itemDidUpdateProgress:(NSProgress *)progress;

/**
 
 */
- (void)itemDidUpdateTotalBytesWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

@end


@interface DownloadItemModel : NSObject

/**
 A string content url to file download
 */
@property (nonatomic, strong) NSString *url;

/**
 Process of downloading
 */
@property (nonatomic, strong) NSProgress *progress;

/**
 Position and  to save file after downloaded
 */
@property (nonatomic, strong) NSString *filePath;

/**
 Priority queue contain task repair to download
 */
@property (nonatomic) DownloadPriority downloadPriority;

/**
 Delegate to do something with every state of download file
 */
@property (nonatomic, retain) id<DownloadItemDelegate> delegate;

@property (nonatomic) DownloadState state;

@property (nonatomic, strong) NSData* resumeData;

/**
 Switch background download and foreground download
 */
- (void)suppend;

/**
 Resume download item
 */
- (void)resume;

/**
 Pause download item
 */
- (void)pause;

/**
 Cancel download. If downloaded will ask user to delete downloaded file
 */
- (void)cancel;

@end
