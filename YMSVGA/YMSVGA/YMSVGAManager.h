//
//  YMSVGAManager.h
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import <Foundation/Foundation.h>
#import "YMSVGAMdl.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSVGAManager : NSObject

+ (id)manager;

- (void)saveSVGAWith:(id)svga svid:(NSString *)svid url:(NSString *)url name:(NSString *)svgaName complete:(void(^)(BOOL flg))complete;

- (void)getSVGAPath:(NSString *)svgaName complete:(void(^)(NSString *path))complete;

- (void)saveAudio:(id)audio url:(NSString *)url name:(NSString *)name complete:(void(^)(BOOL flg))complete;

- (void)getAudioPath:(NSString *)name complete:(void(^)(NSString *path))complete;


@end

NS_ASSUME_NONNULL_END
