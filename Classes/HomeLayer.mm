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
//#import "SWScrollView.h"
#import "GameCell.h"
#import "SWTableViewCell.h"
#import "CCLabelBMFontMultiline.h"
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
			
		NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
		properties = [[[NSDictionary alloc] initWithContentsOfFile:plistPath] retain];
		
		//
		CCSprite *top = [CCSprite spriteWithFile:@"top-bar.png"];
		[top setPosition:ccp(size.width/2, size.height - top.contentSize.height/2)];
		[self addChild:top z:1];
		
		CCSprite *logo1 = [CCSprite spriteWithFile:@"gamefroot.png"];
		[[logo1 texture] setAntiAliasTexParameters];
		[logo1 setPosition:ccp(size.width/2 + 20, size.height - logo1.contentSize.height + 2)];
		[self addChild:logo1 z:2];
		
		CCSprite *logo2 = [CCSprite spriteWithFile:@"fruit.png"];
		[[logo2 texture] setAntiAliasTexParameters];
		[logo2 setPosition:ccp(logo1.position.x - logo1.contentSize.width/2 - logo2.contentSize.width/2 - 20, logo1.position.y)];
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
		
		OnPressMenu *menuBottom = [OnPressMenu menuWithItems:featuredButton, playingButton, browseButton, myGamesButton, moreButton, nil];
		menuBottom.position = ccp(size.width/2, bottom.contentSize.height/2 - 1);
		[menuBottom alignItemsHorizontallyWithPadding:2];
		[self addChild:menuBottom z:11];
		[featuredButton selected];
		
		// Init variables
		jsonDataFeatured = nil;
		jsonDataBrowse = nil;
		jsonDataMyGames = nil;
		
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
		
		// Load featured panel
		[self loadFeatured];
	}
	
	return self;
}

#pragma mark -
#pragma mark Event handlers

/*
 -(void) selectedLevel:(CCMenuItemSprite *)sender {
 NSString *value = (NSString *)sender.userData;
 CCLOG(@"HomeLayer.selectedLevel: %i", [value intValue]);
 [Shared setLevel:[value intValue]];
 
 [[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
 }
 */

// Selected featured buttons
-(void) featured1:(id)sender {
	
}

-(void) featured2:(id)sender {
	
}

// Main navigation
-(void) featured:(id)sender {
	[featuredButton selected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton unselected];
	
	[self loadFeatured];
}

-(void) playing:(id)sender {
	[featuredButton unselected];
	[playingButton selected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton unselected];
	
	[self loadPlaying];
}

-(void) browse:(id)sender {
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton selected];
	[myGamesButton unselected];
	[moreButton unselected];
	
	[self loadBrowse];
}

-(void) myGames:(id)sender {
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton selected];
	[moreButton unselected];
	
	[self loadMyGames];
}

-(void) more:(id)sender {
	[featuredButton unselected];
	[playingButton unselected];
	[browseButton unselected];
	[myGamesButton unselected];
	[moreButton selected];
	
	[self loadMore];
}

#pragma mark -
#pragma mark Featured

-(void) loadFeatured {
	if (selectedPage == featured) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = featured;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadFeatured)];
}

