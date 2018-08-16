//
//  DownloadItem.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItem.h"

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
        self.url = [coder decodeObjectForKey:@"url"];
        self.filePath = [coder decodeObjectForKey:@"filePath"];
        self.state = [coder decodeIntegerForKey:@"state"];
        self.downloadPriority = [coder decodeIntegerForKey:@"priority"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.filePath forKey:@"filePath"];
    [coder encodeInteger:self.state forKey:@"state"];
    [coder encodeInteger:self.downloadPriority forKey:@"priority"];
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
