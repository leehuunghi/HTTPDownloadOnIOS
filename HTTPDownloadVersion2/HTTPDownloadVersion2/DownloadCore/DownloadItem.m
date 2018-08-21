//
//  DownloadItem.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItem.h"
#import <UIKit/UIKit.h>

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
    for (id<DownloadItemDelegate> delegate in _downloadItemDelegates) {
        if (delegate && [delegate respondsToSelector:@selector(downloadProgressDidUpdateWithTotalByteWritten:andTotalBytesExpectedToWrite:)]) {
            [delegate downloadProgressDidUpdateWithTotalByteWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
    }
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
    [self.downloadTask resume];
    [self getState];
}

- (void)pause {
    [self.downloadTask suspend];
    [self getState];
}

- (void)cancel {
    [self.downloadTask cancel];
}

- (void)restart {
    [self.downloadTask cancel];
    self.downloadTask = nil;
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

- (DownloadState)getState {
    switch (self.downloadTask.state) {
        case NSURLSessionTaskStateRunning:
            self.state = DownloadStateDownloading;
            break;
        case NSURLSessionTaskStateSuspended:
            self.state = DownloadStatePause;
            break;
        case NSURLSessionTaskStateCanceling:
            break;
        case NSURLSessionTaskStateCompleted:
            self.state = DownloadStateComplete;
            break;
        default:
            self.state = DownloadStateError;
            break;
    }
    return self.state;
};

- (void)setState:(DownloadState)state {
    _state = state;
    for (id<DownloadItemDelegate> delegate in self.downloadItemDelegates) {
        if (delegate && [delegate respondsToSelector:@selector(downloadStateDidUpdate:)]) {
            [delegate downloadStateDidUpdate:state];
        }
    }
}

- (void)addDelegate:(id<DownloadItemDelegate>)delegate {
    if (delegate) {
        if ([delegate respondsToSelector:@selector(downloadStateDidUpdate:)]) {
            [delegate downloadStateDidUpdate:_state];
        }
        if ([delegate respondsToSelector:@selector(downloadProgressDidUpdateWithTotalByteWritten:andTotalBytesExpectedToWrite:)]) {
            [delegate downloadProgressDidUpdateWithTotalByteWritten:_totalBytesWritten andTotalBytesExpectedToWrite:_totalBytesExpectedToWrite];
        }
    }
    [_downloadItemDelegates addObject:delegate];
}

@end
