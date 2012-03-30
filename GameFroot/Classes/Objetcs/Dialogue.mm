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

#define TOUCH_PRIORITY		-10000
#define FONT_NAME           @"ArialMT"
#define FONT_SIZE           17
#define LINE_SPACE          4
#define LINES_PER_PAGE      5
#define MAX_TEXT_HEIGHT     2048

@implementation Dialogue

-(CGSize) calculateLabelSize:(NSString *)string withFont:(UIFont *)font maxSize:(CGSize)maxSize
{
    return [string
            sizeWithFont:font
            constrainedToSize:maxSize
            lineBreakMode:UILineBreakModeWordWrap];
    
}

-(void) setupDialogue:(NSString *)_text
{
    text = [_text retain];
    
    background = [CCSprite spriteWithFile:@"dialogue_background.png"];
    [background setOpacity:200];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
    
    arrow = [CCSprite spriteWithFile:@"arrow.png"];
    [background addChild:arrow];
    [arrow setPosition:ccp(background.contentSize.width - arrow.contentSize.width, arrow.contentSize.height)];
    
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];
	
    [self prepareText];
    
    fontReference = [[UIFont fontWithName:FONT_NAME size:FONT_SIZE] retain];
    
    CGSize sizeText = [self calculateLabelSize:text withFont:fontReference maxSize:CGSizeMake(background.contentSize.width - 30, MAX_TEXT_HEIGHT)];
    //CCLOG(@"text size: %f,%f", sizeText.width, sizeText.height);       
    
    numPages = (int)((sizeText.height / (FONT_SIZE + LINE_SPACE)) / LINES_PER_PAGE);
    float exact = (sizeText.height / (float)(FONT_SIZE + LINE_SPACE)) / (float)LINES_PER_PAGE;
    if (exact > (float)numPages) numPages++;
    
	//label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Sans.fnt" width:background.contentSize.width - 30 alignment:LeftAlignment page:0 linesPerPage:5];
	//[label.textureAtlas.texture setAliasTexParameters];
    label = [CCLabelTTF labelWithString:@"" dimensions:sizeText alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeWordWrap fontName:FONT_NAME fontSize:FONT_SIZE];
    
    [label setAnchorPoint:ccp(0,1)];
    [label setPosition: ccp(25, background.contentSize.height + 8)];
    
    selectPage = 0;
    if (numPages == 1) arrow.visible = NO;
    
    ////label.contentSize.height / background.contentSize.height;
    ////float exact = label.contentSize.height / background.contentSize.height;
    ////if (exact > (float)numPages) numPages++;
    
    //numPages = label.pages; 
    
    //CCLOG(@"Dialogue.setupDialogue: %@, pages: %i", text, numPages);
    
    [self addChild:background z:1];
	[self addChild:label z:2];
	
	[[GameLayer getInstance] addOverlay:self];
    [[SimpleAudioEngine sharedEngine] playEffect:@"IG Story point.caf"];
    
    if (![[GameLayer getInstance] isPaused]) {
        //[[CCDirector sharedDirector] pause];
        //[[CCDirector sharedDirector] stopAnimation];
        [[GameLayer getInstance] stopPlayer];
        [[GameLayer getInstance] pause];
        [[GameLayer getInstance] resetControls];
    }
    
    [self animate];
}

-(void) animate 
{
    animating = YES;
    
    // Find previous speed
    CCArray *values; CCARRAY_FOREACH(speechSpeeds, values) {
        NSRange range = [[values objectAtIndex:0] rangeValue];
        if (range.location < currentCharacter) {
            NSString *command = [values objectAtIndex:1];
            if ([command isEqualToString:@"{slow}"]) speed = 150;
            else if ([command isEqualToString:@"{fast}"]) speed = 20;
            else if ([command isEqualToString:@"{talk}"]) speed = 50;
            
            //CCLOG(@"Found previous speed %f", speed);
        }
    }
    
    [self unschedule:@selector(animateCharacter:)];
    //CCLOG(@"Animate with speed %f", speed);
    [self schedule:@selector(animateCharacter:) interval:speed / 1000.0f];
}

- (void) stepBackAnimation 
{   
    if (currentCharacter == 0) return;
    
    int i;
    NSRange range;
    
    for (i=currentCharacter; i >= 0; i--) {
        range = NSMakeRange(i, 1);
        NSString *character = [text substringWithRange:range];
        //CCLOG(@"step back char: %@", character);
        
        if ([character isEqualToString:@" "]) {            
            break;
        }
    }
    
    currentCharacter = i;
    
    range = NSMakeRange(0, currentCharacter);
    NSString *display = [text substringWithRange:range];
    [label setString:display];
}

