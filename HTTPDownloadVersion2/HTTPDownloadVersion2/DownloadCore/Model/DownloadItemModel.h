//
//  DownloadItemModel.h
//  HTTPDownloadVersion2
//
//  Created by CPU11367 on 8/7/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadEnumType.h"

@interface DownloadItemModel : NSObject

/**
 A string content url to file download
 */
@property (nonatomic, strong) NSString *url;

/**
 Position and  to save file after downloaded
 */
@property (nonatomic, strong) NSString *filePath;

/**
 State of download
 */
@property (nonatomic) DownloadState state;

/**
 Priority queue contain task repair to download
 */
@property (nonatomic) DownloadPriority downloadPriority;

/**
 Total bytes downloaded and written
 */
@property (nonatomic) int64_t totalBytesWritten;

/**
 Total bytes of file download
 */
@property (nonatomic) int64_t totalBytesExpectedToWrite;


@end
