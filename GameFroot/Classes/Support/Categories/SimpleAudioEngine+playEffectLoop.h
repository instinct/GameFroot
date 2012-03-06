//
//  SimpleAudioEngine+SimpleAudioEngine_playEffectLoop.h
//  GameFroot
//
//  Created by Sam Win-Mason on 6/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimpleAudioEngine.h"

@interface SimpleAudioEngine (SimpleAudioEngine_playEffectLoop)
-(int) playEffect:(NSString*) file loop:(BOOL) loop;
-(void) stopEffectWithHandle:(int)handle;
@end
