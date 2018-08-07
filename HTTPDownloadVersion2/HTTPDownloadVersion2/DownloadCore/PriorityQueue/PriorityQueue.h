//
//  PriorityQueue.h
//  HTTPDownload
//
//  Created by CPU11360 on 8/2/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    High,
    Medium,
    Low,
} Priority;

@interface PriorityQueue : NSObject

- (void)addObject:(id)object withPriority:(Priority)priority;

- (id)getObjectFromQueue;

- (void)removeObject;

- (NSInteger)count;

- (void)setPriorityForObject:(id)object withPriority:(int)priority;

//- (bool)isContainObject:(id)object;

@end
