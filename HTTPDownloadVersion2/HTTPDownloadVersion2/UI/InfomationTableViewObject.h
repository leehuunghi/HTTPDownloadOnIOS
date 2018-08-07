//
//  InfomationTableViewObject.h
//  HTTPDownload
//
//  Created by CPU11367 on 8/1/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "CellObjectModel.h"

@interface InfomationTableViewObject : CellObjectModel

@property (strong, nonatomic, readwrite) NSString *messange;

- (instancetype)initWithMessange:(NSString *)messange;

@end
