//
//  GameMenu.m
//  GameFroot
//
//
//  Created by Sam Win-Mason on 3/02/12.
//

#import "GameMenu.h"
#import "HomeLayer.h"
#import "CJSONDeserializer.h"
#import "InputController.h"

#define MAIN_MENU_PROGRESS_BAR_LENGTH 410

@implementation GameMenu

+(ccColor3B) colorForHex:(NSString *)hexColor {
	
	NSString *cString = [[hexColor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
	// String should be 6 or 8 characters
	if ([cString length] < 6) return ccc3(0,0,0);
	
	// strip 0X if it appears
	if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
	
	// strip # if it appears
	if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
	
	if ([cString length] != 6) return ccc3(0,0,0);
	
	// Separate into r, g, b substrings
	NSRange range;
	range.location = 0;
	range.length = 2;
	NSString *rString = [cString substringWithRange:range];
	range.location = 2;
	NSString *gString = [cString substringWithRange:range];
	range.location = 4;
	NSString *bString = [cString substringWithRange:range];
	
	// Scan values
	unsigned int r, g, b;
	[[NSScanner scannerWithString:rString] scanHexInt:&r];
	[[NSScanner scannerWithString:gString] scanHexInt:&g];
	[[NSScanner scannerWithString:bString] scanHexInt:&b];
	
	return ccc3((float) r,
				(float) g,
				(float) b);
}

-(NSString *) returnServer
{
    // Initialise properties dictionary
    NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
    NSDictionary *properties = [[[NSDictionary alloc] initWithContentsOfFile:plistPath] retain];
    
    int serverUsed;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if([Shared isBetaMode]) {
        serverUsed = [prefs integerForKey:@"server"];
    } else {
        serverUsed = 0;
    }
    
    return serverUsed == 0 ? [properties objectForKey:@"server_live"] : [properties objectForKey:@"server_staging"];
}

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        self.isTouchEnabled = NO;
		self.isAccelerometerEnabled = NO;
        
        playMode = NO;
        
        NSString *loadingBarColor = @"";
        
        int gameId = [Shared getLevelID];
        //gameId = 24395; // Hardcode test
        NSString *gameURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_menu&game_id=%d", [self returnServer], gameId];
        
        NSString *stringData = [Shared stringWithContentsOfURL:gameURL ignoreCache:NO];
        NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonData = [[CJSONDeserializer deserializer] deserializeAsDictionary:rawData error:nil];
        //CCLOG(@">>>>>>> %@: %@", gameURL, [jsonData description]);
        
        if (jsonData != nil) {
            // Custom menu
            float scaleFactor = 0.625;
            
            NSArray *assets = [jsonData objectForKey:@"assets"];
            NSDictionary *background = [jsonData objectForKey:@"background"];
            NSDictionary *loadingBar = [jsonData objectForKey:@"loadingBar"];
            
            // Background
            CCSprite *bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:[background objectForKey:@"filename"] ignoreCache:NO]];
            [bg setScale:scaleFactor * CC_CONTENT_SCALE_FACTOR()];
            [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
            [self addChild:bg];
            
            mainMenu = [CCMenu menuWithItems:nil];
            
            // Assets
            for (int i=0; i < [assets count]; i++) {
                NSDictionary *asset = [assets objectAtIndex:i];
                
                NSString *type = [asset objectForKey:@"assetType"];
                
                if ([type isEqualToString:@"image"]) {
                    NSString *behaviour = [asset objectForKey:@"behaviour"];
                    NSString *filename = [asset objectForKey:@"filename"];
                    float width = [[asset objectForKey:@"width"] floatValue] / CC_CONTENT_SCALE_FACTOR();
                    float height = [[asset objectForKey:@"height"] floatValue] / CC_CONTENT_SCALE_FACTOR();
                    float x = [[asset objectForKey:@"x"] floatValue] * scaleFactor;
                    float y = size.height - ([[asset objectForKey:@"y"] floatValue] * scaleFactor);
                    int states = [[asset objectForKey:@"states"] intValue];
                    int zIndex = [[asset objectForKey:@"z-index"] intValue];
                    
                    if ([behaviour isEqualToString:@"PLAY"]) 
                    {
                        if ([filename isEqualToString:@"/menueditor/img/default-play.png"]) 
                        {
                            _playButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"custom_play_button_03.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"custom_play_pressed_03.png"] target:self selector:@selector(_onPlay:)];
                            
                        }
                        else 
                        {
                            CCSprite *normal;
                            CCSprite *selected;
                            
                            if (states == 3)
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, height, width, height)];
                            } 
                            else if (states == 2)
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, height, width, height)];
                            } 
                            else
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                            }
 
                            _playButton = [CCMenuItemSprite itemFromNormalSprite:normal selectedSprite:selected target:self selector:@selector(_onPlay:)];
                        }
                        
                        [_playButton setScale:scaleFactor * CC_CONTENT_SCALE_FACTOR()];
                        [_playButton setAnchorPoint:ccp(0,1)];
                        [mainMenu addChild:_playButton z:zIndex];
                        [_playButton setPosition:ccp(x, y)];
                        
                    } else if ([behaviour isEqualToString:@"HELP"]) 
                    {
                        CCMenuItemSprite *helpButton;
                        
                        if ([filename isEqualToString:@"/menueditor/img/default-help.png"]) 
                        {
                            helpButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"custom_help_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"custom_help_pressed.png"] target:self selector:@selector(_onPlay:)];
                            
                        }
                        else 
                        {
                            CCSprite *normal;
                            CCSprite *selected;
                            
                            if (states == 3)
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, height, width, height)];
                            } 
                            else if (states == 2)
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, height, width, height)];
                            } 
                            else
                            {
                                normal = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                                selected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:filename ignoreCache:NO] rect:CGRectMake(0, 0, width, height)];
                            }
    
                            helpButton = [CCMenuItemSprite itemFromNormalSprite:normal selectedSprite:selected target:self selector:@selector(_onHelp:)];
                        }
                        
                        [helpButton setScale:scaleFactor * CC_CONTENT_SCALE_FACTOR()];
                        [helpButton setAnchorPoint:ccp(0,1)];
                        [mainMenu addChild:helpButton z:zIndex];
                        [helpButton setPosition:ccp(x, y)];
                        
                    }
                }
            }
            
            if (![Shared getIssueHasOneGame]){
                CCSprite *back = [CCSprite spriteWithFile:@"back.png"];
                CCSprite *backSelected = [CCSprite spriteWithFile:@"back-pressed.png"];
                CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:back selectedSprite:backSelected target:self selector:@selector(backMenu:)];
                [mainMenu addChild:backButton z:9999999];
                [backButton setPosition: ccp(back.contentSize.width/2, size.height - back.contentSize.height/2 - 20)];
            }
            
            // Setup menu
            [mainMenu setPosition: ccp(0, 0)];
            [self addChild:mainMenu];
            
            // Loading bar color
            loadingBarColor = [loadingBar objectForKey:@"color"];
            
            
        } else {
            
            // Loading base assets
            
            CCSprite *bg = [CCSprite spriteWithFile:@"blue-bg.png"];
            [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
            [self addChild:bg];
            
            CCLabelBMFont *level = [CCLabelBMFont labelWithString:[Shared getLevelTitle] fntFile:@"Chicpix2.fnt"];
            [level.textureAtlas.texture setAliasTexParameters];
            [level setPosition:ccp(size.width*0.5,size.height*0.8)];
            [self addChild:level];
            
            NSString *authorTextPrefix = @"By ";
            CCLabelBMFont *author = [CCLabelBMFont labelWithString:[authorTextPrefix stringByAppendingString:[[Shared getLevel] valueForKey:@"author"]] fntFile:@"Chicpix.fnt"];
            [author.textureAtlas.texture setAliasTexParameters];
            author.position = ccpSub(level.position, ccp(0,40));
            [self addChild:author];
            
            // Loading menu items
            
            _playButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"play_button_03.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"play_pressed_03.png"] target:self selector:@selector(_onPlay:)];
            
            CCMenuItemSprite *helpButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"help_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"help_pressed.png"] target:self selector:@selector(_onHelp:)];
            
            CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"back_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"back_pressed.png"] target:self selector:@selector(backMenu:)];

            if ([Shared getIssueHasOneGame]){
                mainMenu = [CCMenu menuWithItems:_playButton, helpButton, nil];
            } else {
                mainMenu = [CCMenu menuWithItems:backButton, _playButton, helpButton, nil];
            }
            mainMenu.position = ccp(size.width*0.5, size.height*0.4);
            helpButton.position = ccpSub(helpButton.position, ccp(0,(4*CC_CONTENT_SCALE_FACTOR())));
            [mainMenu alignItemsHorizontallyWithPadding:30];
            [self addChild:mainMenu];
            
            CCSprite *inactive_play = [CCSprite spriteWithSpriteFrameName:@"play_deactived.png"];
            inactive_play.position = ccpAdd(mainMenu.position, _playButton.position);
            [self addChild:inactive_play];
        }
        
        // Loading progress bar assets
        if (![loadingBarColor isEqualToString:@""]) 
        {
            _progressBar = [AGProgressBar progressBarWithFile:@"custom_menu.png"];
            [_progressBar.textureAtlas.texture setAliasTexParameters];
            [_progressBar setupWithFrameNamesLeft:@"custom_bar_left.png" right:@"custom_bar_right.png" middle:@"custom_bar_middle.png" andBackgroundLeft:@"custom_loading_bar_back_left.png" right:@"custom_loading_bar_back_right.png" middle:@"custom_loading_bar_back.png" andWidth:size.width];
            _progressBar.position = ccp(0,8);
        } 
        else 
        {
            _progressBar = [AGProgressBar progressBarWithFile:@"main_menu.png"];
            [_progressBar.textureAtlas.texture setAliasTexParameters];
            [_progressBar setupWithFrameNamesLeft:@"bar_left.png" right:@"bar_right.png" middle:@"bar_middle.png" andBackgroundLeft:@"loading_bar_back_left.png" right:@"loading_bar_back_right.png" middle:@"loading_bar_back.png" andWidth:(MAIN_MENU_PROGRESS_BAR_LENGTH)];
            _progressBar.position = ccp(size.width*0.06,size.height*0.13);
        }
        
        
        if (![loadingBarColor isEqualToString:@""]) 
        {
            [_progressBar setColor:[GameMenu colorForHex:loadingBarColor]];
        } 
        
        //[self hideProgressBar];
        [self addChild:_progressBar z:10];
        [self hideProgressBar];
        
        //\\//\\ Help Screen Setup //\\//
        
        _helpScreen = [HelpScreen node];
        _helpScreen.zOrder = 2000;
        _helpScreen.visible = NO;
        [self addChild:_helpScreen];
    }
    return self;
}

// Toggles between the loading and play buttons
-(void) playModeOn:(bool)status {
    if(status) {
        [self hideProgressBar];
        _playButton.visible = YES;
    } else {
        [self showProgressBar];
        _playButton.visible = NO;
    }
}

-(void) backMenu:(id)sender {
    [[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
}

-(void) _onPlay:(id)sender {
    [[GameLayer getInstance] removeLoadingScreen];
}

-(void) _onHelp:(id)sender {
    mainMenu.visible = NO;
    _helpScreen.visible = YES;
}

-(void) closeHelp {
    mainMenu.visible = YES;
    _helpScreen.visible = NO;
}

-(void) showProgressBar {
    _progressBar.visible = YES;
}

-(void) hideProgressBar {
    _progressBar.visible = NO;
}

-(void) resetProgressBar {
    [self setProgressBar:0.0f];
}

-(void) setProgressBar:(float)percent
{
    [_progressBar setPercent:percent];
}

@end