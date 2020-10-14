//
//  SVGAParser.m
//  SVGAPlayer
//
//  Created by 崔明辉 on 16/6/17.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import "SVGAParser.h"
#import "SVGAVideoEntity.h"
#import "Svga.pbobjc.h"
#import <zlib.h>
#import <SSZipArchive/SSZipArchive.h>
#import <CommonCrypto/CommonDigest.h>

#import "YMSVGAManager.h"


#define YM_MAX_PARSE_COUNT 8

#define ZIP_MAGIC_NUMBER "PK"

@interface SVGAParser ()

@property (strong, nonatomic,readwrite) YMSVGAManager *svgaFileManager;

@property (strong, nonatomic,readwrite) NSOperationQueue *parseQueue;

@property (strong, nonatomic,readwrite) NSOperationQueue *unzipQueue;



@end

@implementation SVGAParser

//static NSOperationQueue *parseQueue;
//static NSOperationQueue *unzipQueue;

#ifdef YM_ENV_VAR_DEBUG

- (void)dealloc {
    _svgaFileManager = nil;
    [_parseQueue cancelAllOperations];
    _parseQueue = nil;
    [_unzipQueue cancelAllOperations];
    _unzipQueue = nil;
    DLog(@"%@ has been dealloced",[self class]);
}
#endif

//+ (void)load {
//    parseQueue = [NSOperationQueue new];
//    parseQueue.maxConcurrentOperationCount = YM_MAX_PARSE_COUNT;
//    unzipQueue = [NSOperationQueue new];
//    unzipQueue.maxConcurrentOperationCount = 1;
//}

