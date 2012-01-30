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
//#import "CCLabelBMFontMultiline.h"
#import "CCLabelFX.h"
#import "FilteredMenu.h"
#import "OnPressMenu.h"
#import "GameFrootAppDelegate.h"

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
	if( (self=[super initWithColor:ccc4(52,52,52,255)])) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];	
			
		// Initialise properties dictionary
		NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
		properties = [[[NSDictionary alloc] initWithContentsOfFile:plistPath] retain];
		
		//
		CCSprite *top = [CCSprite spriteWithFile:@"top-bar.png"];
		[top setPosition:ccp(size.width/2, size.height - top.contentSize.height/2)];
		[self addChild:top z:1];
		
		CCSprite *logo1 = [CCSprite spriteWithFile:@"gamefroot.png"];
		[[logo1 texture] setAntiAliasTexParameters];
		[logo1 setPosition:ccp(size.width/2 + 15, size.height - logo1.contentSize.height + 2)];
		[self addChild:logo1 z:2];
		
		CCSprite *logo2 = [CCSprite spriteWithFile:@"fruit.png"];
		[[logo2 texture] setAntiAliasTexParameters];
		[logo2 setPosition:ccp(logo1.position.x - logo1.contentSize.width/2 - logo2.contentSize.width/2 - 5, logo1.position.y)];
		[self addChild:logo2 z:3];
		
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
		[featuredButton selected];
		
		// Init variables
		jsonDataFeatured = nil;
		jsonDataBrowse = nil;
		jsonDataMyGames = nil;
		userName = nil;
		
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
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
		
		// Load featured panel
		[self loadFeatured];
	}
	
	return self;
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

-(void) selectedLevel:(id)sender {	
	[[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
}


// Selected featured buttons
-(void) featured1:(id)sender {
	
}

-(void) featured2:(id)sender {
	
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
	
	if (selectedPage != featured) featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
	
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
	
	featured.visible = NO;
	if (selectedPage != playing) playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
	
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
	
	featured.visible = NO;
	playing.visible = NO;
	if (selectedPage != browse) browse.visible = NO;
	myGames.visible = NO;
	more.visible = NO;
	
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
	
	featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	if (selectedPage != myGames) myGames.visible = NO;
	more.visible = NO;
	
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
	
	featured.visible = NO;
	playing.visible = NO;
	browse.visible = NO;
	myGames.visible = NO;
	if (selectedPage != more) more.visible = NO;
	[self loadMore];
}

#pragma mark -
#pragma mark Connection

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
                                                        delegate: self 
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
        
		jsonDataFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:receivedData error:nil] retain];
		//CCLOG(@"Levels: %@", [jsonData description]);
        CCLOG(@"connectionDidFinishLoading featured");
        [self _loadFeatured];
    }
	
	
    // release the connection, and the data object
	[connection release];
    [receivedData release];
}

#pragma mark -
#pragma mark Featured

-(void) loadFeatured {
	if (selectedPage == featured) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = featured;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadFeatured)];
	loading = YES;
}

-(void) _loadFeatured {
	
	if (jsonDataFeatured == nil) {
				
		NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels", [properties objectForKey:@"server_json"]];
		CCLOG(@"Load levels: %@",levelsURL);
		 
        /*
        NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
       
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
		//CCLOG(@"Levels: %@", [jsonData description]);
		
		if(!jsonDataFeatured)
		{
			return;
		}
        */
        
        NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:levelsURL]
                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                      timeoutInterval:10.0];
        conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        if (conn) {
            receivedData = [[NSMutableData data] retain];
            connecting = YES;
            
        } else {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Server Connection" 
                                                                 message: @"We cannot connect to our servers, pleaser review your internet connection." 
                                                                delegate: self 
                                                       cancelButtonTitle: @"Ok" 
                                                       otherButtonTitles: nil] autorelease];
            [alertView show];
        }
        
        return;
	}
	
    [Loader hideAsynchronousLoader];
    
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	// Featured panel
	CCMenuItemSprite *featured1Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"young-isaac-icon.png"] selectedSprite:[CCSprite spriteWithFile:@"young-isaac-icon.png"] target:self selector:@selector(featured1:)];
	CCMenuItemSprite *featured2Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"feature-icon.png"] selectedSprite:[CCSprite spriteWithFile:@"feature-icon.png"] target:self selector:@selector(featured2:)];		
	CCMenu *menuFeatured = [CCMenu menuWithItems:featured1Button, featured2Button, nil];
	menuFeatured.position = ccp(size.width/2, size.height - 44 - featured1Button.contentSize.height/2 - 5);
	[menuFeatured alignItemsHorizontally];
	[featured addChild:menuFeatured z:4];
	
	// Featured list
	tableData = [jsonDataFeatured mutableCopy];
	
	loaded = 25;
	total = [tableData count];
	if (total < 25) loaded = total;
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, 280)];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,50);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[featured addChild:tableView z:5];
	[tableView reloadData];
	
	loading = NO;
	featured.visible = YES;
	
}

