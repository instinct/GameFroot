//
//  HomeLayer.m
//  DoubleHappy
//
//  Created by Jose Miguel on 01/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HomeLayer.h"
#import "GameLayer.h"
#import "Loader.h"
#import "Shared.h"
#import "CJSONDeserializer.h"
#import "GameCell.h"
#import "SWTableViewCell.h"
#import "CCLabelFX.h"
#import "FilteredMenu.h"
#import "OnPressMenu.h"
#import "GravatarLoader.h"
#import "AppDelegate.h"

#define ITEMS_PER_PAGE  20
#define AVATAR_TAG      12345

@implementation CCPriorityMenu

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:-9999999 swallowsTouches:YES];
}
#endif
@end

@implementation HomeLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HomeLayer *layer = [HomeLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

#pragma mark -
#pragma mark Init

// on "init" you need to initialize your instance
-(id) init
{
	[[CCDirector sharedDirector] setDeviceOrientation:kCCDeviceOrientationPortrait];
	[[CCDirector sharedDirector] setDisplayFPS:NO];
    
	
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super initWithColor:ccc4(28,28,28,255)])) {
        
        // Check what server to use, if staging or live
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        if ([Shared isBetaMode]) {
            serverUsed = [prefs integerForKey:@"server"];
        } else {
            serverUsed = 1;
        }
        
		CGSize size = [[CCDirector sharedDirector] winSize];
        
        CCSprite *background = [CCSprite spriteWithFile:@"background.png"];
		[background setPosition:ccp(size.width/2, size.height/2)];
		[self addChild:background z:1];
			
		// Initialise properties dictionary
		NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
		properties = [[[NSDictionary alloc] initWithContentsOfFile:plistPath] retain];        
    
		CCSprite *top = [CCSprite spriteWithFile:@"top-bar.png"];
		[top setPosition:ccp(size.width/2, size.height - top.contentSize.height/2)];
		[self addChild:top z:2];
         
        /*
            The GameFroot Logo is a secret button that triggers beta mode.
            To trigger beta mode, tap the logo 5 times
         */
        
        secretTaps = 0;
        
		CCSprite *logo1Normal = [CCSprite spriteWithFile:@"fruit.png"];
        CCSprite *logo1Selected = [CCSprite spriteWithFile:@"fruit.png"];
		[[logo1Normal texture] setAntiAliasTexParameters];
        [[logo1Selected texture] setAliasTexParameters];
        CCMenuItemSprite *secretButton = [CCMenuItemSprite itemFromNormalSprite:logo1Normal selectedSprite:logo1Selected target:self selector:@selector(_onBetaButtonTap:)];
        secretMenu = [CCMenu menuWithItems:secretButton, nil];
        secretMenu.position = ccp(size.width/2 - 120, size.height - top.contentSize.height/2);
        positionLogo = secretMenu.position;
		[self addChild:secretMenu z:3];
        
        editionLabel = [CCLabelTTF labelWithString:@"Gamefroot Edition #1" fontName:@"HelveticaNeue-Bold" fontSize:16];
        editionLabel.color = ccc3(255,255,255);
        editionLabel.position = ccp(size.width/2, size.height - top.contentSize.height/2);
        [self addChild:editionLabel z:4];
		
		// Containers
		featured = [CCNode node];
		[self addChild:featured z:4];
		
		playing = [CCNode node];
		[self addChild:playing z:4];
		
		browse = [CCNode node];
		[self addChild:browse z:4];
		
		myGames = [CCNode node];
		[self addChild:myGames z:4];
		
		more = [CCNode node];
		[self addChild:more z:4];
        
        welcome = [CCNode node];
        [self addChild:welcome z:4];
        
        gameDetail = [CCNode node];
        [self addChild:gameDetail z:4];
		
        // *********************************************************
        // *********************************************************
        // ******** Removing botton navigation bar for v1.0 ********
        /*
		// Main tab navigation
		CCSprite *bottom = [CCSprite spriteWithFile:@"tab-bar.png"];
		[bottom setPosition:ccp(size.width/2, bottom.contentSize.height/2)];
		[self addChild:bottom z:10];
		
		featuredButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"icon5.png"] selectedSprite:[CCSprite spriteWithFile:@"icon5-selected.png"] target:self selector:@selector(featured:)];
		playingButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"icon4.png"] selectedSprite:[CCSprite spriteWithFile:@"icon4-selected.png"] target:self selector:@selector(playing:)];
		browseButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"icon3.png"] selectedSprite:[CCSprite spriteWithFile:@"icon3-selected.png"] target:self selector:@selector(browse:)];
		myGamesButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"icon2.png"] selectedSprite:[CCSprite spriteWithFile:@"icon2-selected.png"] target:self selector:@selector(myGames:)];
		moreButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"icon1.png"] selectedSprite:[CCSprite spriteWithFile:@"icon1-selected.png"] target:self selector:@selector(more:)];
		
		CCLabelTTF *featuredLabelSelected = [CCLabelTTF labelWithString:@"Featured" dimensions:CGSizeMake(featuredButton.selectedImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		featuredLabelSelected.anchorPoint = ccp(0,-0.0);
		featuredLabelSelected.color = ccc3(255,255,255);
		[featuredButton.selectedImage addChild:featuredLabelSelected];
		
		CCLabelTTF *featuredLabelNormal = [CCLabelTTF labelWithString:@"Featured" dimensions:CGSizeMake(featuredButton.normalImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		featuredLabelNormal.anchorPoint = ccp(0,-0.0);
		featuredLabelNormal.color = ccc3(200,200,200);
		[featuredButton.normalImage addChild:featuredLabelNormal];
		
		
		CCLabelTTF *playingLabelSelected = [CCLabelTTF labelWithString:@"Playing" dimensions:CGSizeMake(playingButton.selectedImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		playingLabelSelected.anchorPoint = ccp(0,-0.0);
		playingLabelSelected.color = ccc3(255,255,255);
		[playingButton.selectedImage addChild:playingLabelSelected];
		
		CCLabelTTF *playingLabelNormal = [CCLabelTTF labelWithString:@"Playing" dimensions:CGSizeMake(playingButton.normalImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		playingLabelNormal.anchorPoint = ccp(0,-0.0);
		playingLabelNormal.color = ccc3(200,200,200);
		[playingButton.normalImage addChild:playingLabelNormal];
		
		CCNode *badge = [CCNode node];
		CCSprite *badgeLeft = [CCSprite spriteWithFile:@"badge-left.png"];
		badgeMiddle = [CCSprite spriteWithFile:@"badge-middle.png"];
		badgeRight = [CCSprite spriteWithFile:@"badge-right.png"];
		
		[badgeLeft setAnchorPoint:ccp(0,0)];
		[badgeMiddle setAnchorPoint:ccp(0,0)];
		[badgeRight setAnchorPoint:ccp(0,0)];
		
		[badgeLeft setPosition:ccp(playingButton.contentSize.width/2, playingButton.contentSize.height - badgeLeft.contentSize.height)];
		[badgeMiddle setPosition:ccp(badgeLeft.position.x + badgeLeft.contentSize.width, badgeLeft.position.y)];
		
		[badge addChild:badgeLeft];
		[badge addChild:badgeMiddle];
		[badge addChild:badgeRight];
		
		playingLabel = [CCLabelTTF labelWithString:@"" fontName:@"HelveticaNeue-Bold" fontSize:13];
		playingLabel.anchorPoint = ccp(0,-0.15);
		playingLabel.color = ccc3(255,255,255);
		[badge addChild:playingLabel];
		[playingLabel setPosition:ccp(badgeMiddle.position.x - 3, badgeMiddle.position.y)];
		
		[self updatePlayedBadge];
		
		[playingButton addChild:badge];
		
		
		CCLabelTTF *browseLabelSelected = [CCLabelTTF labelWithString:@"Browse" dimensions:CGSizeMake(browseButton.selectedImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		browseLabelSelected.anchorPoint = ccp(0,-0.0);
		browseLabelSelected.color = ccc3(255,255,255);
		[browseButton.selectedImage addChild:browseLabelSelected];
		
		CCLabelTTF *browseLabelNormal = [CCLabelTTF labelWithString:@"Browse" dimensions:CGSizeMake(browseButton.normalImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		browseLabelNormal.anchorPoint = ccp(0,-0.0);
		browseLabelNormal.color = ccc3(200,200,200);
		[browseButton.normalImage addChild:browseLabelNormal];
		
		
		CCLabelTTF *myGamesLabelSelected = [CCLabelTTF labelWithString:@"My Games" dimensions:CGSizeMake(myGamesButton.selectedImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		myGamesLabelSelected.anchorPoint = ccp(0,-0.0);
		myGamesLabelSelected.color = ccc3(255,255,255);
		[myGamesButton.selectedImage addChild:myGamesLabelSelected];
		
		CCLabelTTF *myGamesLabelNormal = [CCLabelTTF labelWithString:@"My Games" dimensions:CGSizeMake(myGamesButton.normalImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		myGamesLabelNormal.anchorPoint = ccp(0,-0.0);
		myGamesLabelNormal.color = ccc3(200,200,200);
		[myGamesButton.normalImage addChild:myGamesLabelNormal];
		
		
		CCLabelTTF *moreLabelSelected = [CCLabelTTF labelWithString:@"More" dimensions:CGSizeMake(moreButton.selectedImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		moreLabelSelected.anchorPoint = ccp(0,-0.0);
		moreLabelSelected.color = ccc3(255,255,255);
		[moreButton.selectedImage addChild:moreLabelSelected];
		
		CCLabelTTF *moreLabelNormal = [CCLabelTTF labelWithString:@"More" dimensions:CGSizeMake(moreButton.normalImage.contentSize.width,13) alignment:CCTextAlignmentCenter fontName:@"HelveticaNeue-Bold" fontSize:10];
		moreLabelNormal.anchorPoint = ccp(0,-0.1);
		moreLabelNormal.color = ccc3(200,200,200);
		[moreButton.normalImage addChild:moreLabelNormal];
		
		
		OnPressMenu *menuBottom = [OnPressMenu menuWithItems:featuredButton, playingButton, browseButton, myGamesButton, moreButton, nil];
		menuBottom.position = ccp(size.width/2, bottom.contentSize.height/2 - 1);
		[menuBottom alignItemsHorizontallyWithPadding:2];
		
		[menuBottom reorderChild:playingButton z:browseButton.zOrder+1];
		
		[self addChild:menuBottom z:11];
		*/
        // *********************************************************
        // *********************************************************
        
		// Init variables
		jsonDataFeatured = nil;
		jsonDataBrowse = nil;
		jsonDataMyGames = nil;
		userName = nil;
        emailAddress = nil;
        conn = nil;
		
		jsonDataPlaying = [[prefs objectForKey:@"favourites"] mutableCopy];
		if (!jsonDataPlaying) {
			jsonDataPlaying = [[NSMutableArray arrayWithCapacity:1] retain];
		} else {
			[jsonDataPlaying retain];
		}
		
		filteredArray = nil;
		tableData = nil;
		selectedPage = nil;
		loading = NO;
        displayingDeleteButton = NO;
        ratingsAnchorEnabled = NO;
        gameDetailLoaded = NO;
        tableView = nil;
        
		/*if([[NSUserDefaults standardUserDefaults] boolForKey:@"firstlaunch"] && ![Shared getWelcomeShown]) {
            // Do some stuff on first launch
            [Shared setWelcomeShown:YES];
            [self loadWelcome];
            
        } else {
        */    
            [featuredButton selected]; // Only select navigation button if no welcome screen
            
            RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
            [rvc showBanner];
        
            // If we have come from a game, go to that games' detail page
            if(![Shared getLevel]) {
                // Load featured panel, out default screen.
                [self loadFeatured];
                
            } else {
                ratingsAnchorEnabled = YES;
                [self loadGameDetail];
                selectedPage = gameDetail;
            }
        //}
        
        
        /*
        //  Load gravatar
        loadedAvatar = NO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        emailAddress = [defaults objectForKey:@"FBEmailAddress"];
        //CCLOG(@">>>> check avatar: %@", emailAddress);
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
		if ((emailAddress != nil) && [[app facebook] isSessionValid] && ([Shared connectedToNetwork])) {
            GravatarLoader *gravatarLoader = [[[GravatarLoader alloc] initWithTarget:self andHandle:@selector(setGravatarImage:)] autorelease];
            [gravatarLoader loadEmail:emailAddress withSize:32*CC_CONTENT_SCALE_FACTOR()];
            loadedAvatar = YES;
        }
        */
	}
	
	return self;
}

