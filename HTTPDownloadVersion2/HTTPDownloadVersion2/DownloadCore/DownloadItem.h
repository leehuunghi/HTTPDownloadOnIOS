//
//  DownloadItem.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItemModel.h"
#import "Model/DownloadItemDelegate.h"

@class DownloadItem;

@protocol DownloaderDelegate <NSObject>

@optional

- (void)itemWillStartDownload:(DownloadItem *)downloadItem;

- (void)itemWillFinishDownload:(DownloadItem *)downloadItem;

- (void)itemWillPauseDownload:(DownloadItem *)downloadItem;

- (void)itemWillCancelDownload:(DownloadItem *)downloadItem;

@end

typedef NS_ENUM(NSUInteger, DownloadItemState) {
    DownloadItemStatePending = 0,
    DownloadItemStateDownloading,
    DownloadItemStatePause,
    DownloadItemStateComplete,
    DownloadItemStateError
};

@interface DownloadItem : DownloadItemModel

@property (nonatomic) DownloadItemState downloadState;

@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic) NSMutableArray<id<DownloadItemDelegate>> *downloadItemDelegates;

@property (nonatomic, retain) id<DownloaderDelegate> downloaderDelegate;

- (void)updateProgressWithTotalBytesWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)resume;

- (void)pause;

- (void)cancel;

- (NSData *)transToData;

- (instancetype)initWithData:(NSData *)data;

@end


