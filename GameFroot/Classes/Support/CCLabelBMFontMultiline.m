//
//  CCLabelBMFontMultiline.m
//
//  Created by Mark Wei on 6/14/11.
//  https://github.com/pingpongboss/CCLabelBMFontMultiline
//
//  Modified by Jose Miguel Gomez Gonzalez on 23/03/12 adding typewriting effect and pagination.
//

#import "CCLabelBMFontMultiline.h"

@interface CCLabelBMFontMultiline()

- (void)updateLabel;

@end

@implementation CCLabelBMFontMultiline

@synthesize initialString = initialString_;

@synthesize width = width_;
@synthesize alignment = alignment_;

@synthesize debug = debug_;
@synthesize pages = pages_;
@synthesize animating = animating_;

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment {
    self = [super initWithString:string fntFile:font];
    if (self) {
        initialString_ = [string copy];
        
        width_ = width;
        alignment_ = alignment;        
        
        page_ = 0;
        linesPerPage_ = 0;
        speed = 50.0f;
        
        speechSpeeds = [[CCArray array] retain];
        
        [self updateLabel];
    }
    return self;
}

+ (CCLabelBMFontMultiline *)labelWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment {
    return [[[CCLabelBMFontMultiline alloc] initWithString:string fntFile:font width:width alignment:alignment] autorelease];
}

- (id)initWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment page:(int)page linesPerPage:(int)linesPerPage {
    self = [super initWithString:string fntFile:font];
    if (self) {
        initialString_ = [string copy];
        
        width_ = width;
        alignment_ = alignment;
        
        page_ = page;
        linesPerPage_ = linesPerPage;
        pages_ = 1;
        speed = 50.0f;
        
        speechSpeeds = [[CCArray array] retain];
        
        [self updateLabel];
    }
    return self;
}

+ (CCLabelBMFontMultiline *)labelWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment page:(int)page linesPerPage:(int)linesPerPage {
    return [[[CCLabelBMFontMultiline alloc] initWithString:string fntFile:font width:width alignment:alignment page:page linesPerPage:linesPerPage] autorelease];
}

- (void)dealloc {
    [initialString_ release], initialString_ = nil;
    
    [speechSpeeds release];
    
    [super dealloc];
}

#pragma mark -

