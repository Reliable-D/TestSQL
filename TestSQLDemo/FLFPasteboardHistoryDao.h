//
//  FLFPasteboardHistoryDao.h
//  TestSQLDemo
//
//  Created by 邓乐 on 2018/5/2.
//  Copyright © 2018年 fanli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLFPasteboardHistoryDao : NSObject

+ (instancetype)standardDao;

- (BOOL)isHistoryPasteboard:(NSString*)text withExpiredTimeControl:(NSNumber*)expiredTimeControl uid:(NSString*)uid;

- (void)insertPasteboardToHistoryPasteboard:(NSString*)text uid:(NSString*)uid time:(NSString*)time;

- (void)cleanUpExpiredHistoryWithTimeControl:(NSNumber*)expiredTimeControl;

@end
