//
//  DownloadTableViewObject.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "DownloadCellObject.h"
#import "DownloadTableViewCell.h"

@interface DownloadCellObject()

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
        _state = DownloadStateDownloading;
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
            weakSelf.cell.progressLabel.text = progressString;
        });
    }
}

- (void)progressDidUpdate:(NSUInteger)currentSize total:(NSUInteger)totalSize {

    if (totalSize > 0) {	
        self.progressString = [NSString stringWithFormat:@"%ld/%ld B", currentSize, totalSize];
        self.progress = (float)currentSize / totalSize;
    } else {
        self.progressString = [NSString stringWithFormat:@"%ld B", currentSize];
    }
    

}

- (void)setState:(DownloadState)state {
    if (_state != state) {
        _state = state;
        switch (state) {
            case DownloadStatePause:
                self.progressString = @"Pause";
                [_downloadManager pause];
                break;
            case DownloadStateDownloading:
                [_downloadManager resume];
                break;
            case DownloadStateComplete:
                self.progress = 1.0;
                self.progressString = @"Dowloaded";
                break;
            case DownloadStateError:
                self.progressString = @"Error!";
                break;
            case DownloadStatePending:
                self.progressString = @"Pending...";
                break;
            default:
                break;
        }
        [self backgroudIfNeeded];
    }
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

- (void)downloadFinish:(NSString *)filePath {
    _filePath = filePath;
    if (filePath) {
        self.state = DownloadStateComplete;
    } else {
        self.state = DownloadStateError;
    }
}

- (void)taskWillStartDownload {
    self.state = DownloadStateDownloading;
}

- (void)pause {
    self.state = DownloadStatePause;
}

- (void)resume {
    self.state = DownloadStateDownloading;
}

- (void)cancel {
    [_downloadManager cancel];
}

- (void)upPriority {
    
}

- (void)downPriority {
    
}

- (void)openFile {
    if (_filePath) {
        //_filePath = @"/coconut-tree.jpg";
        
        NSURL *resourceToOpen = [NSURL fileURLWithPath:_filePath];
        BOOL canOpenResource = [[UIApplication sharedApplication] canOpenURL:resourceToOpen];
        if (canOpenResource) {
            [[UIApplication sharedApplication] openURL:resourceToOpen options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    
                } else {
                    
                }
            }];
        }
    }
}
//filePath    __NSCFString *    @"file: ///Us ers/c pu113 67/Li brary /Deve loper /Core Simul ator/ Devic es/B1 692B0 8-2CD 0-4E5 3-9A9 2-18A E9C26 C97C/ data/ Conta iners /Data /Application/B4C3E093-776D-4992-9DB7-8A9EAD644FE1/Documents/coconut-tree.jpg"    0x00006040005a7c40

# pragma constant

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


