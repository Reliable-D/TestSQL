//
//  FLFPasteboardHistoryDao.m
//  Fanli
//
//  Created by 邓乐 on 2018/5/2.
//  Copyright © 2018年 www.fanli.com. All rights reserved.
//

#import "FLFPasteboardHistoryDao.h"
#import "FMDB/FMDatabase.h"
#import "FMDB/FMDatabaseAdditions.h"

static NSString* const DatabaseTablePasteboardHistory = @"t_pasteboardhistory";

static NSString* const FLFPasteboardHistoryUnknowUser = @"unknow";

@interface FLFPasteboardHistoryDao ()
{
    dispatch_queue_t    m_queue;
    FMDatabase          *m_db;
}

@end

static FLFPasteboardHistoryDao *sharedPasteboardHistoryDao = nil;

@implementation FLFPasteboardHistoryDao

+ (instancetype)standardDao
{
    @synchronized (self)
    {
        if (nil == sharedPasteboardHistoryDao)
        {
            sharedPasteboardHistoryDao = [[self alloc] init];
        }
    }
    
    return sharedPasteboardHistoryDao;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSString* dir = [[FLFPasteboardHistoryDao filePath] stringByDeletingLastPathComponent];
        if (NO == [[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:NULL])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        m_db = [FMDatabase databaseWithPath:[FLFPasteboardHistoryDao filePath]];
        if (![m_db open])
        {
            NSLog(@"could not open dataBase !");
            return nil;
        }
        else
        {
            [m_db setShouldCacheStatements:NO];
        }
        
        if ([self checkToCreateTable])
        {
            m_queue = dispatch_queue_create("com.51fanli.queue.favoriteInfoDao", DISPATCH_QUEUE_SERIAL);
        }
    }
    
    return self;
}

#pragma mark- public
- (BOOL)isHistoryPasteboard:(NSString*)text withExpiredTimeControl:(NSNumber*)expiredTimeControl uid:(NSString*)uid
{
    __block BOOL isHistory = NO;//默认在不历史列表里
//    CONDITION_CHECK_RETURN_VAULE(text.length > 0, isHistory);
    
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
            //NSString* userId = uid.length > 0 ? uid : FLFPasteboardHistoryUnknowUser;
            NSNumber* expired = expiredTimeControl ?:@(7);
            NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE content = ? AND date('now', '-%zd day') < date(createdTime)", DatabaseTablePasteboardHistory,expired.integerValue];
            FMResultSet *result = [m_db executeQuery:sqlStr];
            if ([result next])
            {
                isHistory = YES;
            }
            [result close];
        }
    });
    
    if (NO == isHistory) {
        [self insertPasteboardToHistoryPasteboard:text uid:uid];
    }
    
    return isHistory;
}

- (void)insertPasteboardToHistoryPasteboard:(NSString*)text uid:(NSString*)uid
{
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
            NSString* userId = uid.length > 0 ? uid : FLFPasteboardHistoryUnknowUser;
            NSDate* time = [NSDate date];//[NSDate dateWithTimeIntervalSince1970:[[FLBGeneralDataCenter defaultDataCenter] getServerTimeStamp]];
            NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@(content, userId, createdTime) VALUES (?,?,?)", DatabaseTablePasteboardHistory];
            [m_db executeUpdate:sqlStr, text, userId, time];
        }
    });
}

- (void)cleanUpExpiredHistoryWithTimeControl:(NSNumber*)expiredTimeControl
{
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
            NSNumber* expired = expiredTimeControl ?:@(7);
            NSString *sqlStr = [NSString stringWithFormat:@"DELETE FROM %@ WHERE WHERE ? >= date(createdTime)", DatabaseTablePasteboardHistory,expired.integerValue];
            [m_db executeUpdate:sqlStr,[NSDate date]];
        }
    });
}

#pragma mark- private
+ (NSString *)fileDirectory
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSLog(@"documentsDirectory:%@",documentsDirectory);
    return [documentsDirectory stringByAppendingPathComponent:@"PasteboardHistory"];
}

+ (NSString *)filePath
{
    NSString *filePath = [[self fileDirectory] stringByAppendingPathComponent:@"db"];
    return filePath;
}

- (BOOL)checkToCreateTable
{
    BOOL result = YES;
    
    if (NO == [m_db tableExists:DatabaseTablePasteboardHistory])
    {
        result = [m_db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, content text, userId text, createdTime datetime)", DatabaseTablePasteboardHistory]];
    }
    
    return result;
}

@end
