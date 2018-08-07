//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "Downloader.h"
#import "PriorityQueue.h"

@interface Downloader()

@property (nonatomic, strong) PriorityQueue *priorityQueue;
@property (nonatomic, strong) NSURLSessionConfiguration *configuration;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation Downloader

- (void)downloadTaskWithUrl:(NSString *)url success:(void (^)(DownloadItem* downloadItem))completionSuccess failure:(void (^)(NSError *))completionFailure{
    
}

- (DownloadItem *)createDownloadItemWithUrl:(NSString *)url andFileName:(NSString *)fileName {
    DownloadItem *downloadItem = [[DownloadItem alloc] initWithUrlAndFileName:url fileName:fileName session:self.session];
    return downloadItem;
}

@end
