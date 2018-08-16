//
//  DowloaderModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItemModel.h"

@interface DownloaderModel : NSObject

/**
 Create a Download Item Model

 @param urlString url link to file will download
 @param filePath position and name of file to save when downloaded
 @param priority priority to set oder in download item
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

/**
 Create a Download Item Model with default file path

 @param urlString url link to file will download
 @param priority priority to set oder in download item
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString priority:(DownloadPriority)priority completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

/**
 Create a Download Item Model with default file path and medium priority

 @param urlString url link to file will download
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString completion:(void (^)(DownloadItemModel *downloadItem, NSError *error))completion;

/**
 Cancel all download
 */
- (void)cancelAll;

/**
 Pause all
 */
- (void)pauseAll;

/**
 Save download list and do something

 @param completion block will run after saved
 */
- (void)saveData:(void(^)(void))completion;

/**
 Load download list and return this

 @return donwload item list
 */
- (NSArray *)loadData;

/**
 check link url can download

 @param urlString is link to file need download
 @param completion callback block to return error
 */
- (void)checkURL:(NSString*)urlString completion:(void (^)(NSError* error))completion;

@end
