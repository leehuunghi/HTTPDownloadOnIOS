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
    DownloadErrorCodeUnknow
};

static NSString *const DownloadErrorDomain = @"com.download.contact";


@interface DownloadTableView : TableViewModel

@property (strong, nonatomic, readwrite) NSMutableArray *downloadArray;

@property (nonatomic, readwrite) NSError *error;

- (void)addCell:(CellObjectModel *)cellObject;

- (void)removeCell:(CellObjectModel *)cellObject;

@end
