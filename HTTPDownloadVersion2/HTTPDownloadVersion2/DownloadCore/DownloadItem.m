//
//  DownloadItem.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItem.h"

@interface DownloadItem()
@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;
@end

@implementation DownloadItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithUrlAndFileName:(NSString *)url fileName:(NSString *)fileName session:(NSURLSession *)session{
    NSURL *URL = [NSURL URLWithString:url];
    
    _downloadTask = [session downloadTaskWithURL:URL];
    _downloadTask = [session downloadTaskWithURL:URL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    return self;
}

@end
