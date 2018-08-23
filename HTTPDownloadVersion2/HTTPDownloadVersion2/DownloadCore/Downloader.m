//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#define kSaveKeyUserDefaut @"download_array_data"

#define kDownLoadListFileName @"downloadList.dat"

#define kDownLoadDataFileName @"downloadData.dat"

#import "Downloader.h"

@interface Downloader()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) NSMutableDictionary *downloadItems;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic) NSUInteger limitDownloadTask;

@property (nonatomic) NSUInteger downloadingCount;

@property (nonatomic, strong) NSMutableDictionary *resumeDataDictionnary;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadItems = [[NSMutableDictionary alloc] init];
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"download.background"];
        [_configuration setDiscretionary:YES];
        [_configuration setSessionSendsLaunchEvents:YES];
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueue = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _limitDownloadTask = 2;
        _downloadingCount = 0;
        [self readFromFile];
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSString *identifier, NSError *error))completion {
    if (urlString) {
        __weak typeof(self)weakSelf = self;
        NSString *identifier = urlString;
        if (completion) {
            completion(identifier, nil);
        }
        
        dispatch_async(self.serialQueue, ^{
            DownloadItem *downloadItem  = [weakSelf.downloadItems objectForKey:urlString];
            if (downloadItem) {
                [downloadItem addDelegate:delegate];
            } else {
                downloadItem = [DownloadItem new];
                downloadItem.state = DownloadStatePending;
                downloadItem.downloadPriority = priority;
                downloadItem.url = urlString;
                downloadItem.filePath = filePath;
                downloadItem.downloadItemDelegates = [[NSMutableArray alloc] initWithArray:@[delegate]];
                [weakSelf.downloadItems setObject:downloadItem forKey:urlString];
                [weakSelf checkAndEnqueueDownloadItem:downloadItem];
            }
        });
    }
}

- (void)checkAndEnqueueDownloadItem:(DownloadItem *)downloadItem {
    __weak typeof(self)weakSelf = self;
    [self checkURL:downloadItem.url completion:^(NSError *error) {
        if (error) {
            downloadItem.state = DownloadStateError;
            for (id<DownloadItemDelegate>delegateItem in downloadItem.downloadItemDelegates) {
                [delegateItem downloadErrorWithError:error];
            }
        } else {
            NSData* resumeData = [weakSelf.resumeDataDictionnary objectForKey:downloadItem.url];
            if (resumeData) {
                if ([resumeData isKindOfClass:[NSData class]]) {
                    [weakSelf.resumeDataDictionnary removeObjectForKey:downloadItem.url];
                    downloadItem.downloadTask = [weakSelf.session downloadTaskWithResumeData:resumeData];
                }
            } else {
                NSURL *url = [NSURL URLWithString:downloadItem.url];
                downloadItem.downloadTask = [weakSelf.session downloadTaskWithURL:url];
            }
            [self enqueueItem:downloadItem];
        }
    }];
}

- (void)checkURL:(NSString*)urlString completion:(void (^)(NSError* error))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    request.HTTPMethod = @"HEAD";
    NSURLSessionConfiguration* config = NSURLSessionConfiguration.defaultSessionConfiguration;
    NSURLSession *manager =[NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(error);
        } else {
            NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)response;
            if (httpRespone.statusCode >= 200 && httpRespone.statusCode <= 299) {
                if (completion) {
                    completion(nil);
                }
            } else {
                NSError *errorURL = [NSError errorWithDomain:@"com.download.error" code:httpRespone.statusCode userInfo:nil];
                if (completion) {
                    completion(errorURL);
                }
            }
        }
    }];
    [dataTask resume];
}

- (void)enqueueItem:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            if (downloadItem.state == DownloadStatePending || downloadItem.state == DownloadStatePause) {
                downloadItem.state = DownloadStatePending;
                [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
                [weakSelf dequeueItem];
            }
        });
    }
}