-(void) animateCharacter:(ccTime) dt
{
    if (animating) {
        
        CCArray *values; CCARRAY_FOREACH(speechSpeeds, values) {
            NSRange range = [[values objectAtIndex:0] rangeValue];
            BOOL used = [[values objectAtIndex:2] boolValue];
            if (!used && range.location == currentCharacter) {
                NSString *command = [values objectAtIndex:1];
                
                [values removeObjectAtIndex:2];
                [values insertObject:[NSNumber numberWithBool:YES] atIndex:2];
                
                float previousSpeed = speed;
                if ([command isEqualToString:@"{slow}"]) speed = 150;
                else if ([command isEqualToString:@"{fast}"]) speed = 20;
                else if ([command isEqualToString:@"{talk}"]) speed = 50;
                else if ([command isEqualToString:@"{pause}"]) {
                    speed = 1100.0f;
                    //CCLOG(@"Found command %@ on index %i with speed %f", command, range.location, speed);
                    [self unschedule:@selector(animateCharacter:)];
                    [self schedule:@selector(animateCharacter:) interval:speed / 1000.0f];
                    return;
                }
                
                //CCLOG(@"Found command %@ on index %i with speed %f", command, range.location, speed);
                
                if (previousSpeed != speed) {
                    [self unschedule:@selector(animateCharacter:)];
                    [self schedule:@selector(animateCharacter:) interval:speed / 1000.0f];
                }
                
                break;
            }
        }
        
        //CCLOG(@"Animate characters from %i to %i", 0, currentCharacter);
        
        if (currentCharacter < numCharacters - 1) {
            
            currentCharacter++;
            
            NSRange range = NSMakeRange(0, currentCharacter);
            NSString *display = [text substringWithRange:range];
            [label setString:display];
            
            
            CGSize sizeText = [self calculateLabelSize:display withFont:fontReference maxSize:CGSizeMake(background.contentSize.width - 30, MAX_TEXT_HEIGHT)];
            
            if (sizeText.height > ((selectPage + 1) * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE)) {
                animating = NO;
                [self unschedule:@selector(animateCharacter:)];
                [self stepBackAnimation];
            }
            
        } else {
            animating = NO;
            [self unschedule:@selector(animateCharacter:)]; 
        }
        
    }
}

- (void) finishAnimation 
{
    animating = NO;
    
    [self unschedule:@selector(animateCharacter:)];   
    
    int i;
    for (i=currentCharacter; i < numCharacters; i++) {
        
        NSRange range = NSMakeRange(0, i);
        NSString *display = [text substringWithRange:range];
        
        CGSize sizeText = [self calculateLabelSize:display withFont:fontReference maxSize:CGSizeMake(background.contentSize.width - 30, MAX_TEXT_HEIGHT)];
        
        if (sizeText.height > ((selectPage + 1) * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE)) {
            break; 
        }
    }
    
    //CCLOG(@"Skip characters from %i to %i", 0, i - 1);
    currentCharacter = i - 1;
    
    [label setString:[text substringWithRange:NSMakeRange(0, currentCharacter)]];
    
    if (currentCharacter < numCharacters - 1) [self stepBackAnimation];
}

-(void) prepareText
{
    speed = 50.0f;
    speechSpeeds = [[CCArray array] retain];
    currentCharacter = 0;
    
    // Manage the speech commands (speed)
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{[a-z]*\\}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:text
                                      options:0
                                        range:NSMakeRange(0, [text length])];
    
    [speechSpeeds removeAllObjects];
    
    int offset = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *matchText = [text substringWithRange:[match range]];
        NSRange matchRange = [match range];
        //CCLOG(@">>>> %@: %i, %i", matchText, matchRange.location, matchRange.length);
        
        CCArray *values = [CCArray arrayWithCapacity:2];
        [values addObject:[NSValue valueWithRange:NSMakeRange(matchRange.location - offset, matchRange.length)]];
        [values addObject:matchText];
        [values addObject:[NSNumber numberWithBool:NO]];
        [speechSpeeds addObject:values];
        
        offset += matchText.length;
    }
    
    [text release];
    text = [regex stringByReplacingMatchesInString:text
                                                      options:0
                                                        range:NSMakeRange(0, [text length])
                                                 withTemplate:@""];
    [text retain];
    
    numCharacters = [text length];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    //CCLOG(@"selected page: %i, num pages: %i", selectPage, numPages);
    if (selectPage < numPages - 1) {
        
        if (animating) {
            //CCLOG(@"Skip page");
            [self finishAnimation];
            
        } else {
            
            // Display next page
            selectPage++;
            
            //[label setPosition:ccp(label.position.x, label.position.y + background.contentSize.height)];
            
            if (selectPage == numPages) {
                arrow.visible = NO;
                //CCLOG(@"Animate last page");
            } else {
                //CCLOG(@"Animate page");
            }
            
            //[self removeChild:label cleanup:YES];
            //label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Sans.fnt" width:background.contentSize.width - 30 alignment:LeftAlignment page:selectPage linesPerPage:5];
            //[label.textureAtlas.texture setAliasTexParameters];
            //[label setAnchorPoint:ccp(0,1)];
            //[label setPosition: ccp(25, background.contentSize.height + 8)];    
            //[self addChild:label z:2];
            
            if (CC_CONTENT_SCALE_FACTOR() == 2) [label setPosition: ccp(25, background.contentSize.height + 8 + ((selectPage * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE) - (2*selectPage)))];
            else [label setPosition: ccp(25, background.contentSize.height + 8 + (selectPage * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE))];
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Story point page turn.caf"];
            
            [self animate];
        }
        
    } else if (animating) {
        //CCLOG(@"Skip last page");
        [self finishAnimation];
        
    } else {
        
        if ([[GameLayer getInstance] isPaused]) {
            [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
            
            //[[CCDirector sharedDirector] resume];
            //[[CCDirector sharedDirector] startAnimation];
            [[GameLayer getInstance] resume];
            
            [[GameLayer getInstance] removeOverlay:self];
            
        } else {
            [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
            [[GameLayer getInstance] removeOverlay:self];
        }
    }
    
    return YES;
}

- (void) visit 
{
	glEnable(GL_SCISSOR_TEST);
	glScissor(10*CC_CONTENT_SCALE_FACTOR(), 10*CC_CONTENT_SCALE_FACTOR(), background.contentSize.height*CC_CONTENT_SCALE_FACTOR(), background.contentSize.width*CC_CONTENT_SCALE_FACTOR());
	[super visit];
	glDisable(GL_SCISSOR_TEST);
    
}

- (void)dealloc
{
    [text release];
    [speechSpeeds release];
    [fontReference release];
    
    [super dealloc];
}

@end
