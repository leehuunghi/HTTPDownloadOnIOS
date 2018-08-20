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

@property (nonatomic, strong) NSMutableArray *downloadItems;

@property (nonatomic, strong) dispatch_queue_t serialQueueDownloader;
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
    __weak typeof(self)weakSelf = self;
    __block DownloadItem *downloadItem;
    __block NSString *identifier;
    dispatch_sync(self.concurrentQueue, ^{
        downloadItem = [weakSelf.downloadItems objectForKey:urlString];
        identifier = downloadItem.url;
    });
    
    if (downloadItem) {
        if (completion) {
            dispatch_barrier_async(self.concurrentQueue, ^{
                [downloadItem.downloadItemDelegates addObject:delegate];
            });
            completion(identifier, nil);
        }
        return;
    }
    
    DownloadItem *item = [DownloadItem new];
    item.downloadState = DownloadItemStatePending;
    item.downloadPriority = priority;
    item.url = urlString;
    item.filePath = filePath;
    
    if (completion) {
        completion(identifier, nil);
    }
    
    [self checkURL:urlString completion:^(NSError *error) {
        if (error) {
            item.state = DownloadItemStateError;
        } else {
            NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:urlString];
            if (resumeData) {
                if ([resumeData isKindOfClass:[NSData class]]) {
                    [weakSelf.userDefaults removeObjectForKey:downloadItem.url];
                    downloadItem.downloadTask = [weakSelf.session downloadTaskWithResumeData:(NSData*)resumeData];
                }
            } else {
                NSURL *url = [NSURL URLWithString:downloadItem.url];
                downloadItem.downloadTask = [weakSelf.session downloadTaskWithURL:url];
            }
            dispatch_async(self.concurrentQueue, ^{
                [weakSelf.downloadItems setObject:item forKey:urlString];
            });
            [self enqueueItem:item];
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
    }];
    [dataTask resume];
}

- (void)enqueueItem:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.concurrentQueue, ^{
            [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
            [weakSelf dequeueItem];
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
        return [self URLSession:session task:task didCompleteWithError:error];
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
            });
        }
    }
}

- (void)restartDownloadWithIdentifier:(NSString *)URLString {
    
}

- (void)openDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)removeDownloadedFileWithIdentifier:(NSString *)URLString {
    
}

- (void)setDelegateForIdentifier:(NSString *)identifier {
}

@end

@property (nonatomic, strong) dispatch_queue_t serialQueueDownloaderRequestURL;

@property (nonatomic, strong) NSMutableArray *downloadingItems;

@property (nonatomic) NSUInteger limitDownloadTask;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation Downloader

- (instancetype)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults new];
        
        _downloadingItems = [[NSMutableArray alloc] init];
        _downloadItems = [[NSMutableArray alloc] init];
        [self loadDataFromUserDefault];
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"download.backgroud"];
        [_configuration setDiscretionary:YES];
        [_configuration setSessionSendsLaunchEvents:YES];
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:nil];
        _priorityQueue = [PriorityQueue new];
        _serialQueueDownloader = dispatch_queue_create("serial_queue_downloader", DISPATCH_QUEUE_SERIAL);
        _serialQueueDownloaderRequestURL = dispatch_queue_create("serial_queue_downloader_request_url", DISPATCH_QUEUE_SERIAL);
        _limitDownloadTask = 2;
    }
    return self;
}

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *, NSError *))completion {
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueueDownloaderRequestURL, ^{
        for (DownloadItem* downloadItem in weakSelf.downloadItems) {
            if ([downloadItem.url compare:urlString] == 0) {
                completion ? completion(downloadItem, nil) : nil;
                return;
            }
        }
        
        DownloadItem *item = [DownloadItem new];
        item.downloadState = DownloadItemStatePending;
        item.downloaderDelegate = self;
        item.downloadPriority = priority;
        item.url = urlString;
        
        completion ? completion(item, nil) : nil;
        
        [self checkURL:urlString completion:^(NSError *error) {
            if (error) {
                item.state = DownloadItemStateError;
            } else {
                NSURL *url = [NSURL URLWithString:urlString];
                if (!item.downloadTask) {
                    item.downloadTask = [weakSelf.session downloadTaskWithURL:url];
                }
                [weakSelf.downloadItems addObject:item];
                [self enqueueItem:item];
            }
        }];
    });
}

- (void)checkURL:(NSString*)urlString completion:(void (^)(NSError* error))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    request.HTTPMethod = @"HEAD";
    NSURLSessionConfiguration* config = NSURLSessionConfiguration.defaultSessionConfiguration;
    NSURLSession *manager =[NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse *)response;
        if (httpRespone.statusCode / 100 == 2) {
            completion ? completion(nil) : nil;
        } else {
            NSError *errorURL = [NSError errorWithDomain:@"com.download.error" code:httpRespone.statusCode userInfo:nil];
            completion ? completion(errorURL) : nil;
        }
    }];
    [dataTask resume];
}

