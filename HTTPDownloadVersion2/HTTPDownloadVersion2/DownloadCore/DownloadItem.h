//
//  DownloadItem.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItemDelegate.h"

@class DownloadItem;


@interface DownloadItem : NSObject

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

@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic) NSMutableArray<id<DownloadItemDelegate>> *downloadItemDelegates;

- (void)updateProgressWithTotalBytesWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)resume;

- (void)pause;

- (void)cancel;

- (NSData *)transToData;

- (instancetype)initWithData:(NSData *)data;

- (void)addDelegate:(id<DownloadItemDelegate>)delegate;

@end