- (instancetype)init {
    if (self = [super init]) {
        _svgaFileManager = [YMSVGAManager manager];
//        parseQueue = [NSOperationQueue new];
//        parseQueue.maxConcurrentOperationCount = YM_MAX_PARSE_COUNT;
//        unzipQueue = [NSOperationQueue new];
//        unzipQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (NSOperationQueue *)parseQueue {
    if (!_parseQueue) {
        _parseQueue = [NSOperationQueue new];
        _parseQueue.maxConcurrentOperationCount = YM_MAX_PARSE_COUNT;
    }
    return _parseQueue;
}

- (NSOperationQueue *)unzipQueue {
    if (!_unzipQueue) {
        _unzipQueue = [NSOperationQueue new];
        _unzipQueue.maxConcurrentOperationCount = 1;
    }
    return _unzipQueue;
}

- (void)parseWithURL:(nonnull NSURL *)URL
     completionBlock:(void ( ^ _Nonnull )(SVGAVideoEntity * _Nullable videoItem))completionBlock
        failureBlock:(void ( ^ _Nullable)(NSError * _Nullable error))failureBlock {
    [self parseWithURLRequest:[NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:20.0] audioUrl:nil completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)parseWithURL:(nonnull NSURL *)URL
            audioUrl:(nullable NSURL *)audioUrl
     completionBlock:(void ( ^ _Nonnull )(SVGAVideoEntity * _Nullable videoItem))completionBlock
        failureBlock:(void ( ^ _Nullable)(NSError * _Nullable error))failureBlock {
    [self parseWithURLRequest:[NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:20.0] audioUrl:audioUrl completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)parseWithURLRequest:(NSURLRequest *)URLRequest audioUrl:(nullable NSURL *)audioUrl completionBlock:(void (^)(SVGAVideoEntity * _Nullable))completionBlock failureBlock:(void (^)(NSError * _Nullable))failureBlock {
    if (URLRequest.URL == nil) {
        if (failureBlock) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failureBlock([NSError errorWithDomain:@"SVGAParser" code:411 userInfo:@{NSLocalizedDescriptionKey: @"URL cannot be nil."}]);
            }];
        }
        return;
    }

    NSString *svgaCacheKey = [self cacheKey:URLRequest.URL];
    NSString *audioKey = audioUrl ? [self cacheKey:audioUrl] : nil;
    __weak typeof(self) weakself = self;
    /// 有缓存
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self cacheDirectory:svgaCacheKey]]) {
        [self parseWithCacheKey:svgaCacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
            /// 音频路径
            [weakself.svgaFileManager getAudioPath:audioKey complete:^(NSString * _Nonnull audioPath) {
                videoItem.audioPath = audioPath;
               if (completionBlock) {
                   [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                       completionBlock(videoItem);
                   }];
               }
            }];
//            videoItem.audioPath = audioPath;
//            if (completionBlock) {
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    completionBlock(videoItem);
//                }];
//            }
        } failureBlock:^(NSError * _Nonnull error) {
            [weakself clearCache:[weakself cacheKey:URLRequest.URL]];
            if (failureBlock) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureBlock(error);
                }];
            }
        }];
        
    } else {
        
//        NSString *svgaPath = [self.svgaFileManager getSVGAPath:svgaCacheKey];
        [self.svgaFileManager getSVGAPath:svgaCacheKey complete:^(NSString * _Nonnull svgaPath) {
            /// 本地存在
            if (svgaPath.length) {
                NSData *data = [NSData dataWithContentsOfFile:svgaPath];
                [self parseWithData:data cacheKey:svgaCacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
                    /// 音频路径
                    [weakself.svgaFileManager getAudioPath:audioKey complete:^(NSString * _Nonnull audioPath) {
                        videoItem.audioPath = audioPath;
                        if (completionBlock) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                completionBlock(videoItem);
                            }];
                        }
                    }];
//                    videoItem.audioPath = audioPath;
//                    if (completionBlock) {
//                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            completionBlock(videoItem);
//                        }];
//                    }
                } failureBlock:^(NSError * _Nonnull error) {
                    [weakself clearCache:svgaCacheKey];
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            failureBlock(error);
                        }];
                    }
                }];
            }
            
            /// 下载
            else {
                
                /// 下载音频
                [self downloadAudioWith:audioUrl cacheKey:audioKey];
                /// 下载svga
                [[[NSURLSession sharedSession] dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error == nil && data != nil) {
                        
                        /// 保存svga文件
                        [weakself.svgaFileManager saveSVGAWith:data svid:@"0" url:URLRequest.URL.absoluteString name:svgaCacheKey complete:^(BOOL flg) {
                            if (flg) {
                                NSLog(@"svga 保存成功");
                            } else {
                                NSLog(@"svga 保存失败");
                            }
                        }];
                        
                        [weakself parseWithData:data cacheKey:svgaCacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
                            /// 音频路径
                            [weakself.svgaFileManager getAudioPath:audioKey complete:^(NSString * _Nonnull audioPath) {
                                videoItem.audioPath = audioPath;
                               if (completionBlock) {
                                   [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                       completionBlock(videoItem);
                                   }];
                               }
                            }];
//                            videoItem.audioPath = audioPath;
//                            if (completionBlock) {
//                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                                    completionBlock(videoItem);
//                                }];
//                            }
                        } failureBlock:^(NSError * _Nonnull error) {
                            [weakself clearCache:svgaCacheKey];
                            if (failureBlock) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    failureBlock(error);
                                }];
                            }
                        }];
                    }
                    else {
                        if (failureBlock) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                failureBlock(error);
                            }];
                        }
                    }
                }] resume];
            }


        }];

