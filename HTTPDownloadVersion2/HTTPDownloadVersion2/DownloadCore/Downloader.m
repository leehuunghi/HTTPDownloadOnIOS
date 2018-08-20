//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#define kSaveKeyUserDefaut @"download_array_data"


#import "Downloader.h"

@interface Downloader()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) NSMutableDictionary *downloadItems;

@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

@property (nonatomic) NSUInteger limitDownloadTask;

@property (nonatomic) NSUInteger downloadingCount;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults new];
        _downloadItems = [[NSMutableDictionary alloc] init];
        [self loadDataFromUserDefault];
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"download.background"];
        [_configuration setDiscretionary:YES];
        [_configuration setSessionSendsLaunchEvents:YES];
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _concurrentQueue = dispatch_queue_create("concurrent_queue_downloader", DISPATCH_QUEUE_CONCURRENT);
        _limitDownloadTask = 2;
        _downloadingCount = 0;
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSString *identifier, NSError *error))completion {
    if (urlString) {
        __weak typeof(self)weakSelf = self;
        __block DownloadItem *downloadItem;
        NSString *identifier = urlString;
        if (completion) {
            completion(identifier, nil);
        }
        
        dispatch_sync(self.concurrentQueue, ^{
            downloadItem = [weakSelf.downloadItems objectForKey:urlString];
        });
        
        if (downloadItem) {
            dispatch_barrier_async(self.concurrentQueue, ^{
                [downloadItem.downloadItemDelegates addObject:delegate];
            });
        } else {
            DownloadItem *item = [DownloadItem new];
            item.downloadState = DownloadItemStatePending;
            item.downloadPriority = priority;
            item.url = urlString;
            item.filePath = filePath;
            item.downloadItemDelegates = [[NSMutableArray alloc] initWithArray:@[delegate]];
            [self checkURL:urlString completion:^(NSError *error) {
                if (error) {
                    item.state = DownloadItemStateError;
                    for (id<DownloadItemDelegate>delegateItem in item.downloadItemDelegates) {
                        [delegateItem downloadErrorWithError:error];
                    }
                } else {
                    NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:urlString];
                    if (resumeData) {
                        if ([resumeData isKindOfClass:[NSData class]]) {
                            [weakSelf.userDefaults removeObjectForKey:downloadItem.url];
                            item.downloadTask = [weakSelf.session downloadTaskWithResumeData:(NSData*)resumeData];
                        }
                    } else {
                        NSURL *url = [NSURL URLWithString:urlString];
                        item.downloadTask = [weakSelf.session downloadTaskWithURL:url];
                    }
                    dispatch_async(self.concurrentQueue, ^{
                        [weakSelf.downloadItems setObject:item forKey:urlString];
                    });
                    [self enqueueItem:item];
                }
            }];
        }
    }
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
        dispatch_async(self.concurrentQueue, ^{
            if (downloadItem.state == DownloadStatePending || downloadItem.state == DownloadStatePause) {
                [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
                [weakSelf dequeueItem];
            }
        });
    }
}

