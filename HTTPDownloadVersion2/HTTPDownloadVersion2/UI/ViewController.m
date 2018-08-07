//
//  ViewController.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/30/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "ViewController.h"
#import "DownloadCellObject.h"

@interface ViewController ()

@property (nonatomic) NSArray* staticArr;
@property (nonatomic) int count;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Download";
    self.staticArr = @[
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
    [self loadCore];
    [self loadData];
    [self loadUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadCore {
//    _downloadManager = [DownloadManager new];
}

- (void)loadData {
    NSMutableArray *historyDownload = [NSMutableArray new];
    _downloadTableView.cellObjects = historyDownload;
}

- (void)loadUI {
    
}

- (IBAction)downloadButtonTouchUpInside:(id)sender {
    NSString *url = _urlInputTextField.text;
    _urlInputTextField.text = self.staticArr[_count++];
    if(_count >= [self.staticArr count]) _count = 0;
    //    _urlInputTextField.text = @"";
    if (url.length > 0) {
        DownloadCellObject *cellObject = [DownloadCellObject new];
        cellObject.title = [ViewController getNameInURL:url];
        cellObject.progressString = @"Pending...";
        [_downloadTableView addCell:cellObject];
        __weak typeof(self) weakSelf = self;
//        [_downloadManager checkURL:url completion:^(NSError *error) {
//            if(error) {
//                cellObject.state = DownloadStateError;
//            } else {
//                [weakSelf.downloadManager createDownloadWithURLString:url completion:^(DownloadObjectModel *downloadObject, NSError *error) {
//                    [downloadObject addUpdateBlock:^(NSNumber * totalWrite, NSNumber * totalExpected) {
//                        [cellObject progressDidUpdate:[totalWrite intValue] total:[totalExpected intValue]];
//                    }];
//                    [downloadObject addCompletionBlock:^(NSURL *fileURL) {
//                        [cellObject downloadFinish:fileURL.absoluteString];
//                    }];
//
//                    cellObject.downloadManager = downloadObject;
//                    [downloadObject resume];
//                }];
//            }
//        }];
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


@end
