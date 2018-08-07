//
//  Downloader.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"

@interface Downloader : NSObject

- (void)downloadTaskWithUrl:(NSString *)url success:(void (^)(DownloadItem* downloadItem))completionSuccess failure:(void (^)(NSError *))completionFailure;

- (DownloadItem *)createDownloadItemWithUrl:(NSString *)url andFileName:(NSString *)fileName;

@end