-(NSString *) returnServer
{
    return serverUsed == 1 ? [properties objectForKey:@"server_live"] : [properties objectForKey:@"server_staging"];
}

-(void) updatePlayedBadge {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	tableData = [[prefs objectForKey:@"favourites"] mutableCopy];
	unsigned int played = 0;
	if (tableData) played = [tableData count];
	
	[playingLabel setString:[NSString stringWithFormat:@"%i", played]];
	
	[badgeMiddle setScaleX:playingLabel.contentSize.width*CC_CONTENT_SCALE_FACTOR() - 6*CC_CONTENT_SCALE_FACTOR()];
	[badgeRight setPosition:ccp(badgeMiddle.position.x + badgeMiddle.contentSize.width * badgeMiddle.scaleX, badgeMiddle.position.y)];
	
}

#pragma mark -
#pragma mark Event handlers

-(void) _onBetaButtonTap:(id)sender {
    secretTaps++;
    if(secretTaps == 6) {
        secretTaps = 0;
        if ([Shared isBetaMode]) {
            CCLOG(@"Beta mode off!");
            [Shared setBetaMode:NO];
            [self changeServer:1];
            UIAlertView *av = [[[UIAlertView alloc] initWithTitle: @"Beta Mode Disabled" 
                                                                 message: @"You have disabled Beta Mode."
                                                                delegate: self 
                                                       cancelButtonTitle: @"Refresh" 
                                                       otherButtonTitles: nil] autorelease];
            [av show];
            
        } else {
            CCLOG(@"Beta mode on!");
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [Shared setBetaMode:YES];
            [self changeServer:[prefs integerForKey:@"server"]];;
            UIAlertView *av = [[[UIAlertView alloc] initWithTitle: @"Beta Mode Enabled" 
                                  message: @"Beta mode is now enabled. This is for developers only. To disable Beta mode, touch the GameFroot logo 6 times."
                                  delegate: self 
                                  cancelButtonTitle: @"Refresh" 
                                  otherButtonTitles: nil] autorelease];
            [av show];
        }
        
    }
}

-(void) selectedLevel:(id)sender {
    [Loader hideAsynchronousLoader];
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc hideBanner];
    
    /*
    NSMutableDictionary *fakeLevel = [NSMutableDictionary dictionary];
    [fakeLevel setObject:@"Jose Gomez" forKey:@"author"];
    [fakeLevel setObject:@"http://gamefroot.com/wp-content/plugins/game_data/backgrounds/user/small-burning_town_background-8.png" forKey:@"background"];
    [fakeLevel setObject:@"Fake level for testing..." forKey:@"content"];
    [fakeLevel setObject:@"10792" forKey:@"id"];
    [fakeLevel setObject:@"1" forKey:@"published"];
    [fakeLevel setObject:@"2012-06-26 07:37:23" forKey:@"published_date"];
    [fakeLevel setObject:@"Fake level" forKey:@"title"];
    [Shared setLevel:fakeLevel];
    */
    
	[[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
}


// Selected featured buttons
-(void) featured1:(id)sender {
    
    // HACK: This is hardcoded for now.
    int featuredGameID = 4320;
    
    NSString *levelsURL;
    
    if([Shared isBetaMode]) {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=promotional", [self returnServer]];
    } else {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=ios-promotional", [self returnServer]];
    }
    
    CCLOG(@"Load promotional levels: %@", levelsURL);
    
    // Try to load cached version first, if not load online
    NSArray *data;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];        
    if ([prefs objectForKey:@"promotional"] != nil) {
        data = [[prefs objectForKey:@"promotional"] mutableCopy];
        CCLOG(@"Load cached promotional levels");
    } else {
        NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:NO];
        NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
        data = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] mutableCopy];
    }
    
    CCLOG(@"Level 1: %@", [data description]);
    
    if (!data || [data count] == 0)
    {
        return;
    }
    
    NSDictionary *levelD;
    
    // Find the featured game ID
    for (NSDictionary *level in data) {
        if ([[level objectForKey:@"id"] intValue] == featuredGameID) {
            levelD = level;
        }
    }
    
    if(levelD == NULL) return;
    
    // use the map Id for the Issac game
	[Shared setLevel:[levelD mutableCopy]];
    
    //[self selectedLevel:nil];
    [self loadGameDetail];
}

-(void) featured2:(id)sender {
	
    NSString *levelsURL;
    
    if([Shared isBetaMode]) {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=promotional", [self returnServer]];
    } else {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=ios-promotional", [self returnServer]];
    }

    CCLOG(@"Load promotional levels: %@", levelsURL);
    
    // Try to load cached version first, if not load online
    NSArray *data;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];        
    if ([prefs objectForKey:@"promotional"] != nil) {
        data = [[prefs objectForKey:@"promotional"] mutableCopy];
        
        CCLOG(@"Load cached promotional levels");
        
    } else {
        NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:NO];
        NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
        data = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] mutableCopy];
    }
    
    CCLOG(@"Level 2: %@", [data description]);
    
    if (!data || [data count] <= 1)
    {
        return;
    }
    
	[Shared setLevel:[[data objectAtIndex:0] mutableCopy]];
    
    //[self selectedLevel:nil];
    [self loadGameDetail];
}

// Main navigation
-(void) featured:(id)sender {
	if (loading) {
		if (selectedPage != featured) [featuredButton unselected];
		return;
	}
	
	[featuredButton selected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton unselected];
	
    welcome.visible = NO;
	if (selectedPage != featured) featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
    gameDetail.visible = NO;
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc showBanner];
	
	[self loadFeatured];
}

-(void) playing:(id)sender {
	if (loading) {
		if (selectedPage != playing) [playingButton unselected];
		return;
	}
	
	[featuredButton unselected];
	[playingButton selected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton unselected];
	
    welcome.visible = NO;
	featured.visible = NO;
	if (selectedPage != playing) playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
    gameDetail.visible = NO;
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc showBanner];
	
	
	[self loadPlaying];
}

-(void) browse:(id)sender {
	if (loading) {
		if (selectedPage != browse) [browseButton unselected];
		return;
	}
	
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton selected];
	[myGamesButton unselected];
	[moreButton unselected];
	
    welcome.visible = NO;
	featured.visible = NO;
	playing.visible = NO;
	if (selectedPage != browse) browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
    gameDetail.visible = NO;
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc showBanner];
	
	
	[self loadBrowse];
}

-(void) myGames:(id)sender {
	if (loading) {
		if (selectedPage != myGames) [myGamesButton unselected];
		return;
	}
	
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton selected];
	[moreButton unselected];
	
    welcome.visible = NO;
	featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	if (selectedPage != myGames) myGames.visible = NO;
	more.visible = NO;
    gameDetail.visible = NO;
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc showBanner];
	
	[self loadMyGames];
}

-(void) more:(id)sender {
	if (loading) {
		if (selectedPage != more) [moreButton unselected];
		return;
	}
	
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton selected];
	
    welcome.visible = NO;
	featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	if (selectedPage != more) more.visible = NO;
    gameDetail.visible = NO;
    
	[self loadMore];
}

#pragma mark -
#pragma mark Game Detail event handlers


