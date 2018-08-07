//
//  DowloaderModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItemModel.h"
#import "PriorityQueue.h"

@interface DownloaderModel : NSObject

- (void)createDownloadItemWithUrl:(NSString *)url completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

- (void)createDownloadItemWithUrl:(NSString *)url priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

- (void)createDownloadItemWithUrl:(NSString *)url filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

- (void)cancelAll;

- (void)pauseAll;



@end
