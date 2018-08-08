//
//  DownloadItem.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItemModel.h"

@protocol DownloaderDelegate <NSObject>

@optional

- (void)itemWillStartDownload;

- (void)itemWillFinishDownload;

- (void)itemWillPauseDownload;

- (void)itemWillCancelDownload;

@end


@interface DownloadItem : DownloadItemModel

@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic, retain) id<DownloaderDelegate> downloaderDelegate;

@end
