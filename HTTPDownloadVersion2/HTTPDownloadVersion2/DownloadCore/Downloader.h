//
//  Downloader.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloaderModel.h"
#import "DownloadItem.h"
#import "PriorityQueue.h"


@interface Downloader : DownloaderModel <DownloaderDelegate, NSURLSessionDownloadDelegate>



@end
