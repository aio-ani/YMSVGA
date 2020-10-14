//
//  YMFileManager.h
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YMFileManager : NSObject

+ (BOOL)writeToFile:(id)data filePath:(NSString *)filePath;

+ (BOOL)createFolderWithFile:(NSString *)filePath;

+ (BOOL)fileExitsAt:(NSString *)path;

+ (NSString *)createFileAt:(NSString *)path;

+ (void)initialFileAt:(NSString *)path;


@end

NS_ASSUME_NONNULL_END