-(void) _loadFeatured {
	
	[Loader hideAsynchronousLoader];
	
	if (jsonDataFeatured == nil) {
				
		NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_all_levels", [properties objectForKey:@"server_json"]];
		CCLOG(@"Load levels: %@",levelsURL);
		
		NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
		NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
		jsonDataFeatured = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
		//CCLOG(@"Levels: %@", [jsonData description]);
		
		if(!jsonDataFeatured)
		{
			return;
		}
	}
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	// Featured panel
	CCMenuItemSprite *featured1Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"young-isaac-icon.png"] selectedSprite:[CCSprite spriteWithFile:@"young-isaac-icon.png"] target:self selector:@selector(featured1:)];
	CCMenuItemSprite *featured2Button = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"feature-icon.png"] selectedSprite:[CCSprite spriteWithFile:@"feature-icon.png"] target:self selector:@selector(featured2:)];		
	CCMenu *menuFeatured = [CCMenu menuWithItems:featured1Button, featured2Button, nil];
	menuFeatured.position = ccp(size.width/2, size.height - 44 - featured1Button.contentSize.height/2 - 5);
	[menuFeatured alignItemsHorizontally];
	[featured addChild:menuFeatured z:4];
	
	// Featured list
	
	/*
	CCLayerColor *layer = [CCLayerColor layerWithColor:ccc4(49, 49, 49, 255)];
	SWScrollView *scrollView = [SWScrollView viewWithViewSize:CGSizeZero];
	scrollView.position = ccp(0, 50);
	scrollView.maxZoomScale = 1.0f;
	scrollView.minZoomScale = 1.0f;
	scrollView.bounces = YES;
	scrollView.direction = SWScrollViewDirectionVertical;
	
	for (uint i=0; i<[jsonDataFeatured count]; i++) {
		NSDictionary *levelData = [jsonDataFeatured objectAtIndex:i];
		
		NSString *title = [levelData objectForKey:@"title"];
		NSString *background = [levelData objectForKey:@"background"];
		int levelId = [[levelData objectForKey:@"id"] intValue];
		//CCLOG(@"Level '%@'", title);
		
		// Button row
		CCSprite *back;
		if (i%2 == 0) back = [CCSprite spriteWithFile:@"dark-row.png"];
		else back = [CCSprite spriteWithFile:@"light-row.png"];
		
		if (i == 0) {
			scrollView.contentSize = CGSizeMake(back.contentSize.width, back.contentSize.height*[jsonDataFeatured count]);	
			scrollView.viewSize = CGSizeMake(back.contentSize.width, 280);
			layer.contentSize = scrollView.contentSize;
			[scrollView addChild:layer];
		}
		
		CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:title fntFile:@"Chicago.fnt" width:200 alignment:LeftAlignment];
		[label.textureAtlas.texture setAliasTexParameters];
		
		if (label.contentSize.width > 200) [label setPosition: ccp(label.contentSize.width/2 + 100, back.contentSize.height/2 + label.contentSize.height/2 - 10)]; // Quick nasty hack
		else [label setPosition: ccp(label.contentSize.width/2 + 100, back.contentSize.height/2)];
		//CCLOG(@"%f,%f", label.contentSize.width, label.contentSize.height);
		
		CCSprite *bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
		bg.scale = 0.6;
		[bg setPosition:ccp((16 + bg.contentSize.width*0.6)/2, back.contentSize.height/2)];
		
		[back addChild:label z:1];
		[back addChild:bg z:2];
		
		// Button selected row
		CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
		
		CCLabelBMFontMultiline *labelSelected = [CCLabelBMFontMultiline labelWithString:title fntFile:@"Chicago.fnt" width:200 alignment:LeftAlignment];
		[labelSelected.textureAtlas.texture setAliasTexParameters];
		[labelSelected setPosition: ccp(labelSelected.contentSize.width/2 + 100, backSelected.contentSize.height/2)];
		
		CCSprite *bgSelected = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
		bgSelected.scale = 0.6;
		[bgSelected setPosition:ccp((16 + bgSelected.contentSize.width*0.6)/2, backSelected.contentSize.height/2)];
		
		[backSelected addChild:labelSelected z:1];
		[backSelected addChild:bgSelected z:2];
		
		CCMenuItemSprite *button = [CCMenuItemSprite itemFromNormalSprite:back selectedSprite:backSelected target:self selector:@selector(selectedLevel:)];
		button.anchorPoint = CGPointZero;
		button.userData = [[NSString stringWithFormat:@"%i",levelId] retain];
		
		FilteredMenu *menu = [FilteredMenu menuWithItems:button, nil];
		menu.anchorPoint = CGPointZero;
		[scrollView addChild:menu];
		[menu setPosition:ccp(0, (back.contentSize.height*[jsonDataFeatured count]) - back.contentSize.height*(i+1))];
		
		if (i == [jsonDataFeatured count]-1) {
			[scrollView setContentOffset:ccp(0,280-back.contentSize.height*([jsonDataFeatured count])) animated:NO];
		}
		
	}
	
	[featured addChild:scrollView z:5];
	*/
	
	
	tableData = jsonDataFeatured;
	
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
	
}

#pragma mark -
#pragma mark Playing

-(void) loadPlaying {
	if (selectedPage == playing) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = playing;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadPlaying)];
}

-(void) _loadPlaying {
	[Loader hideAsynchronousLoader];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	tableData = [[prefs objectForKey:@"favourites"] mutableCopy];
	if (!tableData) return;
	
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
}

#pragma mark -
#pragma mark Browse

-(void) loadBrowse {
	if (selectedPage == browse) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = browse;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadBrowse)];
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
	searchField.position = ccp(size.width/2,size.height - 50 - 18);
	[browse addChild:searchField z:7];
	
	CCMenuItemSprite *clearButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"clear-search.png"] selectedSprite:[CCSprite spriteWithFile:@"clear-search.png"] target:self selector:@selector(clearSearch:)];
	CCMenu *menu = [CCMenu menuWithItems:clearButton, nil];
	menu.position = ccp(size.width - clearButton.contentSize.width - 5, searchBox.position.y);
	[browse addChild:menu z:8];
}

