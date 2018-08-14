//
//  ViewController.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/30/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "ViewController.h"
#import "DownloadCellObject.h"
#import "Downloader.h"

@interface ViewController ()

@property (nonatomic, strong) DownloaderModel *downloader;

@property (nonatomic) NSArray *staticArr;

@property (nonatomic) int count;

@property (weak, nonatomic) IBOutlet UISegmentedControl *prioritySegmented;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Download";
    
    [self loadCore];
    [self loadData];
    [self loadUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadCore {
    _downloader = [Downloader new];
    
}

- (void)loadData {
    NSArray *historyDownload = [_downloader loadData];
    NSMutableArray *cellObjects = [NSMutableArray new];
    for (DownloadItemModel *item in historyDownload) {
        DownloadCellObject *cellObject = [[DownloadCellObject alloc] initWithDownloadItem:item];
        [cellObjects insertObject:cellObject atIndex:0];
        item.delegate = cellObject;
    }
    _downloadTableView.cellObjects = cellObjects;
    
    self.staticArr = @[
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"http://grail.cba.csuohio.edu/~matos/notes/ist-211/2015-fall/classroster_IST_211_1.xlsx",
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"http://www.noiseaddicts.com/samples_1w72b820/274.mp3",
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"pornhub.com",
                       @"xvideos.com",
                       @"xnxx.com",
                       @"http://ipv4.download.thinkbroadband.com/200MB.zip",
                       @"http://ipv4.download.thinkbroadband.com/50MB.zip",
                       @"http://ipv4.download.thinkbroadband.com/512MB.zip",
                       @"https://speed.hetzner.de/100MB.bin",
                       @"https://speed.hetzner.de/1GB.bin",
                       @"http://ipv4.download.thinkbroadband.com/20MB.zip",
                       @"http://ipv4.download.thinkbroadband.com/10MB.zip",
                       @"https://speed.hetzner.de/10GB.bin"
                       ];
    _count = 0;
    
}

- (void)loadUI {
    
}

- (IBAction)downloadButtonTouchUpInside:(id)sender {
    NSString *url = _urlInputTextField.text;
    _urlInputTextField.text = self.staticArr[_count++];
    if(_count >= [self.staticArr count]) _count = 0;
    //    _urlInputTextField.text = @"";
    if (url.length > 0) {
        __weak __typeof(self) weakSelf = self;
        DownloadPriority priority = _prioritySegmented.selectedSegmentIndex;
        [_downloader createDownloadItemWithUrl:url priority:priority completion:^(DownloadItemModel *downloadItem, NSError *error) {
            if (downloadItem && downloadItem.delegate && [downloadItem.delegate isKindOfClass:[CellObjectModel class]]) {
                CellObjectModel *cellObject = downloadItem.delegate;
                [weakSelf.downloadTableView moveCellToHead:cellObject];
            } else {
                DownloadCellObject *cellObject = [DownloadCellObject new];
                cellObject.priority = priority;
                cellObject.title = [ViewController getNameInURL:url];
                [weakSelf.downloadTableView addCell:cellObject];
                if (error) {
                    cellObject.state = DownloadStateError;
                } else {
                    cellObject.downloadItem = downloadItem;
                    downloadItem.delegate = cellObject;
                }
            }
        }];
    }
}

+ (NSString *)getNameInURL:(NSString *)url {
    int startPoint = 0;
    for (int i = 1; i < [url length]; ++i) {
        if ([url characterAtIndex:i] == '/') {
            startPoint = i + 1;
        }
    }
    return [url substringFromIndex:startPoint];
}

- (IBAction)quitItemTouch:(id)sender {
    [_downloader saveData];
    [_downloader saveResumeData:^{
        exit(0);
    }];
}

@end
