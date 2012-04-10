//
//  Help.m
//  GameFroot
//
//  Created by Sam Win-Mason on 10/04/12.
//  Copyright (c) 2012 GameFroot All rights reserved.
//

#import "HelpScreen.h"

@implementation HelpScreen

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        // Set up background
        CCSprite *bg = [CCSprite spriteWithFile:@"blue-bg.png"];
        [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
        [self addChild:bg];
        
        // Set up heading text
        CCLabelBMFont *helpTitle = [CCLabelBMFont labelWithString:@"Help" fntFile:@"Chicpix2.fnt"];
        [helpTitle.textureAtlas.texture setAliasTexParameters];
        [helpTitle setPosition:ccp(size.width*0.5,size.height*0.9)];
        [self addChild:helpTitle];
        
        NSString *instructions = @"Here are the instructions for playing a GameFroot game. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse non mauris vel ligula vestibulum laoreet et nec orci. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla pharetra mauris non turpis tristique ornare. Ut fermentum orci in nulla dignissim vehicula. Pellentesque in mi ut mauris tristique mollis. Donec nec nisi felis, malesuada pulvinar quam. Vivamus auctor nunc nulla.";
        
        // Set up help text
        CCLabelTTF *helpText = [CCLabelTTF labelWithString:instructions dimensions:CGSizeMake(size.width-20, size.height-50) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:12];
        [helpText setPosition:ccp(size.width*0.5,size.height*0.3)];
        [self addChild:helpText];
        
        // Set up back button
         CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"back_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"back_pressed.png"] target:self selector:@selector(_back:)];
        CCMenu *helpMenu = [CCMenu menuWithItems:backButton, nil];
        [helpMenu setPosition:ccp(size.width*0.5,size.height*0.1)];
        [self addChild:helpMenu];
    }
    return self;
}

-(void) _back:(id)sender {
    GameMenu *gm = (GameMenu*)self.parent;
    [gm closeHelp];
}





@end
