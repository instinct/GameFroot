//
//  SimpleAudioEngine+SimpleAudioEngine_playEffectLoop.m
//  GameFroot
//
//  Created by Sam Win-Mason on 6/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimpleAudioEngine+playEffectLoop.h"

@implementation SimpleAudioEngine (SimpleAudioEngine_playEffectLoop)

-(int) playEffect:(NSString*) file loop:(BOOL) loop {
    int handle = [[SimpleAudioEngine sharedEngine] playEffect:file];
    if (loop) {
        alSourcei(handle, AL_LOOPING, 1);
    }
    return handle;
}

-(void) stopEffectWithHandle:(int)handle {
    [[SimpleAudioEngine sharedEngine] stopEffect:handle];
}

@end
