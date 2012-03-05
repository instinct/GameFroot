//
//  AppDelegate.h
//  GameFroot
//
//  Created by Jose Miguel on 01/02/2012.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, FBSessionDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
	
	Facebook *facebook;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, readonly) RootViewController *viewController;

@end
