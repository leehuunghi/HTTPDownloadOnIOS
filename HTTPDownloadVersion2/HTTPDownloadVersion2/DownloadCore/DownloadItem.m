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
        _downloadState = DownloadItemStatePending;
        [self.downloaderDelegate itemWillStartDownload:self];
}

- (void)pause {
    if(self.downloadState != DownloadItemStatePause) {
        _downloadState = DownloadItemStatePause;
        [self.delegate itemWillPauseDownload];
        [self.downloadTask suspend];
        [self.downloaderDelegate itemWillPauseDownload:self];
    }
    
}

- (void)reallyResume {
    [self.delegate itemWillStartDownload];
    [self.downloadTask resume];
}

@end