#pragma mark -
#pragma mark Playing

-(void) loadPlaying {
	if (selectedPage == playing) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = playing;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadPlaying)];
	loading = YES;
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
	
	/*
	if ([tableData count] > 0) {
		NSMutableDictionary *clearItem = [NSMutableDictionary dictionaryWithCapacity:5];
		[clearItem setObject:@"" forKey:@"background"];
		[clearItem setObject:[NSNumber numberWithInt:-1] forKey:@"id"];
		[clearItem setObject:@"" forKey:@"published"];
		[clearItem setObject:@"" forKey:@"published_date"];
		[clearItem setObject:@"Clear recent played list..." forKey:@"title"];
		[tableData addObject:clearItem];
	}
	*/
	
	loaded = 25;
	total = [tableData count];
	if (total < 25) loaded = total;
	
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
	if (selectedPage == browse) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = browse;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadBrowse)];
	loading = YES;
}

-(void) _loadBrowse {
	[Loader hideAsynchronousLoader];
	
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
}

-(void) reloadBrowse {
	if (tableView) [browse removeChild:tableView cleanup:YES];
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_reloadBrowse)];
	loading = YES;
}

-(void) _reloadBrowse {
	[Loader hideAsynchronousLoader];
	
	if (jsonDataBrowse == nil) {
		
		NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels", [properties objectForKey:@"server_json"]];
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
	
	loaded = 25;
	total = [tableData count];
	if (total < 25) loaded = total;
	
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
	if (selectedPage == myGames) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = myGames;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadMyGames)];
	loading = YES;
}

-(void) displayMyGames {
	[Loader hideAsynchronousLoader];
	
	if (tableView != nil) [selectedPage removeChild:tableView cleanup:YES]; // Avoid multiple calls of the facebook request details as it's asyncronous
	
	if (jsonDataMyGames == nil) {
	
		NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_user_levels", [properties objectForKey:@"server_json"]];
		CCLOG(@"Load levels: %@",levelsURL);
		
		NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataMyGames = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
		//CCLOG(@"Levels: %@", [jsonDataMyGames description]);
	}
	
	if(!jsonDataMyGames)
	{
		loading = NO;
		playing.visible = YES;	
		return;
	}
	
	tableData = [jsonDataMyGames mutableCopy];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	loaded = 25;
	total = [tableData count];
	if (total < 25) loaded = total;
	
	tableView = [SWTableView viewWithDataSource:self size:CGSizeMake(size.width, size.height - (45 + 45 + 50))];
	
	tableView.direction = SWScrollViewDirectionVertical;
	tableView.position = ccp(0,50);
	tableView.delegate = self;
	tableView.verticalFillOrder = SWTableViewFillTopDown;
	
	[myGames addChild:tableView z:1];
	[tableView reloadData];
	
	loading = NO;
	myGames.visible = YES;
}