- (void)dequeueItem {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        if (self.downloadingCount < self.limitDownloadTask && self.priorityQueue.count > 0) {
            NSLog(@"In: %lu %ld",(unsigned long)self.downloadingCount, (long)[weakSelf.priorityQueue count]);
            DownloadItem *item = (DownloadItem *)[weakSelf.priorityQueue dequeue];
            if (item) {
                [weakSelf.priorityQueue removeObject:weakSelf.serialQueue];
                [weakSelf increaseDownloadingCount];
                [item resume];
                NSLog(@"Resume: %lu %ld",(unsigned long)weakSelf.downloadingCount, (long)[self.priorityQueue count]);
            }
        }
    });
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        DownloadItem *item = [weakSelf.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
        if (item) {
            if (item.downloadTask) {
                [item updateProgressWithTotalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
            } else {
                [self increaseDownloadingCount];
                item.downloadTask = downloadTask;
            }
        }
    });
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *documentsURL = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    
    documentsURL = [documentsURL URLByAppendingPathComponent:downloadTask.currentRequest.URL.lastPathComponent];
    
    [NSFileManager.defaultManager moveItemAtURL:location toURL:documentsURL error:nil];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        DownloadItem *item = [weakSelf.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
        if (item) {
            item.filePath = documentsURL.absoluteString;
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        DownloadItem *item = [self.downloadItems objectForKey:task.originalRequest.URL.absoluteString];
        if (item.downloadTask == task) {
            NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
            if (error) {
                switch (error.code) {
                    case NSURLErrorCancelled: {
                        __weak typeof(self)weakSelf = self;
                        dispatch_async(weakSelf.serialQueue, ^{
                            [weakSelf.downloadItems removeObjectForKey:item.url];
                            if (item.state == DownloadStateDownloading && item.downloadTask.state == NSURLSessionTaskStateSuspended) {
                                [weakSelf.priorityQueue removeObject:item withPriority:item.downloadPriority];
                            } else if (item.state == DownloadStatePause) {
                                return;
                            }
                        });
                        break;
                    }
                    case NSURLErrorTimedOut: {
                        NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                        item.downloadTask = [weakSelf.session downloadTaskWithResumeData:resumeData];
                        return;
                    }
                    case NSURLErrorNetworkConnectionLost: {
                        NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                        item.downloadTask = [weakSelf.session downloadTaskWithResumeData:resumeData];
                        [item.downloadTask resume];
                        return;
                    }
                    default: {
                        item.state = DownloadStateError;
                        break;
                    }
                }
            } else {
                if (httpRespone.statusCode >= 200 && httpRespone.statusCode <= 299) {
                    item.state = DownloadStateComplete;
                } else {
                    item.state = DownloadStateError;
                }
            }
            [self decreaseDownloadingCount];
            [self dequeueItem];
        } else {
            if (item.url == task.originalRequest.URL.absoluteString) {
                item.downloadTask = (NSURLSessionDownloadTask *)task;
            }
        }
    });
}

- (void)saveData:(void(^)(void))completion {
    [self writeToFile];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    if ([paths count] == 0) {
        return completion();
    }
    NSString *filePath = [[paths objectAtIndex:0]
                          stringByAppendingPathComponent:kDownLoadDataFileName];
    dispatch_queue_t sQueue = dispatch_queue_create("download_save", DISPATCH_QUEUE_SERIAL);
    NSMutableDictionary *dict = [NSMutableDictionary new];
    __block NSUInteger count = 0;
    __weak __typeof(self) weakSelf = self;
    
    for (DownloadItem* download in [_downloadItems allValues]) {
        if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [download.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                if (resumeData) {
                    dispatch_async(sQueue, ^{
                        [dict setObject:resumeData forKey:download.url];
                    });
                }
                ++count;
                if (count == weakSelf.downloadItems.count) {
                    dispatch_async(sQueue, ^{
                        [dict writeToFile:filePath atomically:YES];
                        completion();
                    });
                }
            }];
        } else {
            ++count;
            if (count == weakSelf.downloadItems.count) {
                dispatch_async(sQueue, ^{
                    [dict writeToFile:filePath atomically:YES];
                    completion();
                });
            }
        }
        
    }
}

- (NSArray *)loadData {
    if (_downloadItems) {
        [self readFromFile];
    }
    return _downloadItems.allKeys;
}

#pragma mark - private