- (void)dequeueItem {
    if (self.downloadingCount < self.limitDownloadTask && self.priorityQueue.count > 0) {
        NSLog(@"%lu %ld",(unsigned long)self.downloadingCount, (long)[self.priorityQueue count]);
        DownloadItem *item = (DownloadItem *)[self.priorityQueue dequeue];
        if (item) {
            [self.priorityQueue removeObject];
            self.downloadingCount++;
            [item resume];
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    __block DownloadItem *item;
    dispatch_sync(self.concurrentQueue, ^{
        item = [self.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
    });
    if (item) {
        if (item.downloadTask) {
            [item updateProgressWithTotalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
        } else {
            item.downloadTask = downloadTask;
        }
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *documentsURL = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    
    documentsURL = [documentsURL URLByAppendingPathComponent:downloadTask.currentRequest.URL.lastPathComponent];
    
    [NSFileManager.defaultManager moveItemAtURL:location toURL:documentsURL error:nil];
    
    __block DownloadItem *item;
    dispatch_sync(self.concurrentQueue, ^{
        item = [self.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
    });
    if (item) {
        item.filePath = documentsURL.absoluteString;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __block DownloadItem *item;
    dispatch_sync(self.concurrentQueue, ^{
        item = [self.downloadItems objectForKey:task.originalRequest.URL.absoluteString];
    });
    
    if (item.downloadTask == task) {
        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
        if (error) {
            switch (error.code) {
                case NSURLErrorCancelled:
                    break;
                case NSURLErrorTimedOut: {
                    NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    item.downloadTask = [_session downloadTaskWithResumeData:resumeData];
                    return;
                }
                case NSURLErrorNetworkConnectionLost: {
                    NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    item.downloadTask = [_session downloadTaskWithResumeData:resumeData];
                    [item.downloadTask resume];
                    return;
                }
                default: {
                    item.downloadState = DownloadItemStateError;
                    item.state = DownloadStateError;
                    break;
                }
            }
        } else {
            if (httpRespone.statusCode/100==2) {
                item.downloadState = DownloadItemStateComplete;
                item.state = DownloadStateComplete;
            } else {
                item.downloadState = DownloadItemStateError;
                item.state = DownloadStateError;
            }
        }
        __weak typeof(self) weakSelf = self;
        dispatch_async(_concurrentQueue, ^{
            [weakSelf.downloadItems removeObjectForKey:item.url];
            [self dequeueItem];
        });
        return;
    } else {
        item.downloadTask = (NSURLSessionDownloadTask *)task;
    }
}

- (void)saveData:(void(^)(void))completion {
    [self saveDataToUserDefault];
    NSMutableArray* suspendedDownloads = [NSMutableArray new];
    for (DownloadItem* download in [_downloadItems allValues]) {
        if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [suspendedDownloads addObject:download];
        }
    }
    if (suspendedDownloads.count == 0) {
        if (completion) {
            completion();
        }
    }
    for (DownloadItem* download in suspendedDownloads) {
        [download.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                [NSUserDefaults.standardUserDefaults setObject:resumeData forKey:download.url];
            }
            @synchronized (suspendedDownloads) {
                [suspendedDownloads removeObject:download];
                if (suspendedDownloads.count == 0) {
                    if (completion) {
                        completion();
                    }
                }
            }
        }];
    }
}

#pragma mark - private

- (void)saveDataToUserDefault {
    NSMutableArray *downloadDataArray = [NSMutableArray new];
    for (DownloadItem *item in [_downloadItems allValues]) {
        [downloadDataArray addObject:[item transToData]];
    }
    
    [_userDefaults setObject:downloadDataArray forKey:kSaveKeyUserDefaut];
    [_userDefaults synchronize];
}

- (void)loadDataFromUserDefault {
    NSArray *array = [_userDefaults objectForKey:kSaveKeyUserDefaut];
    for (NSData *data in array) {
        DownloadItem *item = [[DownloadItem alloc] initWithData:data];
        [_downloadItems setObject:item forKey:item.url];
        if (item.state == DownloadStateDownloading) {
            _downloadingCount++;
        }
    }
}

- (NSMutableDictionary *)loadData {
    if (_downloadItems) {
        [self loadDataFromUserDefault];
    }
    return _downloadItems;
}

- (void)resumeDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem *downloadItem = [self.downloadItems objectForKey:URLString];
        [self enqueueItem:downloadItem];
    }
}

- (void)pauseDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            if (downloadItem.state == DownloadStateDownloading) {
                [downloadItem pause];
                __weak typeof(self) weakSelf = self;
                dispatch_async(_concurrentQueue, ^{
                    weakSelf.downloadingCount++;
                    [weakSelf dequeueItem];
                });
            }
        }
        
    }
}

- (void)cancelDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(_concurrentQueue, ^{
                [weakSelf.downloadItems removeObjectForKey:URLString];
                if (downloadItem.state == DownloadItemStatePending) {
                    [weakSelf.priorityQueue removeObject:downloadItem withPriority:downloadItem.downloadPriority];
                }
                [downloadItem cancel];
            });
        }
    }
}

- (void)restartDownloadWithIdentifier:(NSString *)URLString {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        DownloadItem* downloadItem = [self.downloadItems objectForKey:URLString];
        if (downloadItem) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(_concurrentQueue, ^{
                [downloadItem.downloadTask cancel];
            });
        }
    }
}

- (void)openDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)removeDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)setDelegateForIdentifier:(NSString *)identifier {
}

@end
