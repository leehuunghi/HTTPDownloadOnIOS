//
//  DownloadTableView.h
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "TableViewModel.h"

@class CellObjectModel;

typedef NS_ENUM(NSUInteger, DownloadErrorCode) {
    DownloadErrorCodeNone = 0,
    DownloadErrorCodeEmpty = 100,
    DownloadErrorCodeFilterEmpty = 101,
    DownloadErrorCodeUnknow
};

static NSString *const DownloadErrorDomain = @"com.download.contact";


@interface DownloadTableView : TableViewModel

@property (nonatomic, readwrite) NSError *error;

- (void)configDefault;

- (void)addCell:(CellObjectModel *)cellObject;

- (void)removeCell:(CellObjectModel *)cellObject;

- (void)moveCellToHead:(CellObjectModel *)cellObject;

- (void)filterWithCondition:(BOOL (^)(CellObjectModel *cellObject))condition;

@end
