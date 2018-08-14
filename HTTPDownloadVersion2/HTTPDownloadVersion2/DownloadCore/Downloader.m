//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#define kSaveKey @"download_array_data"

#import "Downloader.h"

@interface Downloader()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic) NSUInteger countDownloading;

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) NSMutableArray *downloadedItems;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) dispatch_queue_t serialQueueSameItem;

@property (nonatomic, strong) NSMutableArray *downloadingItems;

@property (nonatomic) unsigned int *limitDownloadTask;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadedItems = [[NSMutableArray alloc] init];
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"My session"];
        [_configuration setDiscretionary:YES];
        [_configuration setSessionSendsLaunchEvents:YES];
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueue = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _serialQueueSameItem = dispatch_queue_create("serial_queue_same_item", DISPATCH_QUEUE_SERIAL);
        _limitDownloadTask = 2;
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
            item.downloadPriority = priority;
            
            NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:urlString];
            if (resumeData) {
                if ([resumeData isKindOfClass:[NSData class]]) {
                    [NSUserDefaults.standardUserDefaults removeObjectForKey:urlString];
                    item.downloadTask = [weakSelf.session downloadTaskWithResumeData:(NSData*)resumeData];
                }
            }
            if (!item.downloadTask) {
                item.downloadTask = [weakSelf.session downloadTaskWithURL:url];
            }
            
            item.url = urlString;
            if (completion) {
                completion(item, nil);
            }
            
            [weakSelf.downloadedItems addObject:item];
            [self enqueueItem:item];
        }
    });
}

- (unsigned int)limitDownloadTask {
    return _limitDownloadTask;
}

- (void)dequeueItem {
	    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueue, ^{
        if (weakSelf.countDownloading < weakSelf.limitDownloadTask && [weakSelf.priorityQueue count] > 0) {
            weakSelf.countDownloading++;
            NSLog(@"%lu %ld",(unsigned long)weakSelf.countDownloading, (long)[weakSelf.priorityQueue count]);
            DownloadItem *item = (DownloadItem *)[weakSelf.priorityQueue dequeue];
            [weakSelf.downloadingItems addObject:item];
            [item reallyResume];
            [weakSelf.priorityQueue removeObject];
        }
    });
}

- (void)enqueueItem:(DownloadItem *)downloadItem {
    if (downloadItem) {
        [self.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
        [self dequeueItem];
    }
}

#pragma DownloaderDelegate

- (void)itemWillCancelDownload:(DownloadItem *)downloadItem {
    [_downloadedItems removeObject:downloadItem];
    if (downloadItem.downloadTask.state == NSURLSessionTaskStateRunning) {
        [_downloadingItems removeObject:downloadItem];
    } else {
        [_priorityQueue removeObject:downloadItem withPriority:downloadItem.downloadPriority];
    }
}

- (void)itemWillPauseDownload:(DownloadItem *)downloadItem {
    __weak typeof(self)weakSelf = self;
    [_downloadingItems removeObject:downloadItem];
    dispatch_async(self.serialQueue, ^{
        if (weakSelf.countDownloading > 0) {
            weakSelf.countDownloading--;
        }
    });
    [self dequeueItem];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self)weakSelf = self;
        [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
        [self dequeueItem];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    for (DownloadItem *item in self.downloadedItems) {
        if (item.downloadTask == downloadTask) {
            [item.delegate itemDidUpdateTotalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
            break;
        }
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *documentsURL = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    
    documentsURL = [documentsURL URLByAppendingPathComponent:downloadTask.currentRequest.URL.lastPathComponent];
    
    NSLog(@"%@", documentsURL.absoluteString);
    [NSFileManager.defaultManager moveItemAtURL:location toURL:documentsURL error:nil];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error.code != -999) {
        for (DownloadItem *item in self.downloadedItems) {
            if (item.downloadTask == task) {
                NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
                if (error) {
                    if (error.code == -1001) {
                        item.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                        item.downloadTask = [_session downloadTaskWithResumeData:item.resumeData];
                        return;
                    } else if (error.code == -1005) {
                        item.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                        item.downloadTask = [_session downloadTaskWithResumeData:item.resumeData];
                        [item.downloadTask resume];
                        return;
                    } else {
                        item.downloadState = DownloadItemStateError;
                        [item.delegate itemDidFinishDownload:NO withError:error];
                    }
                } else {
                    if (httpRespone.statusCode/100==2) {
                        item.downloadState = DownloadItemStateComplete;
                        [item.delegate itemDidFinishDownload:YES withError:nil];
                    } else {
                        item.downloadState = DownloadItemStateError;
                        [item.delegate itemDidFinishDownload:NO withError:[NSError errorWithDomain:@"ServerError" code:[(NSHTTPURLResponse*)(task.response) statusCode] userInfo:nil]];
                    }
                }
                break;
            }
        }
        __weak typeof(self)weakSelf = self;
        dispatch_async(weakSelf.serialQueue, ^{
            if (weakSelf.countDownloading > 0) {
                weakSelf.countDownloading--;
            }
        });
        [self dequeueItem];
    }
}

- (void)setCountDownloading:(NSUInteger)countDownloading {
    _countDownloading = countDownloading;
    NSLog(@"Count Downloading: %ld", _countDownloading);
}

- (void)saveResumeData:(void(^)(void))completion {
    [self saveData];
    NSMutableArray* suspendedDownloads = [NSMutableArray new];
    for (DownloadItem* download in _downloadedItems) {
        if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [suspendedDownloads addObject:download];
        }
    }
    if (suspendedDownloads.count == 0) {
        completion();
    }
    for (DownloadItem* download in suspendedDownloads) {
        [download.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                [NSUserDefaults.standardUserDefaults setObject:resumeData forKey:download.url];
            }
            @synchronized (suspendedDownloads) {
                [suspendedDownloads removeObject:download];
                if (suspendedDownloads.count == 0) {
                    completion();
                }
            }
        }];
    }
}

- (void)saveData {
    NSMutableArray *downloadDataArray = [NSMutableArray new];
    for (DownloadItem *item in _downloadedItems) {
        [downloadDataArray addObject:[item transToData]];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:downloadDataArray forKey:kSaveKey];
    [userDefaults synchronize];
}

- (NSArray *)loadData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [userDefaults objectForKey:kSaveKey];
    _downloadedItems = [NSMutableArray new];
    for (NSData *data in array) {
        DownloadItem *item = [[DownloadItem alloc] initWithData:data];
        item.downloaderDelegate = self;
        NSData* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:item.url];
        if (resumeData) {
            item.resumeData = [resumeData copy];
            item.downloadTask = [_session downloadTaskWithResumeData:(NSData*)resumeData];
            [_downloadedItems addObject:item];
        }
    }
    return _downloadedItems;
}

@end