-(void) gameDetailBack:(id)sender 
{
    editionLabel.visible = YES;
    secretMenu.position = positionLogo;
    
    welcome.visible = NO;
	featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
    gameDetail.visible = NO;
	
    CCNode *previousPage = selectedPage;
    selectedPage = gameDetail;
    
    if(previousPage == featured) {
        [self loadFeatured];
    } else if(previousPage == playing) {
        [self loadPlaying];
    } else if(previousPage == browse) {
        [self loadBrowse];
    } else if(previousPage == myGames) {
        [self loadMyGames];
    } else {
        [self loadFeatured];
    }
}

-(void) gameDetailRemix:(id)sender {
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (![[app facebook] isSessionValid] || (![Shared connectedToNetwork])) {
        // Not logged
        UIAlertView *alertView1 = [[[UIAlertView alloc] initWithTitle: @"Login required to remix" 
                                                             message: @"You must be logged in to remix the game, select login to be redirected to the My Games section and hit Login"
                                                            delegate: self 
                                                   cancelButtonTitle: @"Cancel" 
                                                   otherButtonTitles: @"My Games", nil] autorelease];
        [alertView1 show];

        
    } else {
        // logged in
        UIAlertView *alertView2 = [[[UIAlertView alloc] initWithTitle: @"Think you can improve this game?" 
                                                              message: @"Take a copy of this game, then modify it on a computer."
                                                             delegate: self 
                                                    cancelButtonTitle: @"Cancel" 
                                                    otherButtonTitles: @"Start a Remix", nil] autorelease];
        [alertView2 show];
    }
    
}

-(void) gameDetailPlay:(id)sender {
    
    // Add level to favourites
    for (uint i = 0; i < [jsonDataPlaying count]; i++) {
        NSDictionary *ld = [jsonDataPlaying objectAtIndex:i];
        int levelId = [[ld objectForKey:@"id"] intValue];
        if (levelId == [Shared getLevelID]) {
            [jsonDataPlaying removeObjectAtIndex:i];
            break;
        }
    }
    
    // if we havn't already retrieved the level data get it now
    // need to check correct json data depending on where we've come from
    
    
    NSString *author = [[Shared getLevel] objectForKey:@"author"];
    
    //CCLOG(@">>>>>> %@, %@", author, [author class]);
    if ([author isMemberOfClass:[NSNull class]]) {
        [[Shared getLevel] setObject:userName forKey:@"author"];
    }
    
    [jsonDataPlaying insertObject:[Shared getLevel] atIndex:0];
    
    //CCLOG(@"Add favourite: %@", [[Shared getLevel] description]);
    //CCLOG(@"Favourites: %@", [jsonDataPlaying description]);
    
    [self selectedLevel:sender];
}


-(void) like:(id)sender {
    
    NSMutableDictionary *ld = [Shared getLevel];
    
    NSString *url = [NSString stringWithFormat:@"%@?eventstats_api&log_event", [self returnServer]];
    
    NSString *postData = [NSString stringWithFormat:@"event_type=like&resource_id=%@&user_id=%@&source_type=%@&source_id=%@",
                          [ld objectForKey:@"id"],
                          @"0",
                          @"iOS",
                          [NSString stringWithFormat:@"%@ %@", [Shared getDevice], [Shared getOSVersion]]
                          ];
    
    //NSString *result = 
    [Shared stringWithContentsOfPostURL:url post:postData];
    //CCLOG(@"LIKE! Result: %@",  result);
    
    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Like!" 
                                                         message: @"You liked this game! The result has been recorded on the GameFroot website."
                                                        delegate: nil 
                                               cancelButtonTitle: @"Ok" 
                                               otherButtonTitles: nil] autorelease];
    [alertView show];
}

-(void) unlike:(id)sender {
    
    NSMutableDictionary *ld = [Shared getLevel];
    
    NSString *url = [NSString stringWithFormat:@"%@?eventstats_api&log_event", [self returnServer]];
    
    NSString *postData = [NSString stringWithFormat:@"event_type=dislike&resource_id=%@&user_id=%@&source_type=%@&source_id=%@",
                          [ld objectForKey:@"id"],
                          @"0",
                          @"iOS",
                          [NSString stringWithFormat:@"%@ %@", [Shared getDevice], [Shared getOSVersion]]
                          ];
    
    //NSString *result = 
    [Shared stringWithContentsOfPostURL:url post:postData];
    //CCLOG(@"DISLIKE! Result: %@",  result);

    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Dislike!" 
                                                         message: @"You disliked this game! The result has been recorded on the GameFroot website."
                                                        delegate: nil 
                                               cancelButtonTitle: @"Ok" 
                                               otherButtonTitles: nil] autorelease];
    [alertView show];
}



#pragma mark -
#pragma mark Connection


- (void)asynchronousContentsOfURL:(NSString *)url
{
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                 timeoutInterval:10.0];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn) {
        receivedData = [[NSMutableData data] retain];
        connecting = YES;
        
    } else {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Server Connection" 
                                                             message: @"We cannot connect to our servers, please review your internet connection." 
                                                            delegate: nil 
                                                   cancelButtonTitle: @"Ok" 
                                                   otherButtonTitles: nil] autorelease];
        [alertView show];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [connection release];
    [receivedData release];
	connecting = NO;
    
    // inform the user
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Server Connection" 
                                                         message: @"We cannot connect to our servers, pleaser review your internet connection." 
                                                        delegate: nil 
                                               cancelButtonTitle: @"Ok" 
                                               otherButtonTitles: nil] autorelease];
    [alertView show];
	
	[Loader hideAsynchronousLoader];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere
	connecting = NO;
	
    
    if (selectedPage == featured) {
        
        /*
		NSMutableArray *jsonDataUpdatedFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:receivedData error:nil] mutableCopy];
		//CCLOG(@"Levels: %@", [jsonDataUpdatedFeatured description]);
        CCLOG(@"HomeLayer.connectionDidFinishLoading: featured refresh list");
        
        // Cache result
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:jsonDataUpdatedFeatured forKey:@"featured"];
        [prefs synchronize];
        */
        
        // Too dangerous to refresh the list asynchronously since it may be in use
        /*
        // Filter array
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
        if (filteredArray != nil) [filteredArray release];
        filteredArray = [[jsonDataUpdatedFeatured filteredArrayUsingPredicate:predicate] retain];
        tableData = [filteredArray mutableCopy];
        
        [tableView reloadData];
        */
    }
	
	
    // release the connection, and the data object
	[connection release];
    [receivedData release];
}

#pragma mark -
#pragma mark Welcome

-(void) loadWelcome 
{
	selectedPage = welcome;
    CCLOG(@"HomeLayer.loadWelcome called!");
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadWelcome)];
	loading = YES;
}

-(void) _loadWelcome 
{
    [Loader hideAsynchronousLoader];
    
	CGSize size = [[CCDirector sharedDirector] winSize];
    // Some stuff for the welcome screen here.
    // add a textplaceholder
    
    CCLabelTTF *placeHolderText = [CCLabelTTF labelWithString:@"Welcome screen" fontName:@"HelveticaNeue-Bold" fontSize:16];
    placeHolderText.color = ccc3(255,255,255);
    placeHolderText.position = ccp(size.width/2, size.height/2);
    [welcome addChild:placeHolderText z:4];
    
    
    loading = NO;
	welcome.visible = YES;
}


#pragma mark -
#pragma mark GameDetail

-(void) loadGameDetail 
{
    editionLabel.visible = NO;
    secretMenu.position = ccpAdd(positionLogo, ccp(120,0));
    
    // [self cancelAsynchronousConnection];
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadGameDetail)];
    loading = YES;
}

-(CGSize) calculateLabelSize:(NSString *)string withFont:(UIFont *)font maxSize:(CGSize)maxSize {
    return [string
            sizeWithFont:font
            constrainedToSize:maxSize
            lineBreakMode:UILineBreakModeWordWrap];
    
}

