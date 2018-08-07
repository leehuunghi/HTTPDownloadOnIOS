//
//  DownloadItemModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DownloadItemDelegate <NSObject>

@optional

- (void)itemWillStartDownload;

- (void)itemWillFinishDownload;

- (void)itemWillPauseDownload;

- (void)itemWillCancelDownload;

- (void)itemDidUpdateProgress:(NSProgress *)progress;

@end

@interface DownloadItemModel : NSObject

@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, retain) id<DownloadItemDelegate> delegate;

- (void)suppend;

- (void)resume;

- (void)pause;

- (void)cancel;

@end
