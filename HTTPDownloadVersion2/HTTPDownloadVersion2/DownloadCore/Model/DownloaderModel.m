//
//  DowloaderModel.m
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "DownloaderModel.h"

@implementation DownloaderModel

- (void)createDownloadItemWithUrl:(NSString *)urlString filePath:(NSString *)filePath priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSString *identifier, NSError *error))completion {
}

- (void)createDownloadItemWithUrl:(NSString *)urlString priority:(DownloadPriority)priority delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSString *identifier, NSError *error))completion {
    
}

- (void)createDownloadItemWithUrl:(NSString *)urlString delegate:(id<DownloadItemDelegate>)delegate completion:(void (^)(NSString *identifier, NSError *error))completion {
    
}

- (void)cancelAll {
    
}

- (void)pauseAll {
    
}

- (void)saveData:(void(^)(void))completion {

}

- (void)saveData {
    
}

- (NSArray *)loadData {
    return nil;
}

- (void)checkURL:(NSString*)urlString completion:(void (^)(NSError* error))completion {
    
}

#pragma mark - single

- (void)resumeDownloadWithIdentifier:(NSString *)identifier {
    
}

- (void)pauseDownloadWithIdentifier:(NSString *)identifier {
    
}

- (void)cancelDownloadWithIdentifier:(NSString *)identifier {
    
}

- (void)restartDownloadWithIdentifier:(NSString *)identifier {
    
}

- (void)openDownloadedFileWithIdentifier:(NSString *)identifier {
    
}

- (void)removeDownloadedFileWithIdentifier:(NSString *)identifier {
    
}

- (NSString *)getFileNameWithIdentifier:(NSString *)identifier {
    return nil;
}

- (void)setDelegate:(id<DownloadItemDelegate>)delegate forIdentifier:(NSString *)identifier {
    
}

@end
