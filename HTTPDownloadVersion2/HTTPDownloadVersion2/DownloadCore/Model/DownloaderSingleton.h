//
//  DownloaderSingleton.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/17/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Downloader.h"

@interface DownloaderSingleton : NSObject

@property (strong, nonatomic, readwrite) DownloaderModel *downloader;

+ (DownloaderSingleton *)shareIntance;

@end
