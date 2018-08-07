//
//  DownloadItem.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadItem : NSObject

@property (nonatomic, strong) NSString* url;

@property (nonatomic, strong) NSProgress* progress;

@property (nonatomic, strong) NSString* filePath;

- (void)suppend;

- (void)resume;

- (void)pause;

- (void)cancel;

- (instancetype)initWithUrlAndFileName:(NSString *)url fileName:(NSString *)fileName session:(NSURLSession *)session;

@end
