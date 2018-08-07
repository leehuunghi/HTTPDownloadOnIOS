//
//  InfomationTableViewObject.m
//  HTTPDownload
//
//  Created by CPU11367 on 8/1/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "InfomationTableViewObject.h"
#import "InformationTableViewCell.h"

@implementation InfomationTableViewObject

- (Class)cellClass {
    return [InformationTableViewCell class];
}

- (instancetype)initWithMessange:(NSString *)messange {
    self = [super init];
    if (self) {
        _messange = messange;
    }
    return self;
}

- (NSUInteger)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height;
}

@end