-(void) _loadGameDetail {    
    CGSize size = [[CCDirector sharedDirector] winSize];
        
    [Loader hideAsynchronousLoader];
    
    [gameDetail removeAllChildrenWithCleanup:YES];
    
    NSMutableDictionary *ld = [Shared getLevel];
    CCLOG(@"levelData = %@", ld);
     
    NSString *author = [ld objectForKey:@"author"];
    if ([author isMemberOfClass:[NSNull class]]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        author = [defaults objectForKey:@"FBFullName"];
    }
    
    // Text Stuff!
    CCLabelTTF *levelNameText = [CCLabelTTF labelWithString:[ld objectForKey:@"title"] fontName:@"HelveticaNeue-Bold" fontSize:16];
    [levelNameText setColor:ccc3(255, 255, 255)];
    CCLabelTTF *authorText = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"By %@", author] fontName:@"HelveticaNeue-Bold" fontSize:13];
    [authorText setColor:ccc3(144, 144, 144)];
    
    NSString *desc = [ld objectForKey:@"content"];
    //NSString *desc = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?";
    //NSString *desc = @"Sed ut perspiciatis unde omnis iste";
    
    UIFont *fontReference = [UIFont fontWithName:@"HelveticaNeue" size:10];
    CGSize sizeText = [self calculateLabelSize:desc withFont:fontReference maxSize:CGSizeMake(size.width - 24, 1024)];
    CCLabelTTF *descriptionText = [CCLabelTTF labelWithString:desc dimensions:sizeText alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue" fontSize:12];
    [descriptionText setColor:ccc3(0, 0, 0)];
    
    // Game thumb
    /*
    CCSprite *gameImage;
    NSString *urlThumb = [NSString stringWithFormat:@"%@/wp-content/plugins/game_data/thumbs/%@.png", [self returnServer], [ld objectForKey:@"id"]];
    CCLOG(@"Load thumb: %@", urlThumb);
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlThumb] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    CCLOG(@"statusCode = %d", [response statusCode]);
    
    if ([response statusCode] == 404) {
        gameImage = [CCSprite spriteWithFile:@"game_detail_proxy_image.png"];
        
    } else {
        gameImage = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:urlThumb ignoreCache:NO]];
    }
    */
    
    CCSprite *gameImage = [CCSprite spriteWithFile:@"game_detail_proxy_image.png"];
    CCSprite *imageOverlay = [CCSprite spriteWithFile:@"game_detail_image_overlay.png"];
    
    // Add top menu and buttons
    CCMenuItemSprite *topNavBackButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"back-button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"back-button.png"] target:self selector:@selector(gameDetailBack:)];
    CCMenu *topNavMenu = [CCMenu menuWithItems:topNavBackButton, nil];
    
    // Add some stuff to the content area    
    CCMenuItemSprite *contentPlayButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"play-button-up.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"play-button-down.png"] target:self selector:@selector(gameDetailPlay:)];
    CCMenu *contentMenu = [CCMenu menuWithItems:contentPlayButton, nil];
    
    // Like buttons
    CCMenuItem *likeButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"like-button-up.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"like-button-down.png"] target:self selector:@selector(like:)];
    
    CCMenuItem *unlikeButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"dislike-button-up.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"dislike-button-down.png"] target:self selector:@selector(unlike:)];
    
    //CCMenuItem *remixButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"remix-button-up.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"remix-button-down.png"] target:self selector:@selector(gameDetailRemix:)];
    
    CCRadioMenu *likeMenu = [CCMenu menuWithItems:likeButton, unlikeButton, /*remixButton,*/ nil];
    [likeMenu alignItemsHorizontallyWithPadding:20];
    
    CCNode *container = [CCNode node];
    //CCLayerColor *container = [CCLayerColor layerWithColor:ccc4(255,0,0,255)];
    
    CCLayerGradient *containerText = [CCLayerGradient layerWithColor:ccc4(158,158,158,255) fadingTo:ccc4(214,214,214,255)];
    [container addChild:containerText];
    
    // Calculate size of the layer
    // NOTE! cocos2d layers don't get size according to his cildren
    CGSize sizeScroll = CGSizeMake(size.width, 18 + gameImage.contentSize.height + 20 + levelNameText.contentSize.height + 12 + sizeText.height + 12 + contentPlayButton.contentSize.height + 12 + likeButton.contentSize.height + authorText.contentSize.height + 12);
    CGSize sizeView = CGSizeMake(size.width, size.height - (50)); // - (45 + 50) Screen size minus bottom and top navigation margins
    //CCLOG(@"scroll: %f,%f", sizeScroll.width, sizeScroll.height);
    //CCLOG(@"view: %f,%f", sizeView.width, sizeView.height);
    
    // position stuff
    topNavMenu.position = ccp((topNavBackButton.contentSize.width / 2) + 5, size.height - (topNavBackButton.contentSize.height/2) - 7);
    
    // relative to container
    levelNameText.position = ccp(levelNameText.contentSize.width/2 + 12, sizeScroll.height - 12);
    authorText.position = ccp(authorText.contentSize.width/2 + 12, levelNameText.position.y - 18);
    
    gameImage.position = ccp(size.width/2, authorText.position.y - 14 - gameImage.contentSize.height/2);
    imageOverlay.position = gameImage.position;
    
    contentMenu.position = ccp(size.width/2, gameImage.position.y - gameImage.contentSize.height/2 - contentPlayButton.contentSize.height/2 - 10);
    
    [containerText setContentSize:CGSizeMake(size.width, sizeText.height + 10 + likeButton.contentSize.height + 50)];
    containerText.position = ccp(0, contentMenu.position.y - contentPlayButton.contentSize.height/2 - likeButton.contentSize.height - sizeText.height - 20 - 50);
    descriptionText.position = ccp(sizeText.width/2 + 12, sizeText.height/2 + likeButton.contentSize.height + 50);
    likeMenu.position = ccp(size.width/2, likeButton.contentSize.height/2 + 10);
    
    
    [gameDetail addChild:topNavMenu];
    
    /*
    [gameDetail addChild:contentMenu];
    [gameDetail addChild:likeMenu];
    [gameDetail addChild:levelNameText];
    [gameDetail addChild:authorText];
    [gameDetail addChild:descriptionText];
    [gameDetail addChild:gameImage];
    [gameDetail addChild:imageOverlay z:20];
    */

    [container addChild:contentMenu];
    [container addChild:levelNameText];
    [container addChild:authorText];
    [containerText addChild:descriptionText];
    [containerText addChild:likeMenu];
    [container addChild:gameImage];
    [container addChild:imageOverlay z:20];
    
    
    gameDetailSV = [SWScrollView viewWithViewSize:sizeView container:container];
    gameDetailSV.contentSize = sizeScroll;
    gameDetailSV.direction = SWScrollViewDirectionVertical;
    gameDetailSV.position = ccp(0,0); // (0,50) Bottom navigation margin

    if(ratingsAnchorEnabled) {
        // Scroll to ratings section
        [gameDetailSV setContentOffset:ccp(0, -(sizeScroll.height - sizeView.height)) animated:NO];
        
        if (sizeScroll.height > sizeView.height) {
            //[gameDetailSV setContentOffset:ccp(0, -(sizeScroll.height - sizeView.height) + sizeScroll.height - likeMenu.contentSize.height - 20) animated:YES];
            [gameDetailSV setContentOffset:ccp(0, -(sizeScroll.height - sizeView.height) + (sizeScroll.height - sizeView.height)) animated:YES];            
        }
        ratingsAnchorEnabled = NO;
        
    } else {
        // Scroll to top
        [gameDetailSV setContentOffset:ccp(0, -(sizeScroll.height - sizeView.height)) animated:NO];
    }
    
    [gameDetail addChild:gameDetailSV];
    gameDetailSV.visible = YES;
    
    loading = NO;
   
	gameDetail.visible = YES;
    gameDetailLoaded = YES;
}

#pragma mark -
#pragma mark Featured

-(void) loadFeatured {
	if ((selectedPage == featured) && !gameDetailLoaded) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = featured;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadFeatured)];
	loading = YES;
    gameDetailLoaded = NO;
}

-(void) _loadFeatured {
	
    //BOOL refreshInBackground = NO;
    
	if (jsonDataFeatured == nil) {
        
        featuredPage = 1;
        
        NSString *levelsURL;
        
        if([Shared isBetaMode]) {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=featured&page=%i", [self returnServer], featuredPage];
        } else {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=issue-0&page=%i", [self returnServer], featuredPage];
        }

		CCLOG(@"Load levels: %@",levelsURL);
        
        /*
        // Try to load cached version first, if not load online
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];        
        if ([prefs objectForKey:@"featured"] != nil) {
            jsonDataFeatured = [[prefs objectForKey:@"featured"] mutableCopy];
            
            CCLOG(@"Loaded cached levels");
            refreshInBackground = YES;
            
        } else {
            // Cache not found, load online
        */
            NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
            
            NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
            jsonDataFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] mutableCopy];
            //CCLOG(@"Levels: %@", [jsonDataFeatured description]);
            
            if(!jsonDataFeatured)
            {
                return;
            }
        
        /*
            // Save locally for next time
            [prefs setObject:jsonDataFeatured forKey:@"featured"];
            [prefs synchronize];
        }*/
	}
	
    [Loader hideAsynchronousLoader];
    
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	// Featured panel
	CCMenuItemSprite *featured1Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"gamefroot-promo.png"] selectedSprite:[CCSprite spriteWithFile:@"gamefroot-promo.png"] target:self selector:@selector(more:)];
    /*
	CCMenuItemSprite *featured2Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"feature-icon.png"] selectedSprite:[CCSprite spriteWithFile:@"feature-icon.png"] target:self selector:@selector(featured2:)];
     */
    
	CCMenu *menuFeatured = [CCMenu menuWithItems:featured1Button, /*featured2Button,*/ nil];
	menuFeatured.position = ccp(size.width/2, size.height - 44 - featured1Button.contentSize.height/2);
    //menuFeatured.position = ccp(featured1Button.contentSize.width/2 + 10, size.height - 44 - featured1Button.contentSize.height/2 - 5);
	
    [menuFeatured alignItemsHorizontally];
	[featured addChild:menuFeatured z:4];
    
    // Filter array
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataFeatured filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	
	loaded = ITEMS_PER_PAGE*featuredPage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*featuredPage) loaded = total;
	
    // ********************************************************
    // ********************************************************
    // ******************** Hack for v1.0 *********************
	//tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, 270)]; // - 50 to height for iAd
	//tableView.position = ccp(0,(50)); // Add 50 to y for iAd
    
    tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, 270 + 10)];
	tableView.position = ccp(0,0);
    // ********************************************************
    // ********************************************************
    
    tableView.direction = SWScrollViewDirectionVertical;
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[featured addChild:tableView z:5];
	[tableView reloadData];
	
	loading = NO;
	featured.visible = YES;
    
    /*
    if (refreshInBackground) {
        // Now load in the background online levels
        NSString *levelsURL;
        
        if([Shared isBetaMode]) {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=featured&page=%i", [self returnServer], 1];
        } else {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=issue-0&page=%i", [self returnServer], 1];
        }

        [self asynchronousContentsOfURL:levelsURL];
    }
	*/
}

-(void) _loadMoreFeatured {
    featuredPage++;
    NSString *levelsURL;
    
    if([Shared isBetaMode]) {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=featured&page=%i", [self returnServer], featuredPage];
    } else {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=issue-0&page=%i", [self returnServer], featuredPage];
    }

    CCLOG(@"Load levels: %@",levelsURL);
    
    NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
    
    NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonDataMoreFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
    //CCLOG(@"Levels: %@", [jsonDataMoreFeatured description]);
    
    if(!jsonDataMoreFeatured)
    {
        return;
    }
    
    [jsonDataFeatured addObjectsFromArray:jsonDataMoreFeatured];
    
    // Filter array
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataFeatured filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	
	loaded = ITEMS_PER_PAGE*featuredPage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*featuredPage) loaded = total;
	
    
    [tableView reloadData];
    [tableView setContentOffset:ccp(0,[tableView contentOffset].y-58*([jsonDataMoreFeatured count])) animated:NO];
}