//        /// 本地存在
//        if (svgaPath.length) {
//            NSData *data = [NSData dataWithContentsOfFile:svgaPath];
//            [self parseWithData:data cacheKey:svgaCacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
//                /// 音频路径
//                NSString *audioPath = [weakself.svgaFileManager getAudioPath:audioKey];
//                videoItem.audioPath = audioPath;
//                if (completionBlock) {
//                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                        completionBlock(videoItem);
//                    }];
//                }
//            } failureBlock:^(NSError * _Nonnull error) {
//                [weakself clearCache:svgaCacheKey];
//                if (failureBlock) {
//                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                        failureBlock(error);
//                    }];
//                }
//            }];
//        }
//
//        /// 下载
//        else {
//
//            /// 下载音频
//            [self downloadAudioWith:audioUrl cacheKey:audioKey];
//            /// 下载svga
//            [[[NSURLSession sharedSession] dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//                if (error == nil && data != nil) {
//
//                    /// 保存svga文件
//                    [weakself.svgaFileManager saveSVGAWith:data svid:@"0" url:URLRequest.URL.absoluteString name:svgaCacheKey];
//
//                    [weakself parseWithData:data cacheKey:svgaCacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
//                        /// 音频路径
//                        NSString *audioPath = [weakself.svgaFileManager getAudioPath:audioKey];
//                        videoItem.audioPath = audioPath;
//                        if (completionBlock) {
//                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                                completionBlock(videoItem);
//                            }];
//                        }
//                    } failureBlock:^(NSError * _Nonnull error) {
//                        [weakself clearCache:svgaCacheKey];
//                        if (failureBlock) {
//                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                                failureBlock(error);
//                            }];
//                        }
//                    }];
//                }
//                else {
//                    if (failureBlock) {
//                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            failureBlock(error);
//                        }];
//                    }
//                }
//            }] resume];
//        }
//
    }
    
}

- (void)downloadAudioWith:(NSURL *)url cacheKey:(NSString *)cacheKey {
    __weak typeof(self) weakself = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            [weakself.svgaFileManager saveAudio:data url:url.absoluteString name:cacheKey complete:^(BOOL flg) {
                if (flg) {
                    NSLog(@"svga 保存成功");
                } else {
                    NSLog(@"svga 保存失败");
                }
            }];
        }

    }] resume];
}

- (void)parseWithNamed:(NSString *)named
              inBundle:(NSBundle *)inBundle
       completionBlock:(void (^)(SVGAVideoEntity * _Nonnull))completionBlock
          failureBlock:(void (^)(NSError * _Nonnull))failureBlock {
    NSString *filePath = [(inBundle ?: [NSBundle mainBundle]) pathForResource:named ofType:@"svga"];
    if (filePath == nil) {
        if (failureBlock) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failureBlock([NSError errorWithDomain:@"SVGAParser" code:404 userInfo:@{NSLocalizedDescriptionKey: @"File not exist."}]);
            }];
        }
        return;
    }
    [self parseWithData:[NSData dataWithContentsOfFile:filePath]
               cacheKey:[self cacheKey:[NSURL fileURLWithPath:filePath]]
        completionBlock:completionBlock
           failureBlock:failureBlock];
}

- (void)parseWithCacheKey:(nonnull NSString *)cacheKey
          completionBlock:(void ( ^ _Nullable)(SVGAVideoEntity * _Nonnull videoItem))completionBlock
             failureBlock:(void ( ^ _Nullable)(NSError * _Nonnull error))failureBlock {
    __weak typeof(self) weakself = self;
    [self.parseQueue addOperationWithBlock:^{
        SVGAVideoEntity *cacheItem = [SVGAVideoEntity readCache:cacheKey];
        if (cacheItem != nil) {
            if (completionBlock) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionBlock(cacheItem);
                }];
            }
            return;
        }
        
        NSString *cacheDir = [weakself cacheDirectory:cacheKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheDir stringByAppendingString:@"/movie.binary"]]) {
            NSError *err;
            NSData *protoData = [NSData dataWithContentsOfFile:[cacheDir stringByAppendingString:@"/movie.binary"]];
            SVGAProtoMovieEntity *protoObject = [SVGAProtoMovieEntity parseFromData:protoData error:&err];
            if (!err && [protoObject isKindOfClass:[SVGAProtoMovieEntity class]]) {
                SVGAVideoEntity *videoItem = [[SVGAVideoEntity alloc] initWithProtoObject:protoObject cacheDir:cacheDir];
                [videoItem resetImagesWithProtoObject:protoObject];
                [videoItem resetSpritesWithProtoObject:protoObject];
                [videoItem resetAudiosWithProtoObject:protoObject];
                if (weakself.enabledMemoryCache) {
                    [videoItem saveCache:cacheKey];
                } else {
                    [videoItem saveWeakCache:cacheKey];
                }
                if (completionBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completionBlock(videoItem);
                    }];
                }
            }
            else {
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failureBlock([NSError errorWithDomain:NSFilePathErrorKey code:-1 userInfo:nil]);
                    }];
                }
            }
        }
        else {
            NSError *err;
            NSData *JSONData = [NSData dataWithContentsOfFile:[cacheDir stringByAppendingString:@"/movie.spec"]];
            if (JSONData != nil) {
                NSDictionary *JSONObject = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:&err];
                if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                    SVGAVideoEntity *videoItem = [[SVGAVideoEntity alloc] initWithJSONObject:JSONObject cacheDir:cacheDir];
                    [videoItem resetImagesWithJSONObject:JSONObject];
                    [videoItem resetSpritesWithJSONObject:JSONObject];
                    if (weakself.enabledMemoryCache) {
                        [videoItem saveCache:cacheKey];
                    } else {
                        [videoItem saveWeakCache:cacheKey];
                    }
                    if (completionBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            completionBlock(videoItem);
                        }];
                    }
                }
            }
            else {
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failureBlock([NSError errorWithDomain:NSFilePathErrorKey code:-1 userInfo:nil]);
                    }];
                }
            }
        }
    }];
}

