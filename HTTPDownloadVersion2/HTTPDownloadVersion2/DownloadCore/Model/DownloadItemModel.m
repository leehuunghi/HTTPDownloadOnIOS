//
//  DownloadItemModel.m
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItemModel.h"

@implementation DownloadItemModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadPriority = DownloadPriorityMedium;
        _state = DownloadStatePending;
    }
    return self;
}

- (void)suppend {
    
}

- (void)resume {
    
}

- (void)pause {

}

- (void)cancel {
    
}

- (void)restart {
    
}

- (void)open {
    
}

@end
