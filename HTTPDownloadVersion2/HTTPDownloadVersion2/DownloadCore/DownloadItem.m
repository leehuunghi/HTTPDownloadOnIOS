//
//  DownloadItem.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItem.h"

#define kURL @"url"
#define kFilePath @"filePath"
#define kState @"state"
#define kPriority @"priority"
#define kWritten @"written"
#define kExpected @"expected"

@interface DownloadItem()

@end

@implementation DownloadItem

- (void)updateProgressWithTotalBytesWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.totalBytesWritten = totalBytesWritten;
    self.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    [self.delegate downloadProgressDidUpdate];
}

- (void)reallyResume {
    [self.downloadTask resume];
    self.state = DownloadStateDownloading;
}

#pragma mark - code/decode NSKeyed

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != NULL)
    {
        self.url = [coder decodeObjectForKey:kURL];
        self.filePath = [coder decodeObjectForKey:kFilePath];
        self.state = [coder decodeIntegerForKey:kState];
        self.downloadPriority = [coder decodeIntegerForKey:kPriority];
        self.totalBytesWritten = [coder decodeIntegerForKey:kWritten];
        self.totalBytesExpectedToWrite = [coder decodeIntegerForKey:kExpected];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.url forKey:kURL];
    [coder encodeObject:self.filePath forKey:kFilePath];
    [coder encodeInteger:self.state forKey:kState];
    [coder encodeInteger:self.downloadPriority forKey:kPriority];
    [coder encodeInteger:self.totalBytesWritten forKey:kWritten];
    [coder encodeInteger:self.totalBytesExpectedToWrite forKey:kExpected];
}

- (NSData *)transToData {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:self];
    return encodedObject;
}

- (instancetype)initWithData:(NSData *)data {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - implement DownloadItemModel

- (void)resume {
    self.state = DownloadStatePending;
    [self.downloaderDelegate itemWillStartDownload:self];
}

- (void)pause {
    if (self.downloadTask.state != NSURLSessionTaskStateSuspended) {
        [self.downloadTask suspend];
        self.state = DownloadStatePause;
        if (self.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [self.downloaderDelegate itemWillPauseDownload:self];
        }
    }
}

- (void)cancel {
    [self.downloaderDelegate itemWillCancelDownload:self];
    [self.downloadTask cancel];
}

- (void)restart {
    [self pause];
    [self.downloadTask cancel];
    self.downloadTask = nil;
    [self resume];
}

- (void)open {
    if (self.filePath) {
        NSURL *resourceToOpen = [NSURL fileURLWithPath:self.filePath];
        BOOL canOpenResource = [[UIApplication sharedApplication] canOpenURL:resourceToOpen];
        if (canOpenResource) {
            [[UIApplication sharedApplication] openURL:resourceToOpen options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    
                } else {
                    
                }
            }];
        }
    }
}

@end
