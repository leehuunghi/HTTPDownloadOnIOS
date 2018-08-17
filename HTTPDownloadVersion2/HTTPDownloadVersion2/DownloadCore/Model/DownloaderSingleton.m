//
//  DownloaderSingleton.m
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/17/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloaderSingleton.h"


@implementation DownloaderSingleton

+ (DownloaderSingleton *)shareDownloader {
    static DownloaderSingleton *intance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        intance = [DownloaderSingleton new];
    });
    return intance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
