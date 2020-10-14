//
//  SVGAAudioLayer.m
//  SVGAPlayer
//
//  Created by PonyCui on 2018/10/18.
//  Copyright © 2018年 UED Center. All rights reserved.
//

#import "SVGAAudioLayer.h"
#import "SVGAAudioEntity.h"
#import "SVGAVideoEntity.h"

@interface SVGAAudioLayer ()

@property (nonatomic, readwrite) AVAudioPlayer *audioPlayer;
@property (nonatomic, readwrite) SVGAAudioEntity *audioItem;

@end

@implementation SVGAAudioLayer

#ifdef YM_ENV_VAR_DEBUG
- (void)dealloc {
    [_audioPlayer stop];
    _audioItem = nil;
    _audioPlayer = nil;
    DLog(@"%@ has been dealloced",[self class]);
}
#endif
- (instancetype)initWithAudioItem:(SVGAAudioEntity *)audioItem videoItem:(SVGAVideoEntity *)videoItem
{
    self = [super init];
    if (self) {
        _audioItem = audioItem;
        if (audioItem.audioKey != nil && videoItem.audiosData[audioItem.audioKey] != nil) {
            _audioPlayer = [[AVAudioPlayer alloc] initWithData:videoItem.audiosData[audioItem.audioKey]
                                                  fileTypeHint:@"mp3"
                                                         error:NULL];
            [_audioPlayer prepareToPlay];
        }
    }
    return self;
}

@end
