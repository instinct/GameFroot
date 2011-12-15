//
//  GameFrootAppDelegate.h
//  DoubleHappy
//
//  Created by Jose Miguel on 08/09/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class RootViewController;

@interface GameFrootAppDelegate : NSObject <UIApplicationDelegate, FBSessionDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
	
	Facebook *facebook;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) Facebook *facebook;

@end
