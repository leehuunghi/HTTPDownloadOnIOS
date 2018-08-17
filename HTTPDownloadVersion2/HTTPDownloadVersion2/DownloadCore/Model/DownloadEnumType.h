//
//  DownloadPriority.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#ifndef DownloadPriority_h
#define DownloadPriority_h

typedef NS_ENUM(NSInteger, DownloadPriority){
    DownloadPriorityLow = 0,
    DownloadPriorityMedium = 1,
    DownloadPriorityHigh = 2
};

typedef NS_ENUM(NSUInteger, DownloadState) {
    DownloadStatePending = 0,
    DownloadStateDownloading,
    DownloadStatePause,
    DownloadStateComplete,
    DownloadStateError
};

#endif /* DownloadPriority_h */
