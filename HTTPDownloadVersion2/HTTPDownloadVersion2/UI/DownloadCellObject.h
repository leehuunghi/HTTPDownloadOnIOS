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

@property (nonatomic) DownloadPriority priority;

@property (readwrite, nonatomic) DownloadState state;

@property (readwrite, nonatomic, weak) DownloadTableViewCell *cell;

@property (readwrite, nonatomic, strong) DownloadItemModel *downloadItem;

- (instancetype)init;

- (instancetype)initWithDownloadItem:(DownloadItemModel *)downloadItem;

- (void)pause;

- (void)resume;

- (void)cancel;

- (void)restart;

- (void)upPriority;

- (void)downPriority;

- (void)openFile;

- (UIColor *)getColorBackgroud;

@end
