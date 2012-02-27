//
//  Dialogue.m
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Dialogue.h"
#import "GameLayer.h"
#import "CCLabelBMFontMultiline.h"
#import <CoreText/CoreText.h>

#define TOUCH_PRIORITY		-10000

@implementation Dialogue

+(NSArray *) findPageSplits:(NSString*)string size:(CGSize)size font:(UIFont*)font
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:32];
    CTFontRef fnt = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize,NULL);
    CFAttributedStringRef str = CFAttributedStringCreate(kCFAllocatorDefault, 
                                                         (CFStringRef)string, 
                                                         (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(id)fnt,kCTFontAttributeName,nil]);
    CTFramesetterRef fs = CTFramesetterCreateWithAttributedString(str);
    CFRange r = {0,0};
    CFRange res = {0,0};
    NSInteger str_len = [string length];
    do {
        CTFramesetterSuggestFrameSizeWithConstraints(fs,r, NULL, size, &res);
        r.location += res.length;
        
        NSString *pageString = [string substringWithRange:NSMakeRange(res.location, res.length)];
        NSString *trimmedString = [pageString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [result addObject:trimmedString];
        
    } while(r.location < str_len);
    CFRelease(fs);
    CFRelease(str);
    CFRelease(fnt);
    return result;
} 

-(void) setupDialogue:(NSString *)_text
{
    //CCLOG(@"Dialogue.setupDialogue: %@", _text);
    
    background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
    
    UIFont *font = [UIFont fontWithName:@"Arial" size:18.0f];
    pages = [Dialogue findPageSplits:_text size:CGSizeMake(background.contentSize.width - 10, background.contentSize.height - 10) font:font];    
    [pages retain];
    numPages = [pages count];
    selectPage = 0;
	
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];
	
	label = [CCLabelBMFontMultiline labelWithString:[pages objectAtIndex:0] fntFile:@"Chicago.fnt" width:background.contentSize.width - 20 alignment:LeftAlignment];
	[label.textureAtlas.texture setAliasTexParameters];
    
    [label setAnchorPoint:ccp(0,1)];
    [label setPosition: ccp(20, background.contentSize.height + 5)];
    
    [self addChild:background z:1];
	[self addChild:label z:2];
	
	[[GameLayer getInstance] addOverlay:self];
	
	[[CCDirector sharedDirector] pause];
	//[[CCDirector sharedDirector] stopAnimation];
	[[GameLayer getInstance] stopPlayer];
	[[GameLayer getInstance] pause];
	[[GameLayer getInstance] resetControls];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (selectPage < numPages - 1) {
        // Display next page
        selectPage++;
        [label setString:[pages objectAtIndex:selectPage]];
        
        return YES;
        
    } else {
        [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
        
        [[CCDirector sharedDirector] resume];
        //[[CCDirector sharedDirector] startAnimation];
        [[GameLayer getInstance] resume];
        
        [[GameLayer getInstance] removeOverlay:self];
        
        return YES;
    }
}

- (void)dealloc
{
    [pages release];
    [super dealloc];
}

@end
