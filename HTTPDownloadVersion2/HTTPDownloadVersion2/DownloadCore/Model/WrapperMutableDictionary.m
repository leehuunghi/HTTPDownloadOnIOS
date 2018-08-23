//
//  WrapperDictionary.m
//  HTTPDownloadVersion2
//
//  Created by CPU11360 on 8/23/18.
//  Copyright © 2018 CPU11360. All rights reserved.
//

#import "WrapperMutableDictionary.h"

@interface WrapperMutableDictionary()

@property (nonatomic) dispatch_queue_t concurrentQueue;

@property (nonatomic) NSMutableDictionary *dictionary;

@end

@implementation WrapperMutableDictionary

- (instancetype)init
{
    self = [super init];
    if (self) {
        _concurrentQueue = dispatch_queue_create("concurrent_queue_wrapper_dictionary", DISPATCH_QUEUE_CONCURRENT);
        _dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)objectForKey:(id)aKey {
    __block id object;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_concurrentQueue, ^{
        object = [weakSelf.dictionary objectForKey:aKey];
    });
    return object;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_concurrentQueue, ^{
        [weakSelf.dictionary setObject:anObject forKey:aKey];
    });
}

- (void)removeObjectForKey:(id)aKey {
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_concurrentQueue, ^{
        [weakSelf.dictionary removeObjectForKey:aKey];
    });
}

- (NSArray *)allValues {
    __block NSArray *array;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_concurrentQueue, ^{
        array = [weakSelf allValues];
    });
    return array;
};

@end
