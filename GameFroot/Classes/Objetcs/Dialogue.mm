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
#define HARD_BREAK_LIMIT    30

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
	
    fontReference = [[UIFont fontWithName:FONT_NAME size:FONT_SIZE] retain];
    
    [self prepareText];
    
    CGSize sizeText = [self calculateLabelSize:text withFont:fontReference maxSize:CGSizeMake(background.contentSize.width - 30, background.contentSize.height)];
    //CCLOG(@"text size: %f,%f", sizeText.width, sizeText.height);       
    
    label = [CCLabelTTF labelWithString:@"" dimensions:sizeText alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeWordWrap fontName:FONT_NAME fontSize:FONT_SIZE];
    
    [label setAnchorPoint:ccp(0,1)];
    [label setPosition: ccp(25, background.contentSize.height + 8)];
    
    selectPage = 0;
    
    if (numPages == 1) arrow.visible = NO;
    //numPages = label.pages; // CCLabelBMFontMultiline
    
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
    //[label animate]; // CCLabelBMFontMultiline
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


-(BOOL) willFitOnPage:(NSString*)t {
    
    CGSize sizeText = [self calculateLabelSize:t withFont:fontReference maxSize:CGSizeMake(background.contentSize.width - 30, MAX_TEXT_HEIGHT)];
    //CCLOG(@"text size: %f,%f", sizeText.width, sizeText.height); 
    int nPages = (int)((sizeText.height / (FONT_SIZE + LINE_SPACE)) / LINES_PER_PAGE);
    float exact = (sizeText.height / (float)(FONT_SIZE + LINE_SPACE)) / (float)LINES_PER_PAGE;
    if (exact > (float)nPages) nPages++;
    return (nPages == 1);
}


-(uint) getIndexBeforeLastWord:(NSString*)str {
    uint currentIndex = str.length - 1;
    while (![[str substringWithRange:NSMakeRange(currentIndex, 1)] isEqualToString:@" "] && currentIndex != 0) {
        currentIndex--;
    }
    return currentIndex;
}

-(uint) getPageBreakIndexForString:(NSString*)t {
    
    if(t.length == 0) return 0;
    
    uint pageBreakIndex;
    NSString *str = [t copy];
    
    while (![self willFitOnPage:str]) {
        // remove a word from the end of the string
        pageBreakIndex = [self getIndexBeforeLastWord:str];
        str = [str substringWithRange:NSMakeRange(0, pageBreakIndex)];
    }
    return pageBreakIndex;
}

// recursive function that paginates the text
-(void) paginate:(NSString*)t result:(CCArray*)r {
    if ([self willFitOnPage:t]) {
        // Base case
        [r addObject:t];
        numPages++;
    } else {
        // recursive case
        // 1. split text at one page worth and add to result
        uint pBreak = [self getPageBreakIndexForString:t];
        if (pBreak == 0) {
            CCLOG(@"Dialog: The break was on 0, page is one contigous word, overflow will occur");
            [r addObject:t];
            numPages++;
        } else {
            [r addObject:[t substringToIndex:pBreak]];
            numPages++;
            // recurse on the rest
            [self paginate:[t substringFromIndex:pBreak] result:r];
        }
    }
}


-(void) prepareText
{
    speed = 50.0f;
    speechSpeeds = [[CCArray array] retain];
    pages = [[CCArray array] retain];
    currentCharacter = 0;
    
    //\\//\\ Manage the pagination //\\//\\
        
    [pages removeAllObjects];
    
   
    //CCLOG(@"Text to paginate: %@",text);
    //CCLOG(@"Orginal text on one page? : %i", [self willFitOnPage:text]);
    
    // Step 1. do basic pagination based on text width RECURSION!!!!
    [self paginate:text result:pages];
    
    /*
    NSString *s; CCARRAY_FOREACH(pages, s) {
        CCLOG(@"PAGE: %@", s);
    }
    */
    
    // Step 1: Create page breaks based on {page} tags
    
    // First find page break tokens
    NSError *error = NULL;
    int pageStart = 0;
    numPages = 0;
    int offset = 0;
    
    NSRegularExpression *pageRegex = [NSRegularExpression regularExpressionWithPattern:@"\\{page\\}"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    
    NSArray *pageTokenMatches = [pageRegex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    
    for (NSTextCheckingResult *match in pageTokenMatches) {
        NSRange matchRange = [match range];
        NSString *matchText = [text substringWithRange:NSMakeRange(pageStart, matchRange.location - offset)];
        offset += matchText.length;
        matchText = [pageRegex stringByReplacingMatchesInString:matchText
                                                    options:0
                                                      range:NSMakeRange(0, [matchText length])
                                               withTemplate:@""];
        matchText = [matchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [pages addObject:matchText];
        pageStart = matchRange.location + matchRange.length;
       
    }
    
    // Add final text to last page
    NSString *matchText = [text substringFromIndex:pageStart];
    matchText = [matchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [pages addObject:matchText];
    
    error = NULL;
    
    //\\//\\ Manage the speech commands (speed) //\\//
    
    /*
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{[a-z]*\\}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:text
                                      options:0
                                        range:NSMakeRange(0, [text length])];
    
    [speechSpeeds removeAllObjects];
    offset = 0;
    
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
    
    
    */
    
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
    if (selectPage < numPages - 1) {
        
        if (animating) {
            [self finishAnimation];
            
        } else {
            
            // Display next page
            selectPage++;
      
            if (selectPage == numPages) arrow.visible = NO;
            
            // CCLabelBMFontMultiline
            //[self removeChild:label cleanup:YES];
            //label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Sans.fnt" width:background.contentSize.width - 30 alignment:LeftAlignment page:selectPage linesPerPage:5];
            //[label.textureAtlas.texture setAliasTexParameters];
            //[label setAnchorPoint:ccp(0,1)];
            //[label setPosition: ccp(25, background.contentSize.height + 8)];    
            //[self addChild:label z:2];
            
            /*
            if (CC_CONTENT_SCALE_FACTOR() == 2) [label setPosition: ccp(25, background.contentSize.height + 8 + ((selectPage * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE) - (2*selectPage)))];
            else [label setPosition: ccp(25, background.contentSize.height + 8 + (selectPage * (FONT_SIZE + LINE_SPACE) * LINES_PER_PAGE))];
             */
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Story point page turn.caf"];
            
            [self animate];
            //[label animate]; // CCLabelBMFontMultiline
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
    [pages release];
    [super dealloc];
}

@end
