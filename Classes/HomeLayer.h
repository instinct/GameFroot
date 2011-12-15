//
//  HomeLayer.h
//  DoubleHappy
//
//  Created by Jose Miguel on 01/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "SWTableView.h"
#import "CCUIViewWrapper.h"
#import "FBConnect.h"

@interface HomeLayer : CCLayerColor <SWTableViewDataSource, SWTableViewDelegate, UITextFieldDelegate, FBSessionDelegate> {
	// Properties
	NSDictionary *properties;
	
	// Containers
	CCNode *featured;
	CCNode *playing;
	CCNode *browse;
	CCNode *myGames;
	CCNode *more;
	CCNode *selectedPage;
	
	// Cached data
	NSArray *jsonDataFeatured;
	NSArray *jsonDataBrowse;
	NSArray *jsonDataMyGames;
	NSMutableArray *jsonDataPlaying;
	
	// Tab menu
	CCMenuItemSprite *featuredButton;
	CCMenuItemSprite *playingButton;
	CCMenuItemSprite *browseButton;
	CCMenuItemSprite *myGamesButton;
	CCMenuItemSprite *moreButton;
	
	// Table view
	SWTableView *tableView;
	int loaded;
	int total;
	NSArray *tableData;
	NSArray *filteredArray;
	
	// Browse
	CCUIViewWrapper *searchField;
	UITextField *searchTextField;
	
}

// returns a CCScene that contains the HomeLayer as the only child
+(CCScene *) scene;

-(void) loadFeatured;
-(void) loadPlaying;
-(void) loadBrowse;
-(void) loadMyGames;
-(void) loadMore;

@end
