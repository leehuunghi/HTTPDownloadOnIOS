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

/**
 It will be call every Download Item error

 @param error decription
 */
- (void)downloadErrorWithError:(NSError *)error;

/**
 It will be call every Download Item update state

 @param state download state
 */
- (void)downloadStateDidUpdate:(DownloadState)state;

/**
 It will be call every Download Item update progress

 @param totalBytesWritten total bytes written
 @param totalBytesExpectedToWrite total bytes of file
 */
- (void)downloadProgressDidUpdateWithTotalByteWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

/**
 It will be call when add new delegate for exist download item

 @param priority download priority
 */
- (void)shouldUpdatePriority:(DownloadPriority)priority;

@end