- (void)updateLabel {
    
    [string_ release];
    string_ = [initialString_ copy];
    
    [self removeAllChildrenWithCleanup:YES]; //Inserted so fontChars do not get reused
    
    [self createFontChars];
    
    //Step 1: Make multiline
    
    NSString *multilineString = @"", *lastWord = @"";
    int line = 1, i = 0, stringLength = [self.string length];
    float startOfLine = -1, startOfWord = -1;
    //Go through each character and insert line breaks as necessary
    for (CCSprite *characterSprite in self.children) {
        
        if (i >= stringLength || i < 0)
            break;
        
        unichar character = [self.string characterAtIndex:i];
        
        if (startOfWord == -1)
            startOfWord = characterSprite.position.x - characterSprite.contentSize.width/2;
        if (startOfLine == -1)
            startOfLine = startOfWord;
        
        //Character is a line break
        //Put lastWord on the current line and start a new line
        //Reset lastWord
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
            lastWord = [[lastWord stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingFormat:@"%C", character];
            multilineString = [multilineString stringByAppendingString:lastWord];
            lastWord = @"";
            startOfWord = -1;
            line++;
            startOfLine = -1;
            i++;
            
            //CCLabelBMFont do not have a character for new lines, so do NOT "continue;" in the for loop. Process the next character
            if (i >= stringLength || i < 0)
                break;
            character = [self.string characterAtIndex:i];
            
            if (startOfWord == -1)
                startOfWord = characterSprite.position.x - characterSprite.contentSize.width/2;
            if (startOfLine == -1)
                startOfLine = startOfWord;
        }
        
        //Character is a whitespace
        //Put lastWord on current line and continue on current line
        //Reset lastWord
        if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:character]) {
            lastWord = [lastWord stringByAppendingFormat:@"%C", character];
            multilineString = [multilineString stringByAppendingString:lastWord];
            lastWord = @"";
            startOfWord = -1;
            i++;
            continue;
        }
        
        //Character is out of bounds
        //Do not put lastWord on current line. Add "\n" to current line to start a new line
        //Append to lastWord
        if (characterSprite.position.x + characterSprite.contentSize.width/2 - startOfLine > self.width) {
            lastWord = [lastWord stringByAppendingFormat:@"%C", character];
            NSString *trimmedString = [multilineString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            multilineString = [trimmedString stringByAppendingString:@"\n"];
            line++;
            startOfLine = -1;
            i++;
            continue;
        } else {
            //Character is normal
            //Append to lastWord
            lastWord = [lastWord stringByAppendingFormat:@"%C", character];
            i++;
            continue;
        }
    }
    
    multilineString = [multilineString stringByAppendingFormat:@"%@", lastWord];
    
    
    //Set the label's string to multilineString. But we don't want to use [super setString]
    //because -createFontChars does the "reusing fonts" bit which messes stuff up
    //
    //
    //Taken from CCLabelBMFont -(void)setString:(NSString *)label
    
    // Manage the speech commands (speed)
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{[a-z]*\\}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
    NSArray *matches = [regex matchesInString:multilineString
                                      options:0
                                      range:NSMakeRange(0, [multilineString length])];
    
    [speechSpeeds removeAllObjects];
    
    int offset = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *matchText = [multilineString substringWithRange:[match range]];
        NSRange matchRange = [match range];
        //CCLOG(@">>>> %@: %i, %i", matchText, matchRange.location, matchRange.length);
        
        CCArray *values = [CCArray arrayWithCapacity:2];
        [values addObject:[NSValue valueWithRange:NSMakeRange(matchRange.location - offset, matchRange.length)]];
        [values addObject:matchText];
        [values addObject:[NSNumber numberWithBool:NO]];
        [speechSpeeds addObject:values];
        
        offset += matchText.length;
    }
    
    //CCLOG(@"before: %@", multilineString);
    multilineString = [regex stringByReplacingMatchesInString:multilineString
                                            options:0
                                            range:NSMakeRange(0, [multilineString length])
                                            withTemplate:@""];
    //CCLOG(@"after: %@", multilineString);
    //CCLOG(@"Command ranges: %@", speechSpeeds);
    
    // Manage the pages
    if (linesPerPage_ > 0 && line > page_ + 2)
    { 
        string_ = [[NSString stringWithString:@""] copy];
        
        NSString *copyText = [multilineString copy];
        multilineString = @"";
        
        NSArray *lines = [copyText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        pages_ = [lines count] / linesPerPage_;
        float exact = (float)[lines count] / (float)linesPerPage_;
        if (exact > (float)pages_) pages_++;
        
        int start = page_ * linesPerPage_;
        int end = start + linesPerPage_;
        
        if (start >= [lines count]) start = 0;
        if (end >= [lines count]) end  = [lines count];
        
        totalOffset = 0;
        
        for (int i = 0; i < start; i++) {
            totalOffset += [[lines objectAtIndex:i] length];
        }
        totalOffset += start;
        
        for (i = start; i < end; i++) {
            multilineString = [multilineString stringByAppendingFormat:@"%@\n", [lines objectAtIndex:i]];
        }  
        
        //CCLOG(@"page offset: %i (%i)", totalOffset, start);
    }
    
    [string_ release];
    string_ = [multilineString copy];
    
    
    [self removeAllChildrenWithCleanup:YES]; //Inserted so fontChars do not get reused by -createFontChars
    
    [self createFontChars];
    
    //END Taken from CCLabelBMFont
    //
    //
    
    
    //Step 2: Make alignment
	
    if (self.alignment != LeftAlignment) {
        
        i = 0;
        int lineNumber = 0;
        //Go through line by line
        for (NSString *lineString in [multilineString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            int lineWidth = 0;
            
            //Find index of last character in this line
            int index = i + [lineString length] - 1;
            if (index < 0 || index >= [self.children count])
                continue;
            
            //Find position of last character on the line
            CCSprite *lastChar = [self.children objectAtIndex:index];
            
            lineWidth = lastChar.position.x + lastChar.contentSize.width/2;
            
            //Figure out how much to shift each character in this line horizontally
            float shift = 0;
            switch (self.alignment) {
                case CenterAlignment:
                    shift = self.contentSize.width/2 - lineWidth/2;
                    break;
                case RightAlignment:
                    shift = self.contentSize.width - lineWidth;
                default:
                    break;
            }
            
            if (shift != 0) {
                int j = 0;
                //For each character, shift it so that the line is center aligned
                for (j = 0; j < [lineString length]; j++) {
                    index = i + j;
                    if (index < 0 || index >= [self.children count])
                        continue;
                    CCSprite *characterSprite = [self.children objectAtIndex:index];
                    characterSprite.position = ccpAdd(characterSprite.position, ccp(shift, 0));
                }
            }
            i += [lineString length];
            lineNumber++;
        }
    }
}

//Draw the bounding box of this CCLabelBMFontMultiline for troubleshooting
- (void)draw {
    [super draw];
    
    if (debug_) {
        glLineWidth(5);
        glColor4f(255, 0, 0, 255);
        ccDrawLine(ccp(0,0), ccp(0, self.contentSize.height));
        ccDrawLine(ccp(0,0), ccp(self.contentSize.width, 0));
        ccDrawLine(ccp(self.contentSize.width, 0), ccp(self.contentSize.width, self.contentSize.height));
        ccDrawLine(ccp(0, self.contentSize.height), ccp(self.contentSize.width, self.contentSize.height));
        ccDrawLine(ccp(0,0), ccp(self.contentSize.width, self.contentSize.height));
        ccDrawLine(ccp(0, self.contentSize.height), ccp(self.contentSize.width, 0));
    }
}

#pragma mark -
#pragma mark <CCLabelProtocol> Methods

- (void)setString:(NSString*)label {
    [initialString_ release];
    initialString_ = [label copy];
    
    [super setString:label];
    
    [self updateLabel];
}

- (void)animate {
    for (CCSprite *characterSprite in self.children) {
        characterSprite.visible = NO;
    }
    
    currentCharacter = 0;
    numCharacters = [self.children count];
    
    animating_ = YES;
    
    if (totalOffset > 0) {
        // Find previous speed
        CCArray *values; CCARRAY_FOREACH(speechSpeeds, values) {
            NSRange range = [[values objectAtIndex:0] rangeValue];
            if (range.location < totalOffset) {
                NSString *command = [values objectAtIndex:1];
                if ([command isEqualToString:@"{slow}"]) speed = 150;
                else if ([command isEqualToString:@"{fast}"]) speed = 20;
                else if ([command isEqualToString:@"{talk}"]) speed = 50;
                
                //CCLOG(@"Found previous speed %f", speed);
            }
        }
    }
    
    [self unschedule:@selector(animateCharacter:)];
    //CCLOG(@"Animate with speed %f", speed);
    [self schedule:@selector(animateCharacter:) interval:speed / 1000.0f];
}

-(void) animateCharacter:(ccTime) dt  {
    
    if (animating_) {
        CCSprite *characterSprite = [self.children objectAtIndex:currentCharacter];
        characterSprite.visible = YES;
        
        CCArray *values; CCARRAY_FOREACH(speechSpeeds, values) {
            NSRange range = [[values objectAtIndex:0] rangeValue];
            BOOL used = [[values objectAtIndex:2] boolValue];
            if (!used && range.location == currentCharacter + totalOffset + (page_ + 1)) {
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
        
        currentCharacter++;
        if (currentCharacter >= numCharacters) {
            animating_ = NO;
            [self unschedule:@selector(animateCharacter:)];            
        }
    }
}

- (void)finishAnimation {
    animating_ = NO;
    
    for (CCSprite *characterSprite in self.children) {
        characterSprite.visible = YES;
    }
}

#pragma mark -
#pragma mark Setter Methods

//Overwrite default setter methods

- (void)setWidth:(float)width {
    width_ = width;
    [self updateLabel];
}

- (void)setAlignment:(CCLabelBMFontMultilineAlignment)alignment {
    alignment_ = alignment;
    [self updateLabel];
}

@end