- (NSUInteger)limitDownloadTask {
    return _limitDownloadTask;
}

- (void)dequeueItem {
	    __weak typeof(self)weakSelf = self;
    dispatch_async(self.serialQueueDownloader, ^{
        if (weakSelf.downloadingItems.count < weakSelf.limitDownloadTask && [weakSelf.priorityQueue count] > 0) {
            NSLog(@"%lu %ld",(unsigned long)weakSelf.downloadingItems.count, (long)[weakSelf.priorityQueue count]);
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

#pragma mark - DownloaderDelegate

- (void)itemWillCancelDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        [_downloadItems removeObject:downloadItem];
        if (downloadItem.downloadTask.state != NSURLSessionTaskStateRunning) {
            [_priorityQueue removeObject:downloadItem withPriority:downloadItem.downloadPriority];
        }
    }
}

- (void)itemWillPauseDownload:(DownloadItem *)downloadItem {
    [_downloadingItems removeObject:downloadItem];
    [self dequeueItem];
}

- (void)itemWillStartDownload:(DownloadItem *)downloadItem {
    if (downloadItem) {
        __weak typeof(self)weakSelf = self;
        if (!downloadItem.downloadTask && !downloadItem.url) {
            return;
        }
        
        if (!downloadItem.downloadTask) {
            NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:downloadItem.url];
            if (resumeData) {
                if ([resumeData isKindOfClass:[NSData class]]) {
                    [_userDefaults removeObjectForKey:downloadItem.url];
                    downloadItem.downloadTask = [weakSelf.session downloadTaskWithResumeData:(NSData*)resumeData];
                }
            } else {
                NSURL *url = [NSURL URLWithString:downloadItem.url];
                downloadItem.downloadTask = [weakSelf.session downloadTaskWithURL:url];
            }
        }
        [weakSelf.priorityQueue addObject:downloadItem withPriority:downloadItem.downloadPriority];
        [self dequeueItem];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    for (DownloadItem *item in self.downloadingItems) {
        if (item.downloadTask == downloadTask) {
            [item updateProgressWithTotalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
            break;
        } else {
            if ([item.url compare:downloadTask.currentRequest.URL.absoluteString] == 0) {
                item.downloadTask = downloadTask;
                break;
            }
        }
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSURL *documentsURL = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    
    documentsURL = [documentsURL URLByAppendingPathComponent:downloadTask.currentRequest.URL.lastPathComponent];
    
    [NSFileManager.defaultManager moveItemAtURL:location toURL:documentsURL error:nil];
    for (DownloadItem *item in self.downloadingItems) {
        if (item.downloadTask == downloadTask) {
            item.filePath = documentsURL.absoluteString;
            
            break;
        }
    }
    
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    for (DownloadItem *item in self.downloadingItems) {
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
            [_downloadingItems removeObject:item];
            [self dequeueItem];
            return;
        }
    }
    for (DownloadItem *item in self.downloadingItems) {
        if ([item.url compare:task.currentRequest.URL.absoluteString] == 0) {
            item.downloadTask = (NSURLSessionDownloadTask *)task;
            return [self URLSession:session task:task didCompleteWithError:error];
        }
    }
}

- (void)saveData:(void(^)(void))completion {
    [self saveDataToUserDefault];
    NSMutableArray* suspendedDownloads = [NSMutableArray new];
    for (DownloadItem* download in _downloadItems) {
        if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [suspendedDownloads addObject:download];
        }
    }
    if (suspendedDownloads.count == 0) {
        completion ? completion() : nil;
    }
    for (DownloadItem* download in suspendedDownloads) {
        [download.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                [NSUserDefaults.standardUserDefaults setObject:resumeData forKey:download.url];
            }
            @synchronized (suspendedDownloads) {
                [suspendedDownloads removeObject:download];
                if (suspendedDownloads.count == 0) {
                    completion ? completion() : nil;
                }
            }
        }];
    }
}

#pragma mark - private

- (void)saveDataToUserDefault {
    NSMutableArray *downloadDataArray = [NSMutableArray new];
    for (DownloadItem *item in _downloadItems) {
        [downloadDataArray addObject:[item transToData]];
    }
    
    [_userDefaults setObject:downloadDataArray forKey:kSaveKeyUserDefaut];
    [_userDefaults synchronize];
}

- (void)loadDataFromUserDefault {
    NSArray *array = [_userDefaults objectForKey:kSaveKeyUserDefaut];
    _downloadItems = [NSMutableArray new];
    _downloadingItems = [NSMutableArray new];
    for (NSData *data in array) {
        DownloadItem *item = [[DownloadItem alloc] initWithData:data];
        item.downloaderDelegate = self;
        
        [_downloadItems addObject:item];
        
        if (item.state == DownloadStateDownloading) {
            [_downloadingItems addObject:item];
        }
    }
}

- (NSArray *)loadData {
    if (_downloadItems) {
        [self loadDataFromUserDefault];
    }
    return _downloadItems;
}

@end
