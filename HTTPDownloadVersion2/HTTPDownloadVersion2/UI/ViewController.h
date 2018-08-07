//
//  ViewController.h
//  HTTPDownload
//
//  Created by CPU11367 on 7/30/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadTableView.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet DownloadTableView *downloadTableView;

@property (weak, nonatomic) IBOutlet UITextField *urlInputTextField;

@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

