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
        _downloadingOperation = [[NSOperationQueue alloc] init];
        _downloadingOperation.maxConcurrentOperationCount = 8;
        _session = [NSURLSession sessionWithConfiguration:self.configuration];
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *, NSError *))completion {
    //check params
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    DownloadItem *item = [DownloadItem new];
    item.downloadState = DownloadItemStatePending;
    item.downloaderDelegate = self;
    completion(item, nil);
    [_arrayDownloadTaskPending addObject:item];

    item.downloadTask = [_session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //task finish
        NSLog(@"Location: %@", location);
        NSLog(@"Path: %@", response.URL.filePathURL);
    }];
        
    [item.downloadTask resume];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self)weakSelf = self;
        [_arrayDownloadTaskPending removeObject:downloadItem];
        [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadState];
        if (_downloadingOperation.operationCount < _downloadingOperation.maxConcurrentOperationCount) {
            [_downloadingOperation addOperationWithBlock:^{
                [[weakSelf.priorityQueue getObjectFromQueue] resume];
                [weakSelf.priorityQueue removeObject];
            }];
        }
    }
}

@end