-(void) _loadMyGames {
	[Loader hideAsynchronousLoader];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	CCSprite *headerBox = [CCSprite spriteWithFile:@"header-box.png"];
	[myGames addChild:headerBox z:6];
	headerBox.position = ccp(size.width/2,size.height - 45 - headerBox.contentSize.height/2);
	
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	
	if (![[app facebook] isSessionValid]) {
		
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
			[self setupMyGamesHeader];
			[Loader showAsynchronousLoaderWithDelayedAction:0.1f target:self selector:@selector(displayMyGames)];
		}
	}
}

#pragma mark -
#pragma mark Facebook Connect

-(void) fbLogin:(id)sender {
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
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
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	[[app facebook] logout:self];
	
	loading = YES;
	myGames.visible = NO;
}

-(void) fbDidLogin {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging succesful");
	
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[app facebook] accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[[app facebook] expirationDate] forKey:@"FBExpirationDateKey"];
	[defaults setObject:userName forKey:@"FBFullName"];
    [defaults synchronize];
	
	[[app facebook] requestWithGraphPath:@"me" andDelegate:self];
	[Loader showAsynchronousLoader];
	
	loading = YES;
}

-(void) fbDidNotLogin:(BOOL)cancelled {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging unsuccesful");
	
	loading = NO;
	myGames.visible = NO;
}

-(void) fbDidLogout {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect loggout succesful");
	
	// Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
		[defaults removeObjectForKey:@"FBFullName"];
        [defaults synchronize];
    }
	
	[jsonDataMyGames release];
	jsonDataMyGames = nil;
	
	[userName release];
	userName = nil;
	
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

-(void)request:(FBRequest *)request didLoad:(id)result {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect request succesful: %@", result);
	
	if (selectedPage != myGames) return;
	
	NSString *email = [result objectForKey:@"email"];
	NSString *facebookid = [result objectForKey:@"id"];
	NSString *key = [NSString stringWithFormat:@"%@%@", facebookid, email];
	NSString *userLoginURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=ios_login&email=%@&code=%@", [properties objectForKey:@"server_json"], email, [Shared md5:key]];
	//NSString *stringData = [Shared stringWithContentsOfURL:userLoginURL ignoreCache:YES];
	
	//NSString *userLoginURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=ios_login", [properties objectForKey:@"server_json"]];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *post = [NSString stringWithFormat:@"token=%@", [defaults objectForKey:@"FBAccessTokenKey"]];
	NSString *stringData = [Shared stringWithContentsOfPostURL:userLoginURL post:post];
	
	CCLOG(@"ios_login result: %@ (%@)", stringData, post);
	
	if ([stringData isEqualToString:@"success"]) {
		userName = [[result objectForKey:@"name"] retain];
		[self setupMyGamesHeader];
		[Loader showAsynchronousLoaderWithDelayedAction:0.1f target:self selector:@selector(displayMyGames)];
		
	} else {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Facebook Connect" 
								message: @"There was a problem with your request" 
								delegate: self 
								cancelButtonTitle: @"Ok" 
								otherButtonTitles: nil] autorelease];
		[alertView show];
		[Loader hideAsynchronousLoader];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if([title isEqualToString:@"Ok"])
    {
		[self fbLogout:nil];
    }
}

#pragma mark -
#pragma mark More

-(void) loadMore {
	if (selectedPage == more) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = more;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadMore)];
	loading = YES;
}

-(void) _loadMore {
	[Loader hideAsynchronousLoader];
	
	loading = NO;
	more.visible = YES;
}

#pragma mark -
#pragma mark SWTableView

