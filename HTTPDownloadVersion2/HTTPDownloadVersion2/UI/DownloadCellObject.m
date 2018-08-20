//
//  DownloadTableViewObject.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "DownloadCellObject.h"
#import "DownloadTableViewCell.h"

@interface DownloadCellObject()<DownloadItemDelegate>

@end

@implementation DownloadCellObject

- (Class)cellClass {
    return [DownloadTableViewCell class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _progress = 0;
        _state = DownloadStatePending;
    }
    return self;
}

- (NSUInteger)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    if (_cell) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cell.titleLabel.text = title;
        });
    }
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if (_cell) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cell.progressView.progress = progress;
        });
    }
}

- (void)setProgressString:(NSString *)progressString {

    _progressString = progressString;
    if (_cell) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cell.progressLabel.text = weakSelf.progressString;
        });
    }
}

- (void)setState:(DownloadState)state {
    _state = state;
    switch (state) {
        case DownloadStateComplete:
            self.progress = 1.0;
            break;
        default:
            break;
    }
    [self backgroudIfNeeded];
}

- (void)backgroudIfNeeded {
    if (_cell) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.cell updateState];
        });
    }
}

- (UIColor *)getColorBackgroud {
    UIColor *backgroudColor;
    switch (_state) {
        case DownloadStateComplete:
            backgroudColor = [DownloadCellObject successColor];
            break;
        case DownloadStateError:
            backgroudColor = [DownloadCellObject errorColor];
            break;
        case DownloadStatePending:
            backgroudColor = [DownloadCellObject pendingColor];
            break;
        case DownloadStatePause:
            backgroudColor = [DownloadCellObject pauseColor];
            break;
        default:
            backgroudColor = [DownloadCellObject normalColor];
            break;
    }
    return backgroudColor;
}

- (void)pause {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader pauseDownloadWithIdentifier:_identifier];
}

- (void)resume {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader resumeDownloadWithIdentifier:_identifier];
}

- (void)cancel {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader cancelDownloadWithIdentifier:_identifier];
}

- (void)restart {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader restartDownloadWithIdentifier:_identifier];
}

- (void)openFile {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader openDownloadedFileWithIdentifier:_identifier];
}

- (void)removeFile {
    DownloaderModel *downloader = [DownloaderSingleton shareIntance].downloader;
    [downloader removeDownloadedFileWithIdentifier:_identifier];
}


- (void)upPriority {
    
}

- (void)downPriority {
    
}


#pragma mark - DownloadItemDelegate

- (void)downloadStateDidUpdate:(DownloadState)state {
    self.state = state;
}

- (void)downloadErrorWithError:(NSError *)error {
    self.progressString = [NSString stringWithFormat:@"Error %ld", error.code];
}

- (void)downloadProgressDidUpdateWithTotalByteWritten:(int64_t)totalBytesWritten andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (totalBytesExpectedToWrite > 0) {
        self.progressString = [NSString stringWithFormat:@"%lld/%lld B", totalBytesWritten, totalBytesExpectedToWrite];
        self.progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    } else {
        self.progressString = [NSString stringWithFormat:@"%lld B", totalBytesWritten];
    }
}

#pragma mark - constant

+ (UIColor *)successColor {
    static UIColor *successColor;
    static dispatch_once_t onceToken1;
    dispatch_once(&onceToken1, ^{
        CGFloat red = 166.0 / 255;
        CGFloat green = 235.0 / 255;
        CGFloat blue = 199.0 / 255;
        successColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    });
    return successColor;
}

+ (UIColor *)errorColor {
    static UIColor *errorColor;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        CGFloat red = 248.0 / 255;
        CGFloat green = 183.0 / 255;
        CGFloat blue = 178.0 / 255;
        errorColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    });
    return errorColor;
}

+ (UIColor *)normalColor {
    static UIColor *normalColor;
    static dispatch_once_t onceToken3;
    dispatch_once(&onceToken3, ^{
        CGFloat red = 171.0 / 255;
        CGFloat green = 214.0 / 255;
        CGFloat blue = 239.0 / 255;
        normalColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    });
    return normalColor;
}

+ (UIColor *)pendingColor {
    static UIColor *pendingColor;
    static dispatch_once_t onceToken4;
    dispatch_once(&onceToken4, ^{
        CGFloat red = 250.0 / 255;
        CGFloat green = 231.0 / 255;
        CGFloat blue = 164.0 / 255;
        pendingColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    });
    return pendingColor;
}

+ (UIColor *)pauseColor {
    static UIColor *pauseColor;
    static dispatch_once_t onceToken5;
    dispatch_once(&onceToken5, ^{
        CGFloat red = 166.0 / 255;
        CGFloat green = 204.0 / 255;
        CGFloat blue = 225.0 / 255;
        pauseColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    });
    return pauseColor;
}


@end


