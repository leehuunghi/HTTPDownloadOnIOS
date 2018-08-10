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

@property (nonatomic, strong) NSMutableArray *downloadedItems;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) dispatch_queue_t serialQueueSameItem;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadedItems = [[NSMutableArray alloc] init];
        _configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueue = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _serialQueueSameItem = dispatch_queue_create("serial_queue_same_item", DISPATCH_QUEUE_SERIAL);
        self.countDownloading = 2;
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *, NSError *))completion {
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueueSameItem, ^{
        BOOL isDownloaded = NO;
        for (DownloadItem* downloadItem in weakSelf.downloadedItems) {
            if ([downloadItem.url compare:urlString] == 0) {
                if (completion) {
                    completion(downloadItem, nil);
                    isDownloaded = YES;
                }
            }
        }
        
        if (!isDownloaded) {
            NSURL *url = [NSURL URLWithString:urlString];
            DownloadItem *item = [DownloadItem new];
            item.downloadState = DownloadItemStatePending;
            item.downloaderDelegate = self;
            item.downloadTask = [weakSelf.session downloadTaskWithURL:url];
            item.url = urlString;
            
            if (completion) {
                completion(item, nil);
            }
            
            [weakSelf.downloadedItems addObject:item];
            [self enqueueItem:item];
        }
    });
}

- (void)dequeueItem {
	    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueue, ^{
        if (weakSelf.countDownloading > 0 && [weakSelf.priorityQueue count] > 0) {
            weakSelf.countDownloading--;
            NSLog(@"%lu %ld",(unsigned long)weakSelf.countDownloading, (long)[weakSelf.priorityQueue count]);
            DownloadItem *item = (DownloadItem *)[weakSelf.priorityQueue getObjectFromQueue];
            [item reallyResume];
            [weakSelf.priorityQueue removeObject];
        }
    });
}

- (void)enqueueItem:(DownloadItem *)downloadItem {
    if (downloadItem) {
        [self.priorityQueue addHeadObject:downloadItem withPriority:downloadItem.downloadPriority];
        [self dequeueItem];
    }
}

#pragma DownloaderDelegate

- (void)itemWillCancelDownload:(DownloadItem *)downloadItem {
}

- (void)itemWillPauseDownload:(DownloadItem *)downloadItem {
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueue, ^{
        weakSelf.countDownloading++;
    });
    [self dequeueItem];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self)weakSelf = self;
        [weakSelf.priorityQueue addObject:downloadItem];
        [self dequeueItem];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
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
    NSLog(@"complete");
    for (DownloadItem *item in self.downloadedItems) {
        if (item.downloadTask == task) {
            NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
            if (error) {
                if (error.code == -1001) {
                    item.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    item.downloadTask = [_session downloadTaskWithResumeData:item.resumeData];
                    return;
                } else {
                    item.downloadState = DownloadItemStateError;
                    [item.delegate itemDidFinishDownload:NO withError:error];
                }
            } else {
                if (httpRespone.statusCode/100==2) {
                    item.downloadState = DownloadItemStateComplete;
                    [item.delegate itemDidFinishDownload:YES withError:error];
                } else {
                    item.downloadState = DownloadItemStateError;
                    [item.delegate itemDidFinishDownload:NO withError:error];
                }
            }
        }
    }
    dispatch_async(self.serialQueue, ^{
        self.countDownloading++;
    });
    [self dequeueItem];
}

- (void)setCountDownloading:(NSUInteger)countDownloading {
    _countDownloading = countDownloading;
    NSLog(@"Count Downloading: %ld", _countDownloading);
}

@end