-(NSUInteger)numberOfCellsInTableView:(SWTableView *)table {
    return total != loaded ? loaded+1 : loaded;
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
			CCSprite *back = [CCSprite spriteWithFile:@"light-row.png"];
			back.anchorPoint = CGPointZero;
			
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
			CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
			backSelected.anchorPoint = CGPointZero;
			backSelected.visible = NO;
			
			int load = 25;
			if (load > total - loaded) load = total - loaded;
			
			CCLabelFX *label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"Load %i more games...", load] dimensions:CGSizeMake(200,16) alignment:CCTextAlignmentLeft fontName:@"HelveticaNeue-Bold" fontSize:16
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
			
			CCSprite *back = (CCSprite*)[cell getChildByTag:1];
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
			if (cell.levelId > 0) {
				[cell removeChildByTag:4 cleanup:YES];
			}
			
			CCLabelFX *label = (CCLabelFX*)[cell getChildByTag:3];
			
			int load = 25;
			if (load > total - loaded) load = total - loaded;
			[label setString:[NSString stringWithFormat:@"Load %i more games...", load]];
			
			CCLabelFX *title = (CCLabelFX*)[cell getChildByTag:5];
			[title setString:@""];
			
			cell.index = idx;
			cell.levelId = 0;
		}
		
		return cell;
		
	} else {
		
		NSDictionary *levelData = [tableData objectAtIndex:idx];
		NSString *title = [levelData objectForKey:@"title"];
		NSString *background = [levelData objectForKey:@"background"];
		int levelId = [[levelData objectForKey:@"id"] intValue];
		//CCLOG(@"Level '%@'", title);
		
		GameCell *cell = (GameCell *)[table dequeueCell];
		if (!cell) {
			cell = [[GameCell new] autorelease];
			cell.index = idx;
			cell.levelId = levelId;
			cell.data = levelData;
			
			//CCLOG(@"Add cell: %i, %i", idx, levelId);
			
			// Button row
			CCSprite *back = [CCSprite spriteWithFile:@"light-row.png"];
			back.anchorPoint = CGPointZero;
			
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
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
			
			NSString *author = [levelData objectForKey:@"author"];
			if ((author == nil) || [author isMemberOfClass:[NSNull class]]) {
				if (selectedPage == myGames) author = [levelData objectForKey:@"published_date"]; //author = userName;
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
				//CCSprite *original = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
				//CCSprite *original = [CCSprite spriteWithFile:@"back0_thumb.jpg"];
				NSArray *values = [background componentsSeparatedByString:@"/"];
				//CCLOG(@"Thumb: %@", [values lastObject]);
				CCSprite *original = [CCSprite spriteWithFile:[values lastObject]];
				
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
				
				CCSprite *back = (CCSprite*)[cell getChildByTag:1];
				if (idx%2 == 0) back.opacity = 255;
				else back.opacity = 128;
				
				if ((cell.levelId > 0) || (cell.levelId == -1)) {
					[cell removeChildByTag:4 cleanup:YES];
				}
				
				CCSprite *bg;
				if ((background != nil) && ![background isEqualToString:@""]) {
					//CCLOG(@"Thumb: %@", background);
					//CCSprite *original = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
					//CCSprite *original = [CCSprite spriteWithFile:@"back0_thumb.jpg"];
					NSArray *values = [background componentsSeparatedByString:@"/"];
					//CCLOG(@"Thumb: %@", [values lastObject]);
					CCSprite *original = [CCSprite spriteWithFile:[values lastObject]];
					
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
					NSString *author = [levelData objectForKey:@"author"];
					if ((author == nil) || [author isMemberOfClass:[NSNull class]]) {
						if (selectedPage == myGames) author = [levelData objectForKey:@"published_date"]; //author = userName;
						else author = @"";
					}
					[title setString:author];
					
				} else {
					[title setString:@""];
				}
				
				cell.index = idx;
				cell.levelId = levelId;
				cell.data = levelData;
			}
		}
		
		return cell;
	}
}

-(void)table:(SWTableView *)table cellTouched:(SWTableViewCell *)cell {
    //CCLOG(@"cell touched at index: %i", cell.idx);
	
	CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
	id action = [CCSequence actions:
				 [CCDelayTime actionWithDuration:0.2],
				 [CCShow action],
				 nil];
	[backSelected runAction:action];
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
		
		if (deleteMenu != nil) {
			[deleteMenu.parent removeChild:deleteMenu cleanup:YES];
		}
		
		CCMenuItemSprite *deleteButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"delete_btn.png"] selectedSprite:[CCSprite spriteWithFile:@"delete_btn.png"] target:self selector:@selector(deleteItem:)];
		deleteMenu = [CCMenu menuWithItems:deleteButton, nil];
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		if (CC_CONTENT_SCALE_FACTOR() == 2) [deleteMenu setPosition:ccp(size.width - deleteButton.contentSize.width/2 - 10, (58*2) - (58/2))];
		else [deleteMenu setPosition:ccp(size.width - deleteButton.contentSize.width/2 - 10, 58/2)];
		[cell addChild:deleteMenu z:10 tag:10];
		
		return;
	}
}

