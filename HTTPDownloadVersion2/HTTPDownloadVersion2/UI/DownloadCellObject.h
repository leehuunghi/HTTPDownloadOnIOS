//
//  DownloadTableViewObject.h
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "CellObjectModel.h"
#import "DownloadItemDelegate.h"
#import "DownloaderSingleton.h"


@class DownloadTableViewCell;

@interface DownloadCellObject : CellObjectModel <DownloadItemDelegate>

@property (readwrite, nonatomic) NSString *identifier;

@property (readwrite, nonatomic, strong) NSString *title;

@property (readwrite, nonatomic, strong) NSString *progressString;

@property (readwrite, nonatomic) float progress;

@property (readwrite, nonatomic) DownloadPriority priority;

@property (readwrite, nonatomic) DownloadState state;

@property (readwrite, nonatomic, weak) DownloadTableViewCell *cell;

- (instancetype)init;

- (void)pause;

- (void)resume;

- (void)cancel;

- (void)restart;

- (void)upPriority;

- (void)downPriority;

- (void)openFile;

- (UIColor *)getColorBackgroud;

@end
