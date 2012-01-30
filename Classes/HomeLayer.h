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

@interface HomeLayer : CCLayerColor <
	SWTableViewDataSource, 
	SWTableViewDelegate, 
	SWScrollViewDelegate,
	UITextFieldDelegate,
	FBSessionDelegate,
	FBRequestDelegate,
	UIAlertViewDelegate
> {
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
	NSMutableArray *tableData;
	NSArray *filteredArray;
	
	// Browse
	CCUIViewWrapper *searchField;
	UITextField *searchTextField;
	
	CCSprite *badgeMiddle;
	CCSprite *badgeRight;
	CCLabelTTF *playingLabel;
	
	BOOL loading;
	
	NSString *userName;
	
	CCMenu *deleteMenu;
    
    // Async connection
    NSURLConnection *conn;
	NSMutableData *receivedData;
	BOOL connecting;
	
}

// returns a CCScene that contains the HomeLayer as the only child
+(CCScene *) scene;

-(void) loadFeatured;
-(void) _loadFeatured;
-(void) loadPlaying;
-(void) _loadPlaying;
-(void) loadBrowse;
-(void) _loadBrowse;
-(void) loadMyGames;
-(void) _loadMyGames;
-(void) loadMore;
-(void) updatePlayedBadge;
-(void) setupMyGamesHeader;

@end
