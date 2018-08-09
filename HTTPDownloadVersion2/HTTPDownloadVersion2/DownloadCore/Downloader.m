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

@property (nonatomic) NSUInteger countDownloading;

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) NSOperationQueue *downloadingOperation;

@property (nonatomic, strong) NSMutableArray *downloadedItems;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadedItems = [[NSMutableArray alloc] init];
        _downloadingOperation = [[NSOperationQueue alloc] init];
        _downloadingOperation.maxConcurrentOperationCount = 1;
        _configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueue = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _countDownloading = 5;
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
    [_downloadedItems addObject:item];
    item.downloadTask = [_session downloadTaskWithURL:url];
//    item.downloadTask = [_session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        //task finish
//        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)response;
//        if(httpRespone.statusCode == 200) {
//            [item.delegate itemDidFinishDownload:YES withError:nil];
//        } else {
//            [item.delegate itemDidFinishDownload:NO withError:error];
//        }
//    }];
    
    NSLog(@"%@", item.downloadTask);
    
    [item resume];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadState];
            if (self.countDownloading > 0) {
                [_downloadingOperation addOperationWithBlock:^{
                    DownloadItem *item = (DownloadItem *)[weakSelf.priorityQueue getObjectFromQueue];
                    NSLog(@"%@", item.downloadTask);
                    [item.downloadTask resume];
                    [weakSelf.priorityQueue removeObject];
                }];
            }
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"Run here!");
}



- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"Update!!!!!!!!");
    for (DownloadItem *item in self.downloadedItems) {
        if (item.downloadTask == downloadTask) {
            [item.delegate itemDidUpdateTotalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    for (DownloadItem *item in self.downloadedItems) {
        if (item.downloadTask == downloadTask) {
            //store file to document
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    for (DownloadItem *item in self.downloadedItems) {
        if (item.downloadTask == task) {
            NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
            if(httpRespone.statusCode == 200) {
                [item.delegate itemDidFinishDownload:YES withError:nil];
            } else {
                [item.delegate itemDidFinishDownload:NO withError:error];
            }
        }
    }
}

@end
