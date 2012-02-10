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
	UITextFieldDelegate,
	FBSessionDelegate,
	FBRequestDelegate,
	UIAlertViewDelegate
> {
	// Properties
	NSDictionary *properties;
	
	// Containers
    CCNode *welcome;
    CCNode *gameDetail;
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
	
    // Scroll view (Game detail)
    SWScrollView *gameDetailSV;
    
	// Table view
	SWTableView *tableView;
	int loaded;
	int total;
	NSMutableArray *tableData;
	NSArray *filteredArray;
	
	// Browse
	CCUIViewWrapper *searchField;
	UITextField *searchTextField;
	
    // Playing
	CCSprite *badgeMiddle;
	CCSprite *badgeRight;
	CCLabelTTF *playingLabel;
	CCMenu *deleteMenu;
    BOOL displayingDeleteButton;
    
	// My games
	NSString *userName;
    
    // Async connection
    NSURLConnection *conn;
	NSMutableData *receivedData;
	BOOL connecting;
    BOOL loading;
    BOOL ratingsAnchorEnabled;
}

// returns a CCScene that contains the HomeLayer as the only child
+(CCScene *) scene;

-(void) loadWelcome;
-(void) loadGameDetail;
-(void) loadFeatured;
-(void) loadPlaying;
-(void) loadBrowse;
-(void) loadMyGames;
-(void) loadMore;
-(void) updatePlayedBadge;
-(void) setupMyGamesHeader;

@end
