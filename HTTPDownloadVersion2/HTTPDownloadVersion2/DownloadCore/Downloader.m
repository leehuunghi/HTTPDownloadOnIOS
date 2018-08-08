//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "Downloader.h"

@interface Downloader()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSMutableArray* arrayDownloadTaskPending; //Pending

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) NSOperationQueue *downloadingOperation;    //Downloadings

@property (nonatomic, strong) NSMutableArray *downloadedItems;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _arrayDownloadTaskPending = [[NSMutableArray alloc] init];
        _downloadedItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *, NSError *))completion {
    //check params
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    DownloadItem *item = [DownloadItem new];
    
    completion(item, nil);
    
    item.downloadTask = [_session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //task finish
    }];
    item.downloadState = DownloadItemStatePending;
    item.downloaderDelegate = self;
    
    [_arrayDownloadTaskPending addObject:item];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    [_arrayDownloadTaskPending removeObject:downloadItem];
}

@end