-(void)deleteItem:(id)sender {
	CCMenuItemSprite *button = (CCMenuItemSprite *)sender;
	GameCell *cell = (GameCell *)button.parent.parent;
	
	for (uint i = 0; i < [jsonDataPlaying count]; i++) {
		NSDictionary *levelData = [jsonDataPlaying objectAtIndex:i];
		int levelId = [[levelData objectForKey:@"id"] intValue];
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

-(void)scrollViewDidScroll:(SWScrollView *)view {
	if (deleteMenu != nil) {
		[deleteMenu.parent removeChild:deleteMenu cleanup:YES];
		deleteMenu = nil;
	}
}

-(void)scrollViewDidZoom:(SWScrollView *)view {
	
}

-(void)table:(SWTableView *)table cellTouchReleased:(SWTableViewCell *)cell {
    //CCLOG(@"cell touch released at index: %i", cell.idx);
	
	CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
	//[backSelected stopAllActions];
	//backSelected.visible = NO;
	
	if (deleteMenu != nil) {
		[deleteMenu.parent removeChild:deleteMenu cleanup:YES];
	}
	
	GameCell *selected = (GameCell *)cell;
	if (selected.levelId > 0) {
		// Load level
		
		//CCLOG(@"Selected Level: %i", selected.levelId);
		[Shared setLevel:selected.levelId];
		[Shared setLevelDate:[selected.data objectForKey:@"published_date"]];
		
		// Add level to favourites
		for (uint i = 0; i < [jsonDataPlaying count]; i++) {
			NSDictionary *levelData = [jsonDataPlaying objectAtIndex:i];
			int levelId = [[levelData objectForKey:@"id"] intValue];
			if (levelId == selected.levelId) {
				[jsonDataPlaying removeObjectAtIndex:i];
				break;
			}
		}
		
		NSMutableDictionary *data = [selected.data mutableCopy];
		NSString *author = [data objectForKey:@"author"];
		//CCLOG(@">>>>>> %@, %@", author, [author class]);
		if ([author isMemberOfClass:[NSNull class]]) {
			[data setObject:userName forKey:@"author"];
		}
		
		[jsonDataPlaying insertObject:data atIndex:0];
		//CCLOG(@"Add favourite: %@", [selected.data description]);
		
		//CCLOG(@"Favourites: %@", [jsonDataPlaying description]);
		
		id action = [CCSequence actions:
					 [CCDelayTime actionWithDuration:0.2],
					 [CCCallFunc actionWithTarget:self selector:@selector(selectedLevel:)],
					 nil];
		[backSelected runAction:action];
		
		//[[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
	
	/*
	} else if (selected.levelId == -1) {
		// Clear results
		backSelected.visible = NO;
		
		if (selectedPage == playing) {
			[jsonDataPlaying removeAllObjects];
			
			NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
			[prefs setObject:jsonDataPlaying forKey:@"favourites"];
			[prefs synchronize];
			
			playing = nil;
			
			[self loadPlaying];
			[self updatePlayedBadge];
		}
	*/
	
	} else {
		// Load more
		backSelected.visible = NO;
		
		int load = 25;
		if (load > total - loaded) load = total - loaded;
		loaded += load;
		
		int scroll = load;
		if (scroll < 25) scroll--;
		
		[tableView reloadData];
		[tableView setContentOffset:ccp(0,[tableView contentOffset].y-backSelected.contentSize.height*(scroll)) animated:NO];
	}
}

-(CGSize)cellSizeForTable:(SWTableView *)table {
	CGSize size = [[CCDirector sharedDirector] winSize];
    return CGSizeMake(size.width, 57);
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
