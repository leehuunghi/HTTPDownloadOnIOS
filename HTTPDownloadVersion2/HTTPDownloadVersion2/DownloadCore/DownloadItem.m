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

@end