- (void)clearCache:(nonnull NSString *)cacheKey {
    NSString *cacheDir = [self cacheDirectory:cacheKey];
    [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:NULL];
}

+ (BOOL)isZIPData:(NSData *)data {
    BOOL result = NO;
    if (!strncmp([data bytes], ZIP_MAGIC_NUMBER, strlen(ZIP_MAGIC_NUMBER))) {
        result = YES;
    }
    return result;
}

- (void)parseWithData:(nonnull NSData *)data
             cacheKey:(nonnull NSString *)cacheKey
      completionBlock:(void ( ^ _Nullable)(SVGAVideoEntity * _Nonnull videoItem))completionBlock
         failureBlock:(void ( ^ _Nullable)(NSError * _Nonnull error))failureBlock {
    SVGAVideoEntity *cacheItem = [SVGAVideoEntity readCache:cacheKey];
    if (cacheItem != nil) {
        if (completionBlock) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionBlock(cacheItem);
            }];
        }
        return;
    }
    if (!data || data.length < 4) {
        return;
    }
    
    __weak typeof(self) weakself = self;
    /// 不是zip数据
    if (![SVGAParser isZIPData:data]) {
        // Maybe is SVGA 2.0.0
        [self.parseQueue addOperationWithBlock:^{
            NSData *inflateData = [weakself zlibInflate:data];
            NSError *err;
            SVGAProtoMovieEntity *protoObject = [SVGAProtoMovieEntity parseFromData:inflateData error:&err];
            if (!err && [protoObject isKindOfClass:[SVGAProtoMovieEntity class]]) {
                @autoreleasepool {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        SVGAVideoEntity *videoItem = [[SVGAVideoEntity alloc] initWithProtoObject:protoObject cacheDir:@""];
                        [videoItem resetImagesWithProtoObject:protoObject];
                        [videoItem resetSpritesWithProtoObject:protoObject];
                        [videoItem resetAudiosWithProtoObject:protoObject];
                        if (weakself.enabledMemoryCache) {
                            [videoItem saveCache:cacheKey];
                        } else {
                            [videoItem saveWeakCache:cacheKey];
                        }
                        if (completionBlock) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                completionBlock(videoItem);
                            }];
                        }
                    });
                }
                
            }
        }];
        return ;
    }
    
    /// zip数据需要解包
    [self.unzipQueue addOperationWithBlock:^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:[weakself cacheDirectory:cacheKey]]) {
            [weakself parseWithCacheKey:cacheKey completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
                if (completionBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completionBlock(videoItem);
                    }];
                }
            } failureBlock:^(NSError * _Nonnull error) {
                [weakself clearCache:cacheKey];
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failureBlock(error);
                    }];
                }
            }];
            return;
        }
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingFormat:@"%u.svga", arc4random()];
        if (data != nil) {
            [data writeToFile:tmpPath atomically:YES];
            NSString *cacheDir = [weakself cacheDirectory:cacheKey];
            if ([cacheDir isKindOfClass:[NSString class]]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:nil];
                [SSZipArchive unzipFileAtPath:tmpPath toDestination:[weakself cacheDirectory:cacheKey] progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                    
                } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        if (failureBlock) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                failureBlock(error);
                            }];
                        }
                    }
                    else {
                        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheDir stringByAppendingString:@"/movie.binary"]]) {
                            NSError *err;
                            NSData *protoData = [NSData dataWithContentsOfFile:[cacheDir stringByAppendingString:@"/movie.binary"]];
                            SVGAProtoMovieEntity *protoObject = [SVGAProtoMovieEntity parseFromData:protoData error:&err];
                            if (!err) {
                                @autoreleasepool {
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        SVGAVideoEntity *videoItem = [[SVGAVideoEntity alloc] initWithProtoObject:protoObject cacheDir:cacheDir];
                                        [videoItem resetImagesWithProtoObject:protoObject];
                                        [videoItem resetSpritesWithProtoObject:protoObject];
                                        if (weakself.enabledMemoryCache) {
                                            [videoItem saveCache:cacheKey];
                                        } else {
                                            [videoItem saveWeakCache:cacheKey];
                                        }
                                        if (completionBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                completionBlock(videoItem);
                                            }];
                                        }
                                    });
                                }

                                
                            }
                            else {
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        failureBlock([NSError errorWithDomain:NSFilePathErrorKey code:-1 userInfo:nil]);
                                    }];
                                }
                            }
                        }
                        else {
                            NSError *err;
                            NSData *JSONData = [NSData dataWithContentsOfFile:[cacheDir stringByAppendingString:@"/movie.spec"]];
                            if (JSONData != nil) {
                                NSDictionary *JSONObject = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:&err];
                                if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                                    
                                    @autoreleasepool {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                            SVGAVideoEntity *videoItem = [[SVGAVideoEntity alloc] initWithJSONObject:JSONObject cacheDir:cacheDir];
                                            [videoItem resetImagesWithJSONObject:JSONObject];
                                            [videoItem resetSpritesWithJSONObject:JSONObject];
                                            if (weakself.enabledMemoryCache) {
                                                [videoItem saveCache:cacheKey];
                                            } else {
                                                [videoItem saveWeakCache:cacheKey];
                                            }
                                            if (completionBlock) {
                                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                    completionBlock(videoItem);
                                                }];
                                            }
                                        });
                                    }
                                }
                            }
                            else {
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        failureBlock([NSError errorWithDomain:NSFilePathErrorKey code:-1 userInfo:nil]);
                                    }];
                                }
                            }
                        }
                    }
                }];
            }
            else {
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failureBlock([NSError errorWithDomain:NSFilePathErrorKey code:-1 userInfo:nil]);
                    }];
                }
            }
        }
        else {
            if (failureBlock) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureBlock([NSError errorWithDomain:@"Data Error" code:-1 userInfo:nil]);
                }];
            }
        }
    }];
}

- (nonnull NSString *)cacheKey:(NSURL *)URL {
    return [self MD5String:URL.absoluteString];
}

- (nullable NSString *)cacheDirectory:(NSString *)cacheKey {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [cacheDir stringByAppendingFormat:@"/%@", cacheKey];
}

- (NSString *)MD5String:(NSString *)str {
    const char *cstr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSData *)zlibInflate:(NSData *)data
{
    if ([data length] == 0) return data;
    
    unsigned full_length = (unsigned)[data length];
    unsigned half_length = (unsigned)[data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (unsigned)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit (&strm) != Z_OK) return nil;
    
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

@end
