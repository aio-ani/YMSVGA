//
//  YMFileManager.m
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import "YMFileManager.h"

@implementation YMFileManager

+ (BOOL)writeToFile:(id)data filePath:(NSString *)filePath {
    BOOL flg = [data writeToFile:filePath atomically:YES];//将NSData类型对象data写入文件，文件名为FileName
    return flg;
}

+ (BOOL)createFolderWithFile:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExit = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (!isExit || !isDir) {
        BOOL flg = [fileManager createDirectoryAtPath:filePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
        return flg;
    }
    return false;
}

+ (BOOL)fileExitsAt:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

+ (NSString *)createFileAt:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL flg = [fileManager createFileAtPath:path contents:nil attributes:nil];
    return flg ? path : nil;
}

+ (void)initialFileAt:(NSString *)path {
    if (![self fileExitsAt:path]) {
        [self createFileAt:path];
    }
}



@end
