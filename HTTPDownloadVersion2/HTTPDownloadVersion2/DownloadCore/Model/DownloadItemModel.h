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
 It will be call every Download Item update state
 */
- (void)downloadStateDidUpdate;

/**
 It will be call every Download Item update process
 */
- (void)downloadProgressDidUpdate;

@end


@interface DownloadItemModel : NSObject

/**
 A string content url to file download
 */
@property (nonatomic, strong) NSString *url;

/**
 Position and  to save file after downloaded
 */
@property (nonatomic, strong) NSString *filePath;

/**
 State of download
 */
@property (nonatomic) DownloadState state;

/**
 Priority queue contain task repair to download
 */
@property (nonatomic) DownloadPriority downloadPriority;

/**
 Total bytes downloaded and written
 */
@property (nonatomic) int64_t totalBytesWritten;

/**
 Total bytes of file download
 */
@property (nonatomic) int64_t totalBytesExpectedToWrite;

/**
 Delegate to do something with every state of download file
 */
@property (nonatomic, retain) id<DownloadItemDelegate> delegate;

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

/**
 Restart download
 */
- (void)restart;

/**
 Open file if file downloaded
 */
- (void)open;


@end
