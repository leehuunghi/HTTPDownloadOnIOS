//
//  DowloaderModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloadItemModel.h"
#import "DownloadItemDelegate.h"


@interface DownloaderModel : NSObject

/**
 Create a Download Item Model

 @param urlString url link to file will download
 @param filePath position and name of file to save when downloaded
 @param priority priority to set oder in download item
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSUInteger identifier, NSError *error))completion;

/**
 Create a Download Item Model with default file path

 @param urlString url link to file will download
 @param priority priority to set oder in download item
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSUInteger identifier, NSError *error))completion;

/**
 Create a Download Item Model with default file path and medium priority

 @param urlString url link to file will download
 @param completion callback block to return Download Item Model and error
 */
- (void)createDownloadItemWithUrl:(NSString *)urlString delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSUInteger identifier, NSError *error))completion;

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
 Load download list and return identifier list of download list

 @return donwload item list
 */
- (NSArray *)loadData;

/**
 check link url can download

 @param urlString is link to file need download
 @param completion callback block to return error
 */
- (void)checkURL:(NSString*)urlString completion:(void (^)(NSError* error))completion;


//action
- (void)resumeDownloadWithIdentifier:(NSString *)identifier;

- (void)pauseDownloadWithIdentifier:(NSString *)identifier;

- (void)cancelDownloadWithIdentifier:(NSString *)identifier;

- (void)restartDownloadWithIdentifier:(NSString *)identifier;

- (void)openDownloadedFileWithIdentifier:(NSString *)identifier;

- (void)removeDownloadedFileWithIdentifier:(NSString *)identifier;

//
- (void)setDelegateForIdentifier:(NSString *)identifier;

@end
