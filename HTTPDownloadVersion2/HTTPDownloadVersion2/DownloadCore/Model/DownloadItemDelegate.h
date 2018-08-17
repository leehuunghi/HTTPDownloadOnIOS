//
//  DownloadItemDelegate.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/17/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadEnumType.h"

@protocol DownloadItemDelegate <NSObject>

@optional

- (void)downloadErrorWithError:(NSError *)error;

/**
 It will be call every Download Item update state
 */
- (void)downloadStateDidUpdate:(DownloadState)state;

/**
 It will be call every Download Item update process
 */
- (void)downloadProgressDidUpdateWithTotalByteWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

@end
