//
//  YMSVGADBManager.m
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import "YMSVGADBManager.h"
#import <fmdb/FMDB.h>
#import "YMSVGAMdl.h"
#import "YMFileManager.h"
#import "YMAudioMdl.h"

#define YM_SVGA_CACHE_DIR [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define YM_DB_NAME @"YMSVGADB.db"

@interface YMSVGADBManager ()

@property (strong, nonatomic,readwrite) NSString *dbPath;
//@property (strong, nonatomic,readwrite) FMDatabase *db;

@property (nonatomic, strong) FMDatabaseQueue *queue;



@end

@implementation YMSVGADBManager

- (void)dealloc {
    _dbPath = nil;
    [_queue close];
//    [_db close];
//    _db = nil;
    NSLog(@"%@ has been dealloced",[self class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDBPath];
        [self createDB];
        [self createSvgaTable];
        [self createAudioTable];
    }
    return self;
}

+ (id)dbManager {
    return [[YMSVGADBManager alloc] init];
}


// 懒加载数据库队列
//- (FMDatabaseQueue *)queue {
//    if (_queue == nil) {
//        _queue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
//    }
//
//    return _queue;
//}

- (void)setupDBPath {
    NSString *dbPath = [NSString stringWithFormat:@"%@/%@",YM_SVGA_CACHE_DIR,YM_DB_NAME];
    _dbPath = dbPath;
}

- (void)createDB {
    _queue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
//    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
//    if (!db) {
//        NSLog(@"create db error");
//        return false;
//    }
//    _db = db;
//    return false;
}

//- (BOOL)openDB {
//    if (!_db) {
//        return false;
//    }
//    return [_db open];
//}
//
//- (BOOL)closeDB {
//    if (_db) {
//        return [_db close];
//    }
//    return true;
//}

- (void)createSvgaTable {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"CREATE TABLE IF NOT EXISTS 'YMSVGATABLE' (sv_id integer primary key autoincrement not null,show_url text,save_name)";
        BOOL flg = [db executeUpdate:sql];
        if (!flg) {
            NSLog(@"create SVGA table error");
        }
    }];
//    [self closeDB];
}

- (void)createAudioTable {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {

        NSString *sql = @"CREATE TABLE IF NOT EXISTS 'YMAUDIOTABLE' (sv_id integer primary key autoincrement not null,show_url text,save_name)";
        BOOL flg = [db executeUpdate:sql];
        if (!flg) {
            NSLog(@"create Audio table error");
        }
    }];
//    [self closeDB];
}

- (void)saveSvga:(YMSVGAMdl *)svga complete:(void(^)(BOOL flg))complete {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"REPLACE INTO 'YMSVGATABLE' (show_url,save_name) VALUES(?,?)";
        BOOL result = [db executeUpdate:sql withArgumentsInArray:@[svga.show_url,svga.save_name]];
//        if (result) {
//            return true;
//        }
        if (result) {
            NSLog(@"插入数据成功");
        } else {
            NSLog(@"插入数据失败");
        }
        if (complete) {
            complete(result);
        }
    }];
//    [self closeDB];
//    return false;
}

- (void)getSvga:(NSString *)name complete:(void(^)(YMSVGAMdl *mdl))complete  {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM 'YMSVGATABLE' WHERE save_name = ?";
        FMResultSet *result = [db executeQuery:sql withArgumentsInArray:@[name]];
        YMSVGAMdl *mdl;
        while ([result next]) {
            mdl = [YMSVGAMdl new];
            mdl.sid = [result stringForColumn:@"sv_id"];
            mdl.show_url = [result stringForColumn:@"show_url"];
            mdl.save_name = [result stringForColumn:@"save_name"];
            break;
//            return mdl;
        }
        [result close];
        if (complete) {
            complete(mdl);
        }
    }];
//    [self closeDB];
//    return nil;
}

- (void)saveAudio:(YMAudioMdl *)audio complete:(void(^)(BOOL flg))complete {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"REPLACE INTO 'YMAUDIOTABLE' (show_url,save_name) VALUES(?,?)";
        BOOL result = [db executeUpdate:sql withArgumentsInArray:@[audio.show_url,audio.save_name]];
        if (result) {
            NSLog(@"插入数据成功");
        } else {
            NSLog(@"插入数据失败");
        }
        if (complete) {
            complete(result);
        }
//        if (result) {
//            return true;
//        }
    }];
//    [self closeDB];
//    return false;
}

- (void)getAudio:(NSString *)name complete:(void(^)(YMAudioMdl *mdl))complete {
//    if ([self openDB]) {
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM 'YMAUDIOTABLE' WHERE save_name = ?";
        FMResultSet *result = [db executeQuery:sql withArgumentsInArray:@[name]];
        YMAudioMdl *mdl;
        while ([result next]) {
            mdl = [YMAudioMdl new];
            mdl.sid = [result stringForColumn:@"sv_id"];
            mdl.show_url = [result stringForColumn:@"show_url"];
            mdl.save_name = [result stringForColumn:@"save_name"];
//            return mdl;

        }
        [result close];
        if (complete) {
            complete(mdl);
        }
    }];
//    [self closeDB];
//    return nil;
}



@end
