//
//  DownloadTableViewObject.h
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "CellObjectModel.h"

typedef NS_ENUM(NSUInteger, DownloadState) {
    DownloadStatePending = 0,
    DownloadStateDownloading,
    DownloadStatePause,
    DownloadStateComplete,
    DownloadStateError
};

@class DownloadTableViewCell;

@interface DownloadCellObject : CellObjectModel

@property (readwrite, nonatomic, strong) NSString *title;

@property (readwrite, nonatomic, strong) NSString *progressString;

@property (readwrite, nonatomic) float progress;

@property (readwrite, nonatomic) BOOL isPersen;

@property (readwrite, nonatomic) DownloadState state;

@property (readwrite, nonatomic, weak) DownloadTableViewCell *cell;

@property (readwrite, nonatomic, strong) DownloadObjectModel *downloadManager;

@property (readwrite, nonatomic, strong) NSString *filePath;

- (instancetype)init;

- (void)pause;

- (void)resume;

- (void)cancel;

- (void)upPriority;

- (void)downPriority;

- (void)openFile;

- (UIColor *)getColorBackgroud;

- (void)progressDidUpdate:(NSUInteger)currentSize total:(NSUInteger)totalSize;

- (void)downloadFinish:(NSString *)filePath;

@end