#pragma mark -
#pragma mark Playing

-(void) loadPlaying {
	if ((selectedPage == playing) && !gameDetailLoaded) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = playing;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadPlaying)];
	loading = YES;
    gameDetailLoaded = NO;
}

-(void) _loadPlaying {
	[Loader hideAsynchronousLoader];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	tableData = [[prefs objectForKey:@"favourites"] mutableCopy];
	if (!tableData) {
		loading = NO;
		playing.visible = YES;	
		return;
	}

	loaded = total = [tableData count];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, size.height - (45 + 50))];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,50);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[playing addChild:tableView z:5];
	[tableView reloadData];
	
	loading = NO;
	playing.visible = YES;
}

#pragma mark -
#pragma mark Browse

-(void) loadBrowse {
	if ((selectedPage == browse) && !gameDetailLoaded) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = browse;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadBrowse)];
	loading = YES;
}

-(void) _loadBrowse {
	[Loader hideAsynchronousLoader];
	
    /*
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	CCSprite *searchBox = [CCSprite spriteWithFile:@"search-box.png"];
	[browse addChild:searchBox z:6];
	searchBox.position = ccp(size.width/2,size.height - 45 - searchBox.contentSize.height/2);
	
	searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, size.width - 80, 24)];
    [searchTextField setDelegate:self];
    [searchTextField setText:@""];
	
	//searchTextField.backgroundColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:1.0];
	searchTextField.borderStyle = UITextBorderStyleNone;
	[searchTextField setTextColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];
	
	searchField = [CCUIViewWrapper wrapperForUIView:searchTextField];
	searchField.contentSize = CGSizeMake(size.width - 80, 24);
	
	if (CC_CONTENT_SCALE_FACTOR() == 2) searchField.position = ccp(size.width - 40, size.height - 50 - 18 - 12);
	else searchField.position = ccp(size.width/2, size.height - 50 - 18);
	
	[browse addChild:searchField z:7];
	
	CCMenuItemSprite *clearButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"clear-search.png"] selectedSprite:[CCSprite spriteWithFile:@"clear-search.png"] target:self selector:@selector(clearSearch:)];
	CCMenu *menu = [CCMenu menuWithItems:clearButton, nil];
	menu.position = ccp(size.width - clearButton.contentSize.width - 5, searchBox.position.y);
	[browse addChild:menu z:8];
	
	loading = NO;
	browse.visible = YES;
    */
    
    if (jsonDataBrowse == nil) {
        
        browsePage = 1;
		
        // use differnt catagory depending on wether we are in beta mode or not
        // If beta mode use standard categories, if not beta use special ios categories
        
        NSString *levelsURL;
        
        if([Shared isBetaMode]) {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&page=%i", [self returnServer], browsePage];
        } else {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=ios-browse&page=%i", [self returnServer], browsePage];
        }
		
		CCLOG(@"Load levels: %@",levelsURL);
		
		NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataBrowse = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] mutableCopy];
		//CCLOG(@"Levels: %@", [jsonDataBrowse description]);
		
		if(!jsonDataBrowse)
		{
			return;
		}
	}
    
    // Filter array
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataBrowse filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	loaded = ITEMS_PER_PAGE*browsePage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*browsePage) loaded = total;
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, size.height - (45 + 50))];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,50);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[browse addChild:tableView z:5];
	[tableView reloadData];
	
	loading = NO;
	browse.visible = YES;
}

-(void) _loadMoreBrowse {
    browsePage++;
    NSString *levelsURL;
    
    if([Shared isBetaMode]) {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&page=%i", [self returnServer], browsePage];
    } else {
        levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=ios-browse&page=%i", [self returnServer], browsePage];
    }

    CCLOG(@"Load levels: %@",levelsURL);
    
    NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
    
    NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonDataMoreBrowse = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
    //CCLOG(@"Levels: %@", [jsonDataMoreBrowse description]);
    
    if(!jsonDataMoreBrowse)
    {
        return;
    }
    
    [jsonDataBrowse addObjectsFromArray:jsonDataMoreBrowse];
    
    // Filter array
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataBrowse filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	
	loaded = ITEMS_PER_PAGE*browsePage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*browsePage) loaded = total;
	
    
    [tableView reloadData];
    [tableView setContentOffset:ccp(0,[tableView contentOffset].y-58*([jsonDataMoreBrowse count])) animated:NO];
}

-(void) reloadBrowse {
	if (tableView) [browse removeChild:tableView cleanup:YES];
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_reloadBrowse)];
	loading = YES;
}

-(void) _reloadBrowse {
	[Loader hideAsynchronousLoader];
	
	if (jsonDataBrowse == nil) {
		
		NSString *levelsURL;
        
        if([Shared isBetaMode]) {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels", [self returnServer]];
        } else {
            levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels&category=ios-browse", [self returnServer]];
        }

		CCLOG(@"Load levels: %@",levelsURL);
		
		NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataBrowse = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
		//CCLOG(@"Levels: %@", [jsonDataBrowse description]);
		
		if(!jsonDataBrowse)
		{
			return;
		}
	}
	
	// Filter array
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchTextField.text];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataBrowse filteredArrayUsingPredicate:predicate] retain];
	//CCLOG(@"Search results: %@", [filteredArray description]);
	tableData = [filteredArray mutableCopy];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	loaded = ITEMS_PER_PAGE;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE) loaded = total;
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, size.height - (45 + 45 + 50))];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,50);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[browse addChild:tableView z:5];
	[tableView reloadData];
	
	loading = NO;
	browse.visible = YES;
}

-(void)clearSearch: (id)sender {
	[searchTextField setText:@""];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	CCLOG(@"Keyboard Done Pressed: %@", textField.text);
	
	[textField resignFirstResponder];
	
	[self reloadBrowse];
	
	return YES;
}

#pragma mark -
#pragma mark My Games

-(void) loadMyGames {
	if ((selectedPage == myGames) && !gameDetailLoaded) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = myGames;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadMyGames)];
	loading = YES;
}

-(void) displayMyGames {
	[Loader hideAsynchronousLoader];
	
	if (tableView != nil) [selectedPage removeChild:tableView cleanup:YES]; // Avoid multiple calls of the facebook request details as it's asyncronous
    
	if (jsonDataMyGames == nil) {
        
        myGamesPage = 1;
	
		NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_user_levels&page=%1", [self returnServer], myGamesPage];
		CCLOG(@"Load levels: %@",levelsURL);
		
		NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataMyGames = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] mutableCopy];
		//CCLOG(@"Levels: %@", [jsonDataMyGames description]);
	}
	
	if(!jsonDataMyGames)
	{
		loading = NO;
		myGames.visible = YES;	
		return;
	}
	
	// Filter array
	/*NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataMyGames filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	*/
    tableData = [jsonDataMyGames mutableCopy];
    
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	loaded = ITEMS_PER_PAGE*myGamesPage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*myGamesPage) loaded = total;
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, size.height - (45 + 45 + 50 + 50))];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,100);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[myGames addChild:tableView z:1];
	[tableView reloadData];
	
	loading = NO;
	myGames.visible = YES;
}

-(void) _loadMoreMyGames {
    myGamesPage++;
    
    NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_user_levels&page=%i", [self returnServer], myGamesPage];
    CCLOG(@"Load levels: %@",levelsURL);
    
    NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
    
    NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonDataMoreMyGames = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
    //CCLOG(@"Levels: %@", [jsonDataMoreBrowse description]);
    
    if(!jsonDataMoreMyGames)
    {
        return;
    }
    
    [jsonDataMyGames addObjectsFromArray:jsonDataMoreMyGames];
    
    // Filter array
	/*NSPredicate *predicate = [NSPredicate predicateWithFormat:@"published == YES"];
	if (filteredArray != nil) [filteredArray release];
	filteredArray = [[jsonDataMyGames filteredArrayUsingPredicate:predicate] retain];
	tableData = [filteredArray mutableCopy];
	*/
    tableData = [jsonDataMyGames mutableCopy];
    
	loaded = ITEMS_PER_PAGE*myGamesPage;
	total = [tableData count];
	if (total < ITEMS_PER_PAGE*myGamesPage) loaded = total;
	
    
    [tableView reloadData];
    [tableView setContentOffset:ccp(0,[tableView contentOffset].y-58*([jsonDataMoreMyGames count])) animated:NO];
}

-(void) _loadMyGames {
	[Loader hideAsynchronousLoader];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
    /*
	CCSprite *headerBox = [CCSprite spriteWithFile:@"header-box.png"];
	[myGames addChild:headerBox z:6];
	headerBox.position = ccp(size.width/2,size.height - 45 - headerBox.contentSize.height/2);
	*/
    
	AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
	
	if (![[app facebook] isSessionValid] || (![Shared connectedToNetwork])) {
		
		CCMenuItemSprite *loginButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"LoginNormal.png"] selectedSprite:[CCSprite spriteWithFile:@"LoginPressed.png"] target:self selector:@selector(fbLogin:)];
		CCMenu *menu = [CCMenu menuWithItems:loginButton, nil];
		menu.position = ccp(size.width - loginButton.contentSize.width/2 - 5, size.height - 45 - loginButton.contentSize.height/2 - 8);
		[myGames addChild:menu z:100 tag:100];
		
		loading = NO;
		myGames.visible = YES;
		
	} else {
		//CCLOG(@">>>>>>>>>>>> Facebook Connect already connected");
		
		if (userName == nil) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			userName = [defaults objectForKey:@"FBFullName"];
		}
        
		if (userName == nil) {
			[[app facebook] requestWithGraphPath:@"me" andDelegate:self];
			[Loader showAsynchronousLoader];
			
		} else {
            if ((emailAddress != nil) && [self checkLogin:emailAddress]) {
                [self setupMyGamesHeader];
                [Loader showAsynchronousLoaderWithDelayedAction:0.1f target:self selector:@selector(displayMyGames)];
            
            } else {
                [[app facebook] requestWithGraphPath:@"me" andDelegate:self];
                [Loader showAsynchronousLoader];
                
            }
		}
	}
}

