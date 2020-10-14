//
//  YMSVGAManager.m
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import "YMSVGAManager.h"
#import "YMSVGADBManager.h"
#import "YMSVGAMdl.h"
#import "YMFileManager.h"
#import "YMAudioMdl.h"


#define YM_SVGA_CACHE_DOC_DIR [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define YM_SVGA_CACHE_PATH @"SVGA_PATH"
#define YM_SVGA_CACHE_EXTENSION @"svga"
#define YM_AUDIO_CACHE_EXTENSION @"mp3"


@interface YMSVGAManager ()

@property (strong, nonatomic,readwrite) NSString *mainPath;
@property (strong, nonatomic,readwrite) YMSVGADBManager *dbManager;


@end


@implementation YMSVGAManager

- (void)dealloc {
    _mainPath = nil;
    _dbManager = nil;
    NSLog(@"%@ has been dealloced",[self class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self createSVGADIR];
    }
    return self;
}

- (void)createSVGADIR {
    NSString *path = [YM_SVGA_CACHE_DOC_DIR stringByAppendingPathComponent:YM_SVGA_CACHE_PATH];
    _mainPath = path;
    [YMFileManager createFolderWithFile:path];
}

- (YMSVGADBManager *)dbManager {
    if (!_dbManager) {
        _dbManager = [YMSVGADBManager dbManager];
    }
    return _dbManager;
}

+ (id)manager {
    return [[YMSVGAManager alloc] init];
}

- (NSString *)svgaPathForName:(NSString *)svgaName {
    if (!svgaName.length) {
        return nil;
    }
    NSString *filePath = [_mainPath stringByAppendingPathComponent:svgaName];
    filePath = [filePath stringByAppendingPathExtension:YM_SVGA_CACHE_EXTENSION];
    return filePath;
}

- (NSString *)audioPathForName:(NSString *)audioName {
    NSString *filePath = [_mainPath stringByAppendingPathComponent:audioName];
    filePath = [filePath stringByAppendingPathExtension:YM_AUDIO_CACHE_EXTENSION];
    return filePath;
}

- (void)saveSVGAWith:(id)svga svid:(NSString *)svid url:(NSString *)url name:(NSString *)svgaName complete:(void(^)(BOOL flg))complete {
    if (svga && svgaName) {
        NSString *filePath = [self svgaPathForName:svgaName];
        if (![YMFileManager fileExitsAt:filePath]) {
            BOOL flg = [YMFileManager createFileAt:filePath];
            if (flg) {
                flg = [YMFileManager writeToFile:svga filePath:filePath];
                if (flg) {
                    YMSVGAMdl *svga = [YMSVGAMdl new];
                    svga.save_name = svgaName;
                    svga.show_url = url;
                    svga.sid = svid;
                    [self.dbManager saveSvga:svga complete:complete];//^(BOOL flg) {
    //                    if (!flg) {
    //                        NSLog(@"svga 保存数据库失败");
    //                        return false;
    //                    }
    //                }];
                    
                }
            }
        } else {
            if (complete) {
                complete(true);
            }
        }
    }
//    return false;
}


- (void)getSVGAPath:(NSString *)svgaName complete:(void(^)(NSString *path))complete {
    if (!svgaName.length) {
        return;
    }
    [self.dbManager getSvga:svgaName complete:^(YMSVGAMdl * _Nonnull mdl) {
        if (complete) {
            NSString *path = [self svgaPathForName:mdl.save_name];
            complete(path);
        }
    }];
//    if (svga) {
//        NSString *path = [self svgaPathForName:svgaName];
//        return path;
//    }
//    return nil;
}

/// 音频
- (void)saveAudio:(id)audio url:(NSString *)url name:(NSString *)name complete:(void(^)(BOOL flg))complete {
    if (url && name) {
        NSString *filePath = [self audioPathForName:name];
        if (![YMFileManager fileExitsAt:filePath]) {
            BOOL flg = [YMFileManager createFileAt:filePath];
            if (flg) {
                flg = [YMFileManager writeToFile:audio filePath:filePath];
                if (flg) {
                    YMAudioMdl *audio = [YMAudioMdl new];
                    audio.save_name = name;
                    audio.show_url = url;
                    [self.dbManager saveAudio:audio complete:complete];
    //                if (!flg) {
    //                    NSLog(@"audio 保存数据库失败");
    //                    return false;
    //                }
                }
            }
        } else {
            if (complete) {
                complete(true);
            }
        }
        
    }
//    return false;
}

- (void)getAudioPath:(NSString *)name complete:(void(^)(NSString *path))complete {
    if (!name.length) {
        complete(nil);
        return;
    }
    [self.dbManager getAudio:name complete:^(YMAudioMdl * _Nonnull mdl) {
        if (complete) {
            NSString *path = [self audioPathForName:mdl.save_name];
            complete(path);
        }
    }];
//    if (audio) {
//        NSString *path = [self audioPathForName:name];
//        return path;
//    }
//    return nil;
}




@end





