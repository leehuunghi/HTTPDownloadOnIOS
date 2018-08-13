//
//  DownloadTableViewObject.h
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "CellObjectModel.h"
#import "DownloadItemModel.h"

@class DownloadTableViewCell;

@interface DownloadCellObject : CellObjectModel <DownloadItemDelegate>

@property (readwrite, nonatomic, strong) NSString *title;

@property (readwrite, nonatomic, strong) NSString *progressString;

@property (readwrite, nonatomic) float progress;

@property (readwrite, nonatomic) BOOL isPersen;

@property (readwrite, nonatomic) DownloadState state;

@property (readwrite, nonatomic, weak) DownloadTableViewCell *cell;

@property (readwrite, nonatomic, strong) DownloadItemModel *downloadItem;

@property (readwrite, nonatomic, strong) NSString *filePath;

- (instancetype)init;

- (instancetype)initWithDownloadItem:(DownloadItemModel *)downloadItem;

- (void)pause;

- (void)resume;

- (void)cancel;

- (void)upPriority;

- (void)downPriority;

- (void)openFile;

- (UIColor *)getColorBackgroud;

- (void)progressDidUpdate:(NSUInteger)currentSize total:(NSUInteger)totalSize;

@end