#pragma mark -
#pragma mark Facebook Connect

-(void) fbLogin:(id)sender {
	AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
	[app facebook].sessionDelegate = self;
	
	NSArray *permissions = [[NSArray alloc] initWithObjects:
							@"user_website", 
							nil];
	
	[[app facebook] authorize:permissions];
	[permissions release];
	
	//loading = YES;
	myGames.visible = NO;
}

-(void) fbLogout:(id)sender {
	AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
	[[app facebook] logout:self];
	
	loading = YES;
	myGames.visible = NO;
}

-(void) fbDidLogin {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging succesful: %@, %@", userName, emailAddress);
	
	AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[app facebook] accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[[app facebook] expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
	
	[[app facebook] requestWithGraphPath:@"me" andDelegate:self];
	[Loader showAsynchronousLoader];
	
	loading = YES;
}

-(void) fbDidNotLogin:(BOOL)cancelled {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging unsuccesful");
	
	loading = NO;
	myGames.visible = YES;
}

-(void) fbDidLogout {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect loggout succesful");
	
	// Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
		[defaults removeObjectForKey:@"FBFullName"];
        [defaults removeObjectForKey:@"FBEmailAddress"];
        [defaults synchronize];
    }
    
    [self removeChildByTag:AVATAR_TAG cleanup:YES];
    [self removeChildByTag:AVATAR_TAG+1 cleanup:YES];
	loadedAvatar = NO;
    
	[jsonDataMyGames release];
	jsonDataMyGames = nil;
	
	[userName release];
	userName = nil;
    
    [emailAddress release];
	emailAddress = nil;
    
	[self featured:nil];
}

-(void) setupMyGamesHeader {
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	CCLabelFX *nameLabel= [CCLabelFX labelWithString:[NSString stringWithFormat:@"Logged as %@", userName] dimensions:CGSizeMake(size.width - 80, 13) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:13
										shadowOffset:CGSizeMake(-1,1) 
										  shadowBlur:2.0f 
										 shadowColor:ccc4(0,0,0,255) 
										   fillColor:ccc4(200,200,200,255)];
	nameLabel.anchorPoint = ccp(0,0.5);
	[nameLabel setPosition: ccp(10, size.height - 50 - 15)];
	
	CCMenuItemSprite *logoutButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"LogoutNormal.png"] selectedSprite:[CCSprite spriteWithFile:@"LogoutPressed.png"] target:self selector:@selector(fbLogout:)];
	CCMenu *menu = [CCMenu menuWithItems:logoutButton, nil];
	menu.position = ccp(size.width - logoutButton.contentSize.width/2 - 5, size.height - 45 - logoutButton.contentSize.height/2 - 8);
	[myGames addChild:menu z:100];
	
	[myGames removeChildByTag:90 cleanup:YES];
	[myGames addChild:nameLabel z:90 tag:90];
	
	[myGames removeChildByTag:100 cleanup:YES]; // remove login button	
}

-(BOOL) checkLogin:(NSString *)email
{
    if (jsonDataMyGames != nil) return YES;
    
    NSString *userLoginURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=ios_login", [self returnServer]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *post = [NSString stringWithFormat:@"token=%@", [defaults objectForKey:@"FBAccessTokenKey"]];
	NSString *stringData = [Shared stringWithContentsOfPostURL:userLoginURL post:post];
	
	CCLOG(@"ios_login result: %@ (%@)", stringData, post);
	
	return ([stringData isEqualToString:@"success"]);
}

-(void)request:(FBRequest *)request didLoad:(id)result {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect request succesful: %@", result);
	
	if (selectedPage != myGames) return;
	
    NSString *email = [result objectForKey:@"email"];	
    
	if ([self checkLogin:email]) {
		userName = [[result objectForKey:@"name"] retain];
        emailAddress = [email retain];
		[self setupMyGamesHeader];
		[Loader showAsynchronousLoaderWithDelayedAction:0.1f target:self selector:@selector(displayMyGames)];
		
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userName forKey:@"FBFullName"];
        [defaults setObject:emailAddress forKey:@"FBEmailAddress"];
        [defaults synchronize];
        
	} else {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Facebook Connect" 
								message: @"There was a problem with your request" 
								delegate: self 
								cancelButtonTitle: @"Logout" 
								otherButtonTitles: nil] autorelease];
		[alertView show];
		[Loader hideAsynchronousLoader];
        
        loading = NO;
        myGames.visible = NO;
	}
    
    /*
    if (!loadedAvatar) {
        GravatarLoader *gravatarLoader = [[[GravatarLoader alloc] initWithTarget:self andHandle:@selector(setGravatarImage:)] autorelease];
        [gravatarLoader loadEmail:emailAddress withSize:32*CC_CONTENT_SCALE_FACTOR()];
        loadedAvatar = YES;
    }
    */
}

-(void) setGravatarImage:(UIImage *)img
{
    //CCLOG(@">>>>>>>>>>>> Gravatar: %@", img);
    
    CCTexture2D *tex;
    
    if (CC_CONTENT_SCALE_FACTOR() == 2) tex = [[CCTexture2D alloc] initWithImage:img resolutionType:kCCResolutionRetinaDisplay];
    else tex = [[CCTexture2D alloc] initWithImage:img resolutionType:kCCResolutionStandard];
    
    CCSprite *original = [CCSprite spriteWithTexture:tex];
    
    CCSprite *mask = [CCSprite spriteWithFile:@"mask-avatar.png"];
    CCSprite *avatar = [Shared maskedSpriteWithSprite:original maskSprite:mask];
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    [avatar setPosition:ccp(size.width - avatar.contentSize.width/2 - 10, size.height - avatar.contentSize.height/2 - 10)];
    [self addChild:avatar z:AVATAR_TAG tag:AVATAR_TAG];
    
    CCMenuItem *item = [CCMenuItem itemWithTarget:self selector:@selector(myGames:)];
    item.contentSize = avatar.contentSize;
    CCMenu *menu = [CCMenu menuWithItems:item, nil];
    [menu setPosition:avatar.position];
    [self addChild:menu z:AVATAR_TAG-1 tag:AVATAR_TAG-1];
}

#pragma mark -
#pragma mark AlertView handler

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if ([title isEqualToString:@"Logout"])
    {
		[self fbLogout:nil];
        
    } else if ([title isEqualToString:@"My Games"]) {
        if (gameDetailLoaded) {
            [gameDetail removeAllChildrenWithCleanup:YES];
            gameDetailLoaded = NO;
        }
        [self loadMyGames];
     
    } else if ([title isEqualToString:@"Refresh"]) {
        // Refresh current page
        CCNode *previousPage = selectedPage;
        if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
        selectedPage = nil;
        if(previousPage == featured) {
            [self loadFeatured];
        } else if(previousPage == playing) {
            [self loadPlaying];
        } else if(previousPage == browse) {
            [self loadBrowse];
        } else if(previousPage == myGames) {
            [self loadMyGames];
        } else {
            [self loadFeatured];
        }
    
    } else if ([title isEqualToString:@"Start a remix"]) {
        
        NSMutableDictionary *ld = [Shared getLevel];
        
        NSString *url = [NSString stringWithFormat:@"%@?gamemakers_api&type=clone_level", [self returnServer]];
        NSString *postData = [NSString stringWithFormat:@"id=%@", [ld objectForKey:@"id"]];
        
        NSString *result = [Shared stringWithContentsOfPostURL:url post:postData];
        CCLOG(@"CLONE! Result: %@",  result);
        
        if ([result intValue] > 0) {
        
            UIAlertView *alertView1 = [[[UIAlertView alloc] initWithTitle: @"Remix Copy Ready." 
                                                              message: @"A copy of this game is now ready for remixing on gamefroot.com. Visit our website on a computer, open this level in the level editor and make your changes!"
                                                             delegate: nil 
                                                    cancelButtonTitle: @"Awesome!" 
                                                    otherButtonTitles: nil] autorelease];
            [alertView1 show];
            
        } else {
            UIAlertView *alertView2 = [[[UIAlertView alloc] initWithTitle: @"Error" 
                                                                 message: @"There was a problem, please try again later." 
                                                                delegate: nil 
                                                       cancelButtonTitle: @"Ok" 
                                                       otherButtonTitles: nil] autorelease];
            [alertView2 show];
        }
    }
}

#pragma mark -
#pragma mark More

-(void) loadMore 
{
    editionLabel.visible = NO;
    secretMenu.position = ccpAdd(positionLogo, ccp(120,0));
    
	if (selectedPage == more) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = more;
    
    RootViewController *rvc = [((AppDelegate*)[UIApplication sharedApplication].delegate) viewController];
    [rvc hideBanner];
    
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadMore)];
	loading = YES;
}

