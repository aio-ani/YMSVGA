//
//  SVGAVideoSpriteEntity.m
//  SVGAPlayer
//
//  Created by 崔明辉 on 2017/2/20.
//  Copyright © 2017年 UED Center. All rights reserved.
//

#import "SVGAVideoSpriteEntity.h"
#import "SVGAVideoSpriteFrameEntity.h"
#import "SVGABitmapLayer.h"
#import "SVGAContentLayer.h"
#import "SVGAVectorLayer.h"
#import "Svga.pbobjc.h"
#import "UIImage+YMImage.h"

@implementation SVGAVideoSpriteEntity

#ifdef YM_ENV_VAR_DEBUG

- (void)dealloc {
    _imageKey = nil;
    _matteKey = nil;
    _frames = nil;
    DLog(@"%@ has been dealloced",[self class]);
}
#endif

- (instancetype)initWithJSONObject:(NSDictionary *)JSONObject {
    self = [super init];
    if (self) {
        if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSString *imageKey = JSONObject[@"imageKey"];
            NSString *matteKey = JSONObject[@"matteKey"];
            NSArray<NSDictionary *> *JSONFrames = JSONObject[@"frames"];
            if ([imageKey isKindOfClass:[NSString class]] && [JSONFrames isKindOfClass:[NSArray class]]) {
                NSMutableArray<SVGAVideoSpriteFrameEntity *> *frames = [[NSMutableArray alloc] init];
                [JSONFrames enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [frames addObject:[[SVGAVideoSpriteFrameEntity alloc] initWithJSONObject:obj]];
                    }
                }];
                _imageKey = imageKey;
                _frames = frames;
                _matteKey = matteKey;
            }
        }
    }
    return self;
}

- (instancetype)initWithProtoObject:(SVGAProtoSpriteEntity *)protoObject {
    self = [super init];
    if (self) {
        if ([protoObject isKindOfClass:[SVGAProtoSpriteEntity class]]) {
            NSString *imageKey = protoObject.imageKey;
            NSString *matteKey = protoObject.matteKey;
            NSArray<NSDictionary *> *protoFrames = [protoObject.framesArray copy];
            if ([imageKey isKindOfClass:[NSString class]] && [protoFrames isKindOfClass:[NSArray class]]) {
                NSMutableArray<SVGAVideoSpriteFrameEntity *> *frames = [[NSMutableArray alloc] init];
                [protoFrames enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[SVGAProtoFrameEntity class]]) {
                        [frames addObject:[[SVGAVideoSpriteFrameEntity alloc] initWithProtoObject:obj]];
                    }
                }];
                _imageKey = imageKey;
                _frames = frames;
                _matteKey = matteKey;
            }
        }
    }
    return self;
}

- (SVGAContentLayer *)requestLayerWithBitmap:(UIImage *)bitmap {
    SVGAContentLayer *layer = [[SVGAContentLayer alloc] initWithFrames:self.frames];
    if (bitmap != nil) {
//        UIImage *dimage = [self getDealedImage:bitmap];
        layer.bitmapLayer = [[SVGABitmapLayer alloc] initWithFrames:self.frames];
//        layer.bitmapLayer.contents = (__bridge id _Nullable)([dimage CGImage]);
        layer.bitmapLayer.contents = (__bridge id _Nullable)([bitmap CGImage]);
    }
    layer.vectorLayer = [[SVGAVectorLayer alloc] initWithFrames:self.frames];
    return layer;
}

//- (UIImage *)getDealedImage:(UIImage *)image {
//    CGSize oriSize = image.size;
//
//    CGFloat imageWidth = oriSize.width;
//    CGFloat imageHeight = oriSize.height;
//
//
//    CGFloat winWidth = [UIScreen.mainScreen bounds].size.width;
//    CGFloat winHeight = [UIScreen.mainScreen bounds].size.height;
//
//    CGFloat width,height;
//    if (imageWidth > winWidth) {
//        width = winWidth;
//        height = width/winWidth * winHeight;
//    } else if (imageHeight > winHeight) {
//        height = winHeight;
//        width = winWidth/winHeight * imageHeight;
//    }
//
//
//
//
//    CGFloat width = MIN(winWidth, oriSize.width);
//    CGFloat height = MIN(winHeight,oriSize.height);
//    if (oriSize.height > winHeight) {
//        height = oriSize.height * winWidth / oriSize.width;
//    }
////    else {
////        height = oriSize.height;
////    }
//    CGSize dealSize = CGSizeMake(width, height);
//    UIImage *dimage = [image ym_animatedImageByScalingAndCroppingToSize:dealSize];
//    return dimage;
//}

@end
