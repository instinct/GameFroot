//
//  CCLabelBMFontMultiline.h
//
//  Created by Mark Wei on 6/14/11.
//
//  Modified by Jose Miguel Gomez Gonzalez on 23/03/12 adding typewriting effect and pagination.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    CenterAlignment, LeftAlignment, RightAlignment
} CCLabelBMFontMultilineAlignment;

@interface CCLabelBMFontMultiline : CCLabelBMFont {
    NSString *initialString_;
    
    float width_;
    CCLabelBMFontMultilineAlignment alignment_;
    
    BOOL debug_;
    
    int pages_;
    int page_, linesPerPage_;
    
    int numCharacters;
    int currentCharacter;
    BOOL animating;
    float speed;
    CCArray *speechSpeeds;
    int totalOffset;
}

@property (nonatomic,copy,readonly) NSString *initialString;

@property (nonatomic,assign,readonly) float width;
@property (nonatomic,assign,readonly) int pages;
@property (nonatomic,assign,readonly) CCLabelBMFontMultilineAlignment alignment;
@property (nonatomic,assign,readonly) BOOL animating;

@property (nonatomic,assign) BOOL debug;

- (id)initWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment;

+ (CCLabelBMFontMultiline *)labelWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment;

- (id)initWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment page:(int)page linesPerPage:(int)linesPerPage;

+ (CCLabelBMFontMultiline *)labelWithString:(NSString *)string fntFile:(NSString *)font width:(float)width alignment:(CCLabelBMFontMultilineAlignment)alignment page:(int)page linesPerPage:(int)linesPerPage;

- (void)setString:(NSString*)label;

- (void)setWidth:(float)width;
- (void)setAlignment:(CCLabelBMFontMultilineAlignment)alignment;

- (void)animate;
- (void)finishAnimation;

@end
