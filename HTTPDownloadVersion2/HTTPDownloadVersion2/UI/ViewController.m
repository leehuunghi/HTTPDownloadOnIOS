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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadCore {
    _downloader = [Downloader new];
    [DownloaderSingleton shareIntance].downloader = _downloader;
}

- (void)loadData {
    
    NSArray *historyDownload = [_downloader loadData];
    for (NSString *identifier in historyDownload) {
        DownloadCellObject *cellObject = [DownloadCellObject new];
        cellObject.identifier = identifier;
        cellObject.title = [_downloader getFileNameWithIdentifier:identifier];
        [_downloader setDelegate:cellObject forIdentifier:identifier];
        [_downloadTableView addCell:cellObject];
    }
    
    self.staticArr = @[
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"http://grail.cba.csuohio.edu/~matos/notes/ist-211/2015-fall/classroster_IST_211_1.xlsx",
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
                       @"http://www.noiseaddicts.com/samples_1w72b820/274.mp3",
                       @"http://www.vietnamvisaonentry.com/file/2014/06/coconut-tree.jpg",
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

- (IBAction)downloadButtonTouchUpInside:(id)sender {
    NSString *url = _urlInputTextField.text;
    _urlInputTextField.text = self.staticArr[_count++];
    if(_count >= [self.staticArr count]) _count = 0;
    //    _urlInputTextField.text = @"";
    if (url.length > 0) {
        DownloadPriority priority = _prioritySegmented.selectedSegmentIndex;
        DownloadCellObject *cellObject = [DownloadCellObject new];
        cellObject.priority = priority;
        cellObject.title = [url lastPathComponent];
        [_downloader createDownloadItemWithUrl:url priority:priority delegate:cellObject completion:^(NSString *identifier, NSError *error) {
            cellObject.identifier = identifier;
            if (error) {
                
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
    [_downloader saveData:^{
        exit(0);
    }];
}

@end
