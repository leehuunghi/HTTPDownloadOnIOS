//
//  Downloader.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#define kSaveKeyUserDefaut @"download_array_data"


#import "Downloader.h"
#import "WrapperMutableDictionary.h"

@interface Downloader()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) PriorityQueue *priorityQueue;

@property (nonatomic, strong) WrapperMutableDictionary *downloadItems;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic) NSUInteger limitDownloadTask;

@property (nonatomic) NSUInteger downloadingCount;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults new];
        _downloadItems = [[WrapperMutableDictionary alloc] init];
        [self loadDataFromUserDefault];
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"download.background"];
        [_configuration setDiscretionary:YES];
        [_configuration setSessionSendsLaunchEvents:YES];
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueue = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _limitDownloadTask = 2;
        _downloadingCount = 0;
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
                [weakSelf checkURL:urlString completion:^(NSError *error) {
                    if (error) {
                        downloadItem.state = DownloadStateError;
                        for (id<DownloadItemDelegate>delegateItem in downloadItem.downloadItemDelegates) {
                            [delegateItem downloadErrorWithError:error];
                        }
                    } else {
                        NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:urlString];
                        if (resumeData) {
                            if ([resumeData isKindOfClass:[NSData class]]) {
                                [weakSelf.userDefaults removeObjectForKey:downloadItem.url];
                                downloadItem.downloadTask = [weakSelf.session downloadTaskWithResumeData:(NSData*)resumeData];
                            }
                        } else {
                            NSURL *url = [NSURL URLWithString:urlString];
                            downloadItem.downloadTask = [weakSelf.session downloadTaskWithURL:url];
                        }
                        [weakSelf enqueueItem:downloadItem];
                    }
                }];
            }
        });
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
        dispatch_async(self.serialQueue, ^{
            if (downloadItem.state == DownloadStatePending || downloadItem.state == DownloadStatePause) {
                downloadItem.state = DownloadStateDownloading;
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
    DownloadItem *item = [self.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
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
    
    DownloadItem *item = [self.downloadItems objectForKey:downloadTask.originalRequest.URL.absoluteString];
    if (item) {
        item.filePath = documentsURL.absoluteString;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DownloadItem *item = [self.downloadItems objectForKey:task.originalRequest.URL.absoluteString];
    if (item.downloadTask == task) {
        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)task.response;
        if (error) {
            switch (error.code) {
                case NSURLErrorCancelled: {
                    __weak typeof(self)weakSelf = self;
                    dispatch_async(_serialQueue, ^{
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
                    item.state = DownloadStateError;
                    break;
                }
            }
        } else {
            if (httpRespone.statusCode/100==2) {
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
        }
    }
}

- (void)openDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)removeDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)setDelegateForIdentifier:(NSString *)identifier {
}

- (void)increaseDownloadingCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        if (weakSelf.downloadingCount < weakSelf.limitDownloadTask) {
            NSLog(@"t tang ne nha ahihi");
            weakSelf.downloadingCount++;
        }
    });
}

- (void)decreaseDownloadingCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        if (weakSelf.downloadingCount > 0) {
            NSLog(@"t giam ne nha ahihi");
            weakSelf.downloadingCount--;
        }
    });
}

- (void)setDownloadingCount:(NSUInteger)downloadingCount {
    _downloadingCount = downloadingCount;
    NSLog(@"Count Downloading: %lu", (unsigned long)downloadingCount);
}

@end