-(void) reloadBrowse {
	[browse removeChild:tableView cleanup:YES];
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_reloadBrowse)];
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
	
	tableData = filteredArray;
	
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
}

-(void) displayMyGames {
	[Loader hideAsynchronousLoader];
	
	if (jsonDataMyGames != nil) [jsonDataMyGames release];
	
	NSString *levelsURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_user_levels", [properties objectForKey:@"server_json"]];
	CCLOG(@"Load levels: %@",levelsURL);
	
	NSString *stringData = [Shared stringWithContentsOfURL:levelsURL ignoreCache:YES];
	NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
	jsonDataMyGames = [[[CJSONDeserializer deserializer] deserializeAsArray:rawData error:nil] retain];
	//CCLOG(@"Levels: %@", [jsonDataMyGames description]);
	
	if(!jsonDataMyGames)
	{
		return;
	}
	
	tableData = jsonDataMyGames;
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	CCMenuItemSprite *logoutButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"LogoutNormal.png"] selectedSprite:[CCSprite spriteWithFile:@"LogoutPressed.png"] target:self selector:@selector(fbLogout:)];
	CCMenu *menu = [CCMenu menuWithItems:logoutButton, nil];
	menu.position = ccp(size.width - logoutButton.contentSize.width/2 - 5, size.height - 45 - logoutButton.contentSize.height/2 - 8);
	[myGames addChild:menu z:2];
	
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
}

-(void) _loadMyGames {
	[Loader hideAsynchronousLoader];
	
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	
	if (![[app facebook] isSessionValid]) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		CCMenuItemSprite *loginButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"LoginNormal.png"] selectedSprite:[CCSprite spriteWithFile:@"LoginPressed.png"] target:self selector:@selector(fbLogin:)];
		CCMenu *menu = [CCMenu menuWithItems:loginButton, nil];
		menu.position = ccp(size.width - loginButton.contentSize.width/2 - 5, size.height - 45 - loginButton.contentSize.height/2 - 8);
		[myGames addChild:menu z:1 tag:100];
		
	} else {
		//CCLOG(@">>>>>>>>>>>> Facebook Connect already connected");
		
		[self displayMyGames];	
	}
}

-(void) fbLogin:(id)sender {
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	[app facebook].sessionDelegate = self;
	[[app facebook] authorize:nil];
}

-(void) fbLogout:(id)sender {
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	[[app facebook] logout:self];
}

