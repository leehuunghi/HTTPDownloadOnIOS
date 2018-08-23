//
//  WrapperDictionary.h
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/23/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WrapperMutableDictionary : NSObject

- (id)objectForKey:(id)aKey;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (void)removeObjectForKey:(id)aKey;

- (NSArray *)allValues;

@end
