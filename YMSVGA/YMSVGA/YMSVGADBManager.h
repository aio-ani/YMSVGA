//
//  YMSVGADBManager.h
//  AFNetworking
//
//  Created by aio on 2020/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YMSVGAMdl,YMAudioMdl;
@interface YMSVGADBManager : NSObject

+ (id)dbManager;

- (void)saveSvga:(YMSVGAMdl *)svga complete:(void(^)(BOOL flg))complete;

- (void)getSvga:(NSString *)name complete:(void(^)(YMSVGAMdl *mdl))complete;


- (void)saveAudio:(YMAudioMdl *)audio complete:(void(^)(BOOL flg))complete;

- (void)getAudio:(NSString *)name complete:(void(^)(YMAudioMdl *mdl))complete;


@end

NS_ASSUME_NONNULL_END