-(void) fbDidLogin {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging succesful");
	
	GameFrootAppDelegate *app = (GameFrootAppDelegate *)[UIApplication sharedApplication].delegate;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[app facebook] accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[[app facebook] expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
	
	[myGames removeChildByTag:100 cleanup:YES]; // remove login button
	
	[Loader showAsynchronousLoaderWithDelayedAction:0.1f target:self selector:@selector(displayMyGames)];
}

-(void) fbDidNotLogin:(BOOL)cancelled {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect logging unsuccesful");
}

-(void) fbDidLogout {
	//CCLOG(@">>>>>>>>>>>> Facebook Connect loggout succesful");
	
	// Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
	
	[self featured:nil];
}

#pragma mark -
#pragma mark More

-(void) loadMore {
	if (selectedPage == more) return;
	if (selectedPage != nil) [selectedPage removeAllChildrenWithCleanup:YES];
	selectedPage = more;
	[Loader showAsynchronousLoaderWithDelayedAction:0.5f target:self selector:@selector(_loadMore)];
}

-(void) _loadMore {
	[Loader hideAsynchronousLoader];
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
			
			//if (idx%2 == 0) back = [CCSprite spriteWithFile:@"dark-row.png"];
			//else back = [CCSprite spriteWithFile:@"light-row.png"];
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
			CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
			backSelected.anchorPoint = CGPointZero;
			backSelected.visible = NO;
			
			int load = 25;
			if (load > total - loaded) load = total - loaded;
			CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:[NSString stringWithFormat:@"Load %i more...", load] fntFile:@"Chicago.fnt" width:200 alignment:LeftAlignment];
			[label.textureAtlas.texture setAliasTexParameters];
			label.anchorPoint = ccp(0,0.5);
			[label setPosition: ccp(100, back.contentSize.height/2)];
			
			[cell addChild:back z:1 tag:1];
			[cell addChild:backSelected z:2 tag:2];
			[cell addChild:label z:3 tag:3];
			
		} else {
			//CCLOG(@"Replace more cell: %i, %i (%i, %i)", idx, 0, cell.index, cell.levelId);
			
			CCSprite *back = (CCSprite*)[cell getChildByTag:1];
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
			if (cell.levelId > 0) {
				[cell removeChildByTag:4 cleanup:YES];
			}
			
			CCLabelBMFontMultiline *label = (CCLabelBMFontMultiline*)[cell getChildByTag:3];
			
			int load = 25;
			if (load > total - loaded) load = total - loaded;
			[label setString:[NSString stringWithFormat:@"Load %i more...", load]];
			
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
			
			//if (idx%2 == 0) back = [CCSprite spriteWithFile:@"dark-row.png"];
			//else back = [CCSprite spriteWithFile:@"light-row.png"];
			if (idx%2 == 0) back.opacity = 255;
			else back.opacity = 128;
			
			CCSprite *backSelected = [CCSprite spriteWithFile:@"selected-row.png"];
			backSelected.anchorPoint = CGPointZero;
			backSelected.visible = NO;
			
			CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:title fntFile:@"Chicago.fnt" width:200 alignment:LeftAlignment];
			[label.textureAtlas.texture setAliasTexParameters];
			label.anchorPoint = ccp(0,0.5);
			
			if (label.contentSize.width > 200) [label setPosition: ccp(100, back.contentSize.height/2 + label.contentSize.height/2 - 10)]; // Quick nasty hack
			else [label setPosition: ccp(100, back.contentSize.height/2)];
			//CCLOG(@"%f,%f", label.contentSize.width, label.contentSize.height);
			
			CCSprite *bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
			bg.scale = 0.6;
			[bg setPosition:ccp((16 + bg.contentSize.width*0.6)/2, back.contentSize.height/2)];
			
			[cell addChild:back z:1 tag:1];
			[cell addChild:backSelected z:2 tag:2];
			[cell addChild:label z:3 tag:3];
			[cell addChild:bg z:4 tag:4];
			
		} else {
			
			if (cell.index != (int)idx) {
				//CCLOG(@"Replace cell: %i, %i (%i, %i)", idx, levelId, cell.index, cell.levelId);
				
				CCSprite *back = (CCSprite*)[cell getChildByTag:1];
				if (idx%2 == 0) back.opacity = 255;
				else back.opacity = 128;
				
				if (cell.levelId > 0) {
					[cell removeChildByTag:4 cleanup:YES];
				}
				
				CCSprite *bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
				bg.scale = 0.6;
				[bg setPosition:ccp((16 + bg.contentSize.width*0.6)/2, back.contentSize.height/2)];
				[cell addChild:bg z:4 tag:4];
				
				CCLabelBMFontMultiline *label = (CCLabelBMFontMultiline*)[cell getChildByTag:3];
				[label setString:title];
				
				if (label.contentSize.width > 200) [label setPosition: ccp(100, back.contentSize.height/2 + label.contentSize.height/2 - 10)]; // Quick nasty hack
				else [label setPosition: ccp(100, back.contentSize.height/2)];
				//CCLOG(@"%f,%f", label.contentSize.width, label.contentSize.height);
				
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

-(void)table:(SWTableView *)table cellTouchReleased:(SWTableViewCell *)cell {
    //CCLOG(@"cell touch released at index: %i", cell.idx);
	
	CCSprite *backSelected = (CCSprite*)[cell getChildByTag:2];
	[backSelected stopAllActions];
	backSelected.visible = NO;
	
	GameCell *selected = (GameCell *)cell;
	if (selected.levelId > 0) {
		// Load level
		
		//CCLOG(@"Selected Level: %i", selected.levelId);
		[Shared setLevel:selected.levelId];
		
		//Add level to favourites
		for (uint i = 0; i < [jsonDataPlaying count]; i++) {
			NSDictionary *levelData = [jsonDataPlaying objectAtIndex:i];
			int levelId = [[levelData objectForKey:@"id"] intValue];
			if (levelId == selected.levelId) {
				[jsonDataPlaying removeObjectAtIndex:i];
				break;
			}
		}
		[jsonDataPlaying insertObject:selected.data atIndex:0];
		//CCLOG(@"Add favourite: %@", [selected.data description]);
		
		//CCLOG(@"Favourites: %@", [favourites description]);
		
		[[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
		
	} else {
		// Load more
		
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
	
	[properties release];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
