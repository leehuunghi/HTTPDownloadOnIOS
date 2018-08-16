//
//  DownloadTableViewCell.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/30/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "DownloadTableViewCell.h"
#import "DownloadCellObject.h"
#import "DownloadTableView.h"

@interface DownloadTableViewCell()

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (weak, nonatomic) IBOutlet UIButton *resumeButton;

@end

@implementation DownloadTableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [_progressView setHidden:NO];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(id)sender {
    if (_cellObject) {
        [_cellObject openFile];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:YES];
    if (selected) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setSelected:NO];
        });
    }
    
    // Configure the view for the selected state
}

+ (TableViewCellModel *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DownloadTableViewCell";
    TableViewCellModel *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (BOOL)shouldUpdateWithObject:(id)anObject {
    if (![anObject isKindOfClass:[DownloadCellObject class]]) {
        return false;
    }
    DownloadCellObject *object = anObject;
    _titleLabel.text = object.title;
    _progressLabel.text = object.progressString;
    _progressView.progress = object.progress;
    if (self.cellObject) {
        self.cellObject.cell = nil;
    }
    object.cell = self;
    self.cellObject = object;
    [self updateState];
    [self setPriority:object.priority];
    [self setStateString:object.state];
    return true;
}

#pragma mark - event

- (IBAction)cencelButtonTouch:(id)sender {
    if (!_cellObject) {
        return;
    }
    
    id view = [self superview];
    
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    DownloadTableView *tableView = view;
    
    switch (_cellObject.state) {
        case DownloadStateError:
            [tableView removeCell:self.cellObject];
            break;
        case DownloadStateComplete: {
            __weak typeof(self)weakSelf = self;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Cancel" message:@"Do you want to delete downloaded file?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* exitAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [weakSelf.cellObject cancel];
                [tableView removeCell:self.cellObject];
            }];
            
            UIAlertAction* comebackAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [weakSelf.cellObject cancel];
                [tableView removeCell:self.cellObject];
            }];
            
            [alert addAction:exitAction];
            [alert addAction:comebackAction];
            UIViewController *viewCotroller = [UIApplication sharedApplication].windows[0].rootViewController;
            [viewCotroller presentViewController:alert animated:YES completion:nil];
            break;
        }
        default: {
            __weak typeof(self)weakSelf = self;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Cancel" message:@"Do you want to cancel downloading this file?\nWhich will remove downloaded data" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* exitAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [weakSelf.cellObject cancel];
                [tableView removeCell:self.cellObject];
            }];
            
            UIAlertAction* comebackAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:exitAction];
            [alert addAction:comebackAction];
            UIViewController *viewCotroller = [UIApplication sharedApplication].windows[0].rootViewController;
            [viewCotroller presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
}

- (IBAction)pauseButtonTouch:(id)sender {
    if (_cellObject) {
        [_cellObject pause];
    }
}

- (IBAction)resumeButtonTouch:(id)sender {
    if (_cellObject) {
        [_cellObject resume];
    }
}

- (IBAction)restartButtonClick:(id)sender {
    if (!_cellObject) {
        return;
    }
    
    switch (_cellObject.state) {
        case DownloadStateError:
            [_progressView setHidden:NO];
            [_cellObject restart];
            break;
            
        default: {
//            [_progressView setHidden:NO];
//            [_cellObject restart];
            __weak typeof(self)weakSelf = self;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Restart" message:@"Do you want to predownload this file?\nWhich will remove downloaded data" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* exitAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [weakSelf.progressView setHidden:NO];
                [weakSelf.cellObject restart];
            }];
            
            UIAlertAction* comebackAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:exitAction];
            [alert addAction:comebackAction];
            UIViewController *viewCotroller = [UIApplication sharedApplication].windows[0].rootViewController;
            [viewCotroller presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - state

- (void)updateState {
    if (_cellObject) {
        switch (_cellObject.state) {
            case DownloadStateDownloading:
                [self resumeState];
                break;
            case DownloadStatePause:
                [self pauseState];
                break;
            case DownloadStateComplete:
            case DownloadStateError:
                [_progressView setHidden:YES];
            default:
                [self noDownloadState];
                break;
        }
        [self setStateString:_cellObject.state];
        //self.backgroundColor = [_cellObject getColorBackgroud];
    }
    
}

- (void)pauseState {
    [_pauseButton setHidden:YES];
    [_resumeButton setHidden:NO];
    [_progressView setHidden:NO];
}

- (void)resumeState {
    [_pauseButton setHidden:NO];
    [_resumeButton setHidden:YES];
    [_progressView setHidden:NO];
}

- (void)noDownloadState {
    [_resumeButton setHidden:YES];
    [_pauseButton setHidden:YES];
}

- (void)setPriority:(DownloadPriority)priority {
    switch (priority) {
        case DownloadPriorityLow:
            _priorityLabel.text = @"Low";
            break;
        case DownloadPriorityHigh:
            _priorityLabel.text = @"High";
            break;
        default:
            _priorityLabel.text = @"Medium";
            break;
    }
}

- (void)setStateString:(DownloadState)state {
    switch (state) {
        case DownloadStatePause:
            self.progressLabel.text = @"Pause";
            break;
        case DownloadStatePending:
            self.progressLabel.text = @"Pending...";
            break;
        case DownloadStateComplete:
            self.progressLabel.text = @"Downloaded";
            break;
        case DownloadStateError:
            self.progressLabel.text = @"Error !";
            break;
        default:
            break;
    }
}

@end
