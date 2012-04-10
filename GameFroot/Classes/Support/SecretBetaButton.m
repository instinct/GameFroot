//
//  SecretBetaButton.m
//  GameFroot
//
//  Created by Sam Win-Mason on 10/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SecretBetaButton.h"

@implementation SecretBetaButton


-(void) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    CCLOG(@"secret: touch began");
}
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    CCLOG(@"secret: touch ended");
}
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    CCLOG(@"secret: touch moved");
}
-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    CCLOG(@"secret: touch cancelled");
}


@end