- (void)writeToFile {
    NSMutableArray *downloadDataArray = [NSMutableArray new];
    for (DownloadItem *item in [_downloadItems allValues]) {
        [downloadDataArray addObject:[item transToData]];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    if ([paths count] > 0) {
        NSString *filePath = [[paths objectAtIndex:0]
                     stringByAppendingPathComponent:kDownLoadListFileName];
        
        [downloadDataArray writeToFile:filePath atomically:YES];
    }
}

- (void)readFromFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    if ([paths count] > 0) {
        NSString *filePath = [[paths objectAtIndex:0]
                              stringByAppendingPathComponent:kDownLoadDataFileName];
        _resumeDataDictionnary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
        
        filePath = [[paths objectAtIndex:0]
                    stringByAppendingPathComponent:kDownLoadListFileName];
        NSArray *array = [NSArray arrayWithContentsOfFile:filePath];
        
        for (NSData *data in array) {
            DownloadItem *item = [[DownloadItem alloc] initWithData:data];
            [_downloadItems setObject:item forKey:item.url];
            if (item.state == DownloadStatePending) {
                [self enqueueItem:item];
            } else if (item.state == DownloadStatePause) {
                NSData *resumeData = [_resumeDataDictionnary objectForKey:item.url];
                item.downloadTask = [_session downloadTaskWithResumeData:resumeData];
            }
        }
    }
}

//- (void)saveDataToUserDefault {
//    NSMutableArray *downloadDataArray = [NSMutableArray new];
//    for (DownloadItem *item in [_downloadItems allValues]) {
//        [downloadDataArray addObject:[item transToData]];
//    }
//
//    [_userDefaults setObject:downloadDataArray forKey:kSaveKeyUserDefaut];
//    [_userDefaults synchronize];
//}
//
//- (void)loadDataFromUserDefault {
//    NSArray *array = [_userDefaults objectForKey:kSaveKeyUserDefaut];
//    for (NSData *data in array) {
//        DownloadItem *item = [[DownloadItem alloc] initWithData:data];
//        [_downloadItems setObject:item forKey:item.url];
//        if (item.state == DownloadStateDownloading) {
//            _downloadingCount++;
//        }
//    }
//}

- (void)resumeDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        __weak typeof(self) weakSelf = self;
        DownloadItem *downloadItem = [self.downloadItems objectForKey:URLString];
        dispatch_async(_serialQueue, ^{
            if (downloadItem.state != DownloadStateDownloading) {
                [weakSelf enqueueItem:downloadItem];
            }
        });
    }
}

- (void)pauseDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(_serialQueue, ^{
                if (downloadItem.state == DownloadStateDownloading) {
                    if (downloadItem.downloadTask.state == NSURLSessionTaskStateRunning) {
                        [weakSelf decreaseDownloadingCount];
                    }
                    [downloadItem pause];
                    [weakSelf dequeueItem];
                }
            });
        }
    }
}

- (void)cancelDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            dispatch_async(_serialQueue, ^{
                [downloadItem cancel];
            });
        }
    }
}

- (void)restartDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            [downloadItem.downloadTask cancel];
            downloadItem.downloadTask = nil;
            downloadItem.state = DownloadStatePending;
            [self checkAndEnqueueDownloadItem:downloadItem];
        }
    }
}

- (void)openDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)removeDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)setDelegate:(id<DownloadItemDelegate>)delegate forIdentifier:(NSString *)identifier {
    DownloadItem *item = [_downloadItems objectForKey:identifier];
    [item addDelegate:delegate];
}

- (NSString *)getFileNameWithIdentifier:(NSString *)identifier {
    return identifier.lastPathComponent;
}

- (void)increaseDownloadingCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        if (weakSelf.downloadingCount < weakSelf.limitDownloadTask) {
            weakSelf.downloadingCount++;
        }
    });
}

- (void)decreaseDownloadingCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        if (weakSelf.downloadingCount > 0) {
            weakSelf.downloadingCount--;
        }
    });
}

- (void)setDownloadingCount:(NSUInteger)downloadingCount {
    _downloadingCount = downloadingCount;
    NSLog(@"Count Downloading: %lu", (unsigned long)downloadingCount);
}

@end