-(void) _loadMore {
	[Loader hideAsynchronousLoader];
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCSprite *logo = [CCSprite spriteWithFile:@"funsplosion.png"];
    [logo setPosition:ccp(size.width/2, size.height - 100 - logo.contentSize.height/2)];
    [more addChild:logo];
    
    //CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:@"© 2010–2012 Instinct Entertainment" fontName:@"HelveticaNeue" fontSize:13];
    CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:@"So you want to make a game? It's never been easier! Just head over to gamefroot.com login, and start creating! Anybody can do it!" dimensions:CGSizeMake(size.width - 40,300) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue" fontSize:17];
    
    moreLabel.color = ccc3(255,255,255);
    moreLabel.position = ccp(size.width/2, logo.position.y - logo.contentSize.height/2 - moreLabel.contentSize.height/2 - 10);
    [more addChild:moreLabel];
    
#if COCOS2D_DEBUG
    if ([Shared isBetaMode]) {
        [CCMenuItemFont setFontSize:17];
        [CCMenuItemFont setFontName:@"HelveticaNeue"];
        
        CCMenuItemToggle *serverOptions = [CCMenuItemToggle itemWithTarget:self selector:@selector(server:) items:
                                           [CCMenuItemFont itemFromString: @"Staging"],
                                           [CCMenuItemFont itemFromString: @"Live"],
                                           nil];
        [serverOptions setSelectedIndex:serverUsed];
        
        CCMenuItemToggle *debugOptions = [CCMenuItemToggle itemWithTarget:self selector:@selector(immortal:) items:
                                          [CCMenuItemFont itemFromString: @"Mortal"],
                                          [CCMenuItemFont itemFromString: @"Immortal"],
                                          nil];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        int immortal = [prefs integerForKey:@"immortal"];
        [debugOptions setSelectedIndex:immortal];
        
        int server = [prefs integerForKey:@"server"];
        [serverOptions setSelectedIndex:server];
        
        CCMenu *menu = [CCMenu menuWithItems:serverOptions, debugOptions, nil];
        [menu alignItemsHorizontallyWithPadding:25.0f];
        [more addChild:menu];
        
        [menu setPosition:ccp(size.width/2, size.height - 50 - serverOptions.contentSize.height/2)];
    }
#endif
    
    // Add top menu and buttons
    CCMenuItemSprite *topNavBackButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"back-button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"back-button.png"] target:self selector:@selector(gameDetailBack:)];
    CCMenu *topNavMenu = [CCMenu menuWithItems:topNavBackButton, nil];
    topNavMenu.position = ccp((topNavBackButton.contentSize.width / 2) + 5, size.height - (topNavBackButton.contentSize.height/2) - 7);
    [more addChild:topNavMenu];
    
	loading = NO;
	more.visible = YES;
}

-(void) server:(id)sender {
    [self changeServer:[sender selectedIndex]];
}

-(void) changeServer:(int)server {
    serverUsed = server;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setInteger:serverUsed forKey:@"server"];
	[prefs synchronize];
    
    if (jsonDataFeatured != nil) [jsonDataFeatured release];
	if (jsonDataBrowse != nil) [jsonDataBrowse release];
	if (jsonDataMyGames != nil) [jsonDataMyGames release];
    
    jsonDataFeatured = nil;
    jsonDataBrowse = nil;
    jsonDataMyGames = nil;
    
    // Reset cached lists
    [jsonDataPlaying removeAllObjects];
    [prefs setObject:jsonDataPlaying forKey:@"favourites"];
    [prefs removeObjectForKey:@"featured"];
    [prefs synchronize];
    
    [self updatePlayedBadge];
}
    
-(void) immortal:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setInteger:[sender selectedIndex] forKey:@"immortal"];
	[prefs synchronize];
}

#pragma mark -
#pragma mark SWTableView

-(NSUInteger)numberOfCellsInTableView:(SWTableView *)table {
    //CCLOG(@"HomeLayer.numberOfCellsInTableView: %i, %i", total, loaded);
    
    if (selectedPage == playing) return total;
    else if (total == 0) return 0;
    else return total % ITEMS_PER_PAGE == 0 ? total + 1 : total;
}

-(SWTableViewCell *)table:(SWTableView *)table cellAtIndex:(NSUInteger)idx 
{
	if ((int)idx >= loaded) {
		
		GameCell *cell = (GameCell *)[table dequeueCell];
		if (!cell) {
            
			cell = [[GameCell new] autorelease];
			cell.index = idx;
			cell.levelId = 0;
			
			//CCLOG(@"Add more cell: %i, %i", idx, 0);
			
			// Button more
			CCSprite *back;
			if (idx%2 == 1) {
                back = [CCSprite spriteWithFile:@"dark-row.png"];
                
            } else {
                back = [CCSprite spriteWithFile:@"light-row.png"];
            }
            
            back.anchorPoint = CGPointZero;
			
			CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
			backSelected.anchorPoint = CGPointZero;
			backSelected.visible = NO;

			CCLabelFX *label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"Load %i more games...", ITEMS_PER_PAGE] dimensions:CGSizeMake(200,16) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:16
											 shadowOffset:CGSizeMake(-1,1) 
											   shadowBlur:2.0f 
											  shadowColor:ccc4(0,0,0,255) 
												fillColor:ccc4(255,255,255,255)];
			
			label.anchorPoint = ccp(0,0.5);
			[label setPosition: ccp(60, back.contentSize.height/2)];
			
			CCLabelFX *title = [CCLabelFX labelWithString:@"" dimensions:CGSizeMake(200,13) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:13
											 shadowOffset:CGSizeMake(-1,1) 
											   shadowBlur:2.0f 
											  shadowColor:ccc4(0,0,0,255) 
												fillColor:ccc4(200,200,200,255)];
			title.anchorPoint = ccp(0,0.5);
			[title setPosition: ccp(60, 45)];
			
			[cell addChild:back z:1 tag:1];
			[cell addChild:backSelected z:2 tag:2];
			[cell addChild:label z:3 tag:3];
			[cell addChild:title z:5 tag:5];
			
		} else {
			//CCLOG(@"Replace more cell: %i, %i (%i, %i)", idx, 0, cell.index, cell.levelId);
			
			[cell removeChildByTag:1 cleanup:YES];
            
            CCSprite *back;
			if (idx%2 == 1) {
                back = [CCSprite spriteWithFile:@"dark-row.png"];
                
            } else {
                back = [CCSprite spriteWithFile:@"light-row.png"];
            }
            
            back.anchorPoint = CGPointZero;
			[cell addChild:back z:1 tag:1];
            
			if (cell.levelId > 0) {
				[cell removeChildByTag:4 cleanup:YES];
			}
			
			CCLabelFX *label = (CCLabelFX*)[cell getChildByTag:3];
			
			[label setString:[NSString stringWithFormat:@"Load %i more games...", ITEMS_PER_PAGE]];
			
			CCLabelFX *title = (CCLabelFX*)[cell getChildByTag:5];
			[title setString:@""];
			
			cell.index = idx;
			cell.levelId = 0;
		}
		
		return cell;
		
	} else {
		
		NSDictionary *cellData = [tableData objectAtIndex:idx];
		NSString *title = [cellData objectForKey:@"title"];
		NSString *background = [cellData objectForKey:@"background"];
		int levelId = [[cellData objectForKey:@"id"] intValue];
		//CCLOG(@"Level '%@'", title);
		
		GameCell *cell = (GameCell *)[table dequeueCell];
		if (!cell) {
			cell = [[GameCell new] autorelease];
			cell.index = idx;
			cell.levelId = levelId;
			cell.data = cellData;
			
			//CCLOG(@"Add cell: %i, %i", idx, levelId);
			
			// Button row
			CCSprite *back;
			if (idx%2 == 1) {
                back = [CCSprite spriteWithFile:@"dark-row.png"];
                
            } else {
                back = [CCSprite spriteWithFile:@"light-row.png"];
            }
            
            back.anchorPoint = CGPointZero;
			
			CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
			backSelected.anchorPoint = CGPointZero;
			backSelected.visible = NO;
			
			CCLabelFX *label = [CCLabelFX labelWithString:title dimensions:CGSizeMake(200,16) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:16
											 shadowOffset:CGSizeMake(-1,1) 
											   shadowBlur:2.0f 
											  shadowColor:ccc4(0,0,0,255) 
												fillColor:ccc4(255,255,255,255)];
			
			label.anchorPoint = ccp(0,0.5);
			[label setPosition: ccp(60, back.contentSize.height/2)];
			
			NSString *author = [cellData objectForKey:@"author"];
			if ((author == nil) || [author isMemberOfClass:[NSNull class]]) {
				if (selectedPage == myGames) author = [cellData objectForKey:@"published_date"]; //author = userName;
				else author = @"";
			}
			
			CCLabelFX *title = [CCLabelFX labelWithString:author dimensions:CGSizeMake(200,13) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:13
											 shadowOffset:CGSizeMake(-1,1) 
											   shadowBlur:2.0f 
											  shadowColor:ccc4(0,0,0,255) 
												fillColor:ccc4(200,200,200,255)];
			title.anchorPoint = ccp(0,0.5);
			[title setPosition: ccp(60, 45)];
			
			CCSprite *bg;
			if ((background != nil) && ![background isEqualToString:@""]) {
				//CCLOG(@"Thumb: %@", background);
                
				NSArray *values = [background componentsSeparatedByString:@"/"];
				//CCLOG(@"Thumb: %@", [values lastObject]);
                
                CCSprite *original;
                
                if ([Shared existEmbeddedFile:[values lastObject]]) {
                    // Use default embedded background thumb
                    //CCLOG(@"Use default thumb: %@", [values lastObject]);
                    original = [CCSprite spriteWithFile:[values lastObject]];
                    
                } else {
                    // Download custom background thumb
                    //CCLOG(@"Download custom thumb: %@", background);
                    original = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
                }
				
				
				[original setScale:CC_CONTENT_SCALE_FACTOR()];
				CCSprite *mask = [CCSprite spriteWithFile:@"mask.png"];
				bg = [Shared maskedSpriteWithSprite:original maskSprite:mask];
				
				CCSprite *border = [CCSprite spriteWithFile:@"border.png"];
				[[border texture] setAliasTexParameters];
				[border setPosition:ccp(border.contentSize.width/2, border.contentSize.height/2 - 1)];
				[bg addChild:border z:1];
				
				[bg setPosition:ccp(bg.contentSize.width/2 + 5, back.contentSize.height/2)];
				
			} else {
				bg = [CCSprite node];
				[title setString:@""];
			}
			
			[cell addChild:back z:1 tag:1];
			[cell addChild:backSelected z:2 tag:2];
			[cell addChild:label z:3 tag:3];
			[cell addChild:bg z:4 tag:4];
			[cell addChild:title z:5 tag:5];
			
		} else {
            
			if (cell.index != (int)idx) {
				//CCLOG(@"Replace cell: %i, %i (%i, %i)", idx, levelId, cell.index, cell.levelId);
				
				[cell removeChildByTag:1 cleanup:YES];
                
                CCSprite *back;
                if (idx%2 == 1) {
                    back = [CCSprite spriteWithFile:@"dark-row.png"];
                    
                } else {
                    back = [CCSprite spriteWithFile:@"light-row.png"];
                }
                
                back.anchorPoint = CGPointZero;
				[cell addChild:back z:1 tag:1];
                
				if ((cell.levelId > 0) || (cell.levelId == -1)) {
					[cell removeChildByTag:4 cleanup:YES];
				}
				
				CCSprite *bg;
				if ((background != nil) && ![background isEqualToString:@""]) {
					//CCLOG(@"Thumb: %@", background);
                    
                    NSArray *values = [background componentsSeparatedByString:@"/"];
                    //CCLOG(@"Thumb: %@", [values lastObject]);
                    
                    CCSprite *original;
                    
                    if ([Shared existEmbeddedFile:[values lastObject]]) {
                        // Use default embedded background thumb
                        //CCLOG(@"Use default thumb: %@", [values lastObject]);
                        original = [CCSprite spriteWithFile:[values lastObject]];
                        
                    } else {
                        // Download custom background thumb
                        //CCLOG(@"Download custom thumb: %@", background);
                        original = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
                    }
					
					[original setScale:CC_CONTENT_SCALE_FACTOR()];
					CCSprite *mask = [CCSprite spriteWithFile:@"mask.png"];
					bg = [Shared maskedSpriteWithSprite:original maskSprite:mask];
					
					CCSprite *border = [CCSprite spriteWithFile:@"border.png"];
					[[border texture] setAliasTexParameters];
					[border setPosition:ccp(border.contentSize.width/2, border.contentSize.height/2 - 1)];
					[bg addChild:border z:1];
					
					[bg setPosition:ccp(bg.contentSize.width/2 + 5, back.contentSize.height/2)];
					
				} else {
					bg = [CCSprite node];
				}

				[cell addChild:bg z:4 tag:4];
				
				CCLabelFX *label = (CCLabelFX*)[cell getChildByTag:3];
				[label setString:title];
				
				CCLabelFX *title = (CCLabelFX*)[cell getChildByTag:5];
				if ((background != nil) && ![background isEqualToString:@""]) {
					NSString *author = [cellData objectForKey:@"author"];
					if ((author == nil) || [author isMemberOfClass:[NSNull class]]) {
						if (selectedPage == myGames) author = [cellData objectForKey:@"published_date"]; //author = userName;
						else author = @"";
					}
					[title setString:author];
					
				} else {
					[title setString:@""];
				}
				
				cell.index = idx;
				cell.levelId = levelId;
				cell.data = cellData;
			}
		}
		
		return cell;
	}
}

