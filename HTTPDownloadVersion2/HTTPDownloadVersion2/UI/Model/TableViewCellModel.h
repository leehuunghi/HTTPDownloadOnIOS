//
//  TableViewCellModel.h
//  HTTPDownload
//
//  Created by CPU11367 on 8/1/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCellModel : UITableViewCell

+ (__kindof TableViewCellModel *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldUpdateWithObject:(nonnull id)anObject;

@end
