//
//  InformationTableViewCell.m
//  HTTPDownload
//
//  Created by CPU11367 on 8/1/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "InformationTableViewCell.h"
#import "InfomationTableViewObject.h"

@implementation InformationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (TableViewCellModel *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCellModel *cell = [tableView dequeueReusableCellWithIdentifier:@"InformationTableViewCell"];
    return cell;
}

- (BOOL)shouldUpdateWithObject:(id)anObject {
    if (![anObject isKindOfClass:[InfomationTableViewObject class]]) {
        return false;
    }
    InfomationTableViewObject *object = anObject;
    _messange.text = object.messange;
    return true;
}

@end