-(void)table:(SWTableView *)table cellTouched:(SWTableViewCell *)cell {
    //CCLOG(@"cell touched at index: %i", cell.idx);
    
    if (displayingDeleteButton) {
        if ((deleteMenu != nil) && ([deleteMenu.parent getChildByTag:10] != nil)) {   
            [deleteMenu.parent removeChildByTag:10 cleanup:YES]; // remove any delete button
            deleteMenu = nil;
        }
        
    } else {
    
        CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
        id action = [CCSequence actions:
                     [CCDelayTime actionWithDuration:0.2],
                     [CCShow action],
                     nil];
        [backSelected runAction:action];
    }
}

-(void)table:(SWTableView *)table cellTouchCancelled:(SWTableViewCell *)cell {
    //CCLOG(@"cell touch cancelled at index: %i", cell.idx);
	
	CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
	[backSelected stopAllActions];
	backSelected.visible = NO;
}

-(void)table:(SWTableView *)table cellSwipedHorizontally:(SWTableViewCell *)cell {
    //CCLOG(@"cell swipped horizontally at index: %i", cell.idx);
	
	if (selectedPage == playing) {
		CCSprite *bkSelected = (CCSprite*)[cell getChildByTag:2];
		[bkSelected stopAllActions];
		bkSelected.visible = NO;
		
        if (displayingDeleteButton) {
            if ((deleteMenu != nil) && ([deleteMenu.parent getChildByTag:10] != nil)) {
                [deleteMenu.parent removeChildByTag:10 cleanup:YES]; // remove any delete button
                deleteMenu = nil;
            }
        }
        
		CCMenuItemSprite *deleteButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"delete_btn.png"] selectedSprite:[CCSprite spriteWithFile:@"delete_btn.png"] target:self selector:@selector(deleteItem:)];
		deleteMenu = [CCPriorityMenu menuWithItems:deleteButton, nil];
		displayingDeleteButton = YES;
        
		CGSize size = [[CCDirector sharedDirector] winSize];
        [deleteMenu setPosition:ccp(size.width - deleteButton.contentSize.width/2 - 10 + 100, 58/2)];
		[cell addChild:deleteMenu z:10 tag:10];
		
        [deleteMenu runAction:[CCMoveBy actionWithDuration:0.2 position:ccp(-100, 0)]];
        
        // Crop texts, needs some work
        //CCLabelFX *label = (CCLabelFX*)[cell getChildByTag:3];
        //CCLabelFX *title = (CCLabelFX*)[cell getChildByTag:5];
        //[label setVisibleArea:CGSizeMake(150, 16)];
        //[title setVisibleArea:CGSizeMake(150, 13)];
        
		return;
	}
}

-(void)deleteItem:(id)sender {
	CCMenuItemSprite *button = (CCMenuItemSprite *)sender;
	GameCell *cell = (GameCell *)button.parent.parent;
	
	for (uint i = 0; i < [jsonDataPlaying count]; i++) {
		NSDictionary *cellData = [jsonDataPlaying objectAtIndex:i];
		int levelId = [[cellData objectForKey:@"id"] intValue];
		if (levelId == cell.levelId) {
			
			[jsonDataPlaying removeObjectAtIndex:i];
			
			NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
			[prefs setObject:jsonDataPlaying forKey:@"favourites"];
			[prefs synchronize];
			
			// Refresh without delay
			[playing removeAllChildrenWithCleanup:YES];
			[self _loadPlaying];
			
			[self updatePlayedBadge];
			
			return;
		}
	}
}

-(void)scrollViewDidScroll:(SWScrollView *)view
{
    //CCLOG(@"HomeLayer.scrollViewDidScroll");
    
    if (displayingDeleteButton) {
        if ((deleteMenu != nil) && ([deleteMenu.parent getChildByTag:10] != nil)) {
            [deleteMenu.parent removeChildByTag:10 cleanup:YES]; // remove any delete button
            deleteMenu = nil;
        }
        displayingDeleteButton = NO;
    }
}

-(void)table:(SWTableView *)table cellTouchReleased:(SWTableViewCell *)cell {
    //CCLOG(@"cell touch released at index: %i", cell.idx);
	
	CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
	//[backSelected stopAllActions];
	//backSelected.visible = NO;
    
    if (displayingDeleteButton) {
        if ((deleteMenu != nil) && ([deleteMenu.parent getChildByTag:10] != nil)) {
            [deleteMenu.parent removeChildByTag:10 cleanup:YES]; // remove any delete button
            deleteMenu = nil;
        }
        displayingDeleteButton = NO;
        
        [backSelected stopAllActions];
        backSelected.visible = NO;
        
        return;
    }
    
	GameCell *selected = (GameCell *)cell;
	if (selected.levelId > 0) {
		// Load game detail screen.
        
        //CCLOG(@"Selected data: %@", selected.data);
        //CCLOG(@"Selected Level: %i", selected.levelId);

        // store this for later.
        [Shared setLevel:[selected.data mutableCopy]];
        
        [self scheduleOnce:@selector(loadGameDetail) delay:0.1];
        //[self loadGameDetail];
	
	} else {
		// Load more
        [backSelected stopAllActions];
		backSelected.visible = NO;
		
        /*
		int load = ITEMS_PER_PAGE;
		if (load > total - loaded) load = total - loaded;
		loaded += load;
		
		int scroll = load;
		if (scroll < ITEMS_PER_PAGE) scroll--;
		
		[tableView reloadData];
		[tableView setContentOffset:ccp(0,[tableView contentOffset].y-backSelected.contentSize.height*(scroll)) animated:NO];
        */
        
        CCLabelFX *label = (CCLabelFX*)[cell getChildByTag:3];
        [label setString:@"Loading..."];
        
        if (selectedPage == featured) [self scheduleOnce:@selector(_loadMoreFeatured) delay:0.1];
        else if (selectedPage == browse) [self scheduleOnce:@selector(_loadMoreBrowse) delay:0.1];
        else if (selectedPage == myGames) [self scheduleOnce:@selector(_loadMoreMyGames) delay:0.1];
	}
}

-(CGSize)cellSizeForTable:(SWTableView *)table {
	CGSize size = [[CCDirector sharedDirector] winSize];
    return CGSizeMake(size.width, 58);
}


#pragma mark -
#pragma mark Dealloc

- (void) dealloc
{
	if (jsonDataFeatured != nil) [jsonDataFeatured release];
	if (jsonDataBrowse != nil) [jsonDataBrowse release];
	if (jsonDataMyGames != nil) [jsonDataMyGames release];
	
	if (jsonDataPlaying != nil) {
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		[prefs setObject:jsonDataPlaying forKey:@"favourites"];
		[prefs synchronize];
		[jsonDataPlaying release];
	}
	
	if (filteredArray != nil) [filteredArray release];
	
	if (userName != nil) [userName release];
	
	[properties release];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
