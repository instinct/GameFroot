//
//  RootViewController.h
//  GameFroot
//
//  Created by Jose Miguel on 01/02/2012.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>


@interface RootViewController : UIViewController <ADBannerViewDelegate> {
    ADBannerView *adBannerView;
}

- (void) createBannerView;
- (void) showBanner;
- (void) hideBanner;


@end
