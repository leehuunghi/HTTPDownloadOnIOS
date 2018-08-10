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

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)resume {
    [self.downloaderDelegate itemWillStartDownload:self];
}

- (void)pause {
    if (self.downloadTask.state != NSURLSessionTaskStateSuspended) {
        [self.downloadTask suspend];
        if (self.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [self.delegate itemWillPauseDownload];
            [self.downloaderDelegate itemWillPauseDownload:self];
        }
    }
}

- (void)reallyResume {
    [self.delegate itemWillStartDownload];
    [self.downloadTask resume];
}

- (void)cancel {
    [self.downloaderDelegate itemWillCancelDownload:self];
    [self.downloadTask cancel];
}

@end
