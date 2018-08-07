//
//  DowloaderModel.m
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloaderModel.h"

@implementation DownloaderModel

- (void)createDownloadItemWithUrl:(NSString *)urlString completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion {
    [self createDownloadItemWithUrl:urlString priority:DownloadPriorityMedium completion:completion];
}

- (void)createDownloadItemWithUrl:(NSString *)urlString priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion {
    [self createDownloadItemWithUrl:urlString filePath:nil priority:priority completion:completion];
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion {
    
}

- (void)cancelAll {
    
}

- (void)pauseAll {
    
}

@end
