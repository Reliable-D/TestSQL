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

//static NSString* const FLFPasteboardHistoryUnknowUser = @"NULL";

@interface FLFPasteboardHistoryDao ()
{
    dispatch_queue_t    m_queue;
}

@property (nonatomic, strong) FMDatabase     *db;

@property (nonatomic, strong) NSDateFormatter     *dateFormatter;

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
        NSString* path = [FLFPasteboardHistoryDao filePath];
        NSString* dir = [path stringByDeletingLastPathComponent];
        if (NO == [[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:NULL])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.db = [FMDatabase databaseWithPath:path];
        if (![self.db open])
        {
            NSLog(@"could not open dataBase !");
            return nil;
        }
        else
        {
            [self.db setShouldCacheStatements:NO];
        }
        
        if ([self checkToCreateTable])
        {
            m_queue = dispatch_queue_create("com.51fanli.queue.favoriteInfoDao", DISPATCH_QUEUE_SERIAL);
        }
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat: @"yyyy-MM-dd"];
    }
    
    return self;
}

#pragma mark- public
- (BOOL)isHistoryPasteboard:(NSString*)text withExpiredTimeControl:(NSNumber*)expiredTimeControl uid:(NSString*)uid
{
    __block BOOL isHistory = NO;//默认在不历史列表里
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
            //NSString* userId = uid.length > 0 ? uid : FLFPasteboardHistoryUnknowUser;
            NSNumber* expired = expiredTimeControl ?:@(7);
             NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE content = ? AND julianday('%@') - julianday(createdTime) <= %zd", DatabaseTablePasteboardHistory,[self.dateFormatter stringFromDate:[NSDate date]],expired.integerValue];
            FMResultSet *result = [self.db executeQuery:sqlStr, text];
            if ([result next])
            {
                isHistory = YES;
            }
            [result close];
        }
    });
    
    return isHistory;
}

- (void)insertPasteboardToHistoryPasteboard:(NSString*)text uid:(NSString*)uid time:(NSString*)time
{
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
//            NSString* userId = uid.length > 0 ? uid : FLFPasteboardHistoryUnknowUser;
            //[NSDate dateWithTimeIntervalSince1970:[[FLBGeneralDataCenter defaultDataCenter] getServerTimeStamp]];
            NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@(content, userId, createdTime) VALUES (?,?,?)", DatabaseTablePasteboardHistory];
            [self.db executeUpdate:sqlStr, text, uid.length>0?uid:[NSNull null], time];
        }
    });
}

- (void)cleanUpExpiredHistoryWithTimeControl:(NSNumber*)expiredTimeControl
{
    dispatch_sync(m_queue, ^{
        @autoreleasepool
        {
            NSNumber* expired = expiredTimeControl ?:@(7);
            NSString *sqlStr = [NSString stringWithFormat:@"DELETE FROM %@ WHERE julianday('%@') - julianday(createdTime) > %zd", DatabaseTablePasteboardHistory, [self.dateFormatter stringFromDate:[NSDate date]],expired.integerValue];
            [self.db executeUpdate:sqlStr];
        }
    });
}

#pragma mark- private
+ (NSString *)fileDirectory
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    return [documentsDirectory stringByAppendingPathComponent:@"PasteboardHistory"];
}

+ (NSString *)filePath
{
    NSString *filePath = [[self fileDirectory] stringByAppendingPathComponent:@"PasteboardHistory.db"];
    NSLog(@"filePath:%@",filePath);
    return filePath;
}

- (BOOL)checkToCreateTable
{
    BOOL result = YES;
    
    if (NO == [self.db tableExists:DatabaseTablePasteboardHistory])
    {
        result = [self.db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, content text, userId text, createdTime datetime)", DatabaseTablePasteboardHistory]];
    }
    
    return result;
}

@end
