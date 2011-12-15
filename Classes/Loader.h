//
//  Loader.h
//  isoEngine
//
//  Created by Jose Miguel on 28/12/2009.
//  Copyright 2009 ITL Business Ltd. All rights reserved.
//

#import "cocos2d.h"

@interface Loader : NSObject {
	
}


+(void) showAsynchronousLoader;
+(void) hideAsynchronousLoader;
+(void) showAsynchronousLoaderWithDelayedAction:(float)delay target:(id)target selector:(SEL)func;

/*
+(void) openWebView: (NSString *)url;
+(void) rotateWebView;
-(void) checkWebLoaded: (ccTime) delta;
+(void) closeWebView;
*/

@end
