//
//  Loader.m
//  isoEngine
//
//  Created by Jose Miguel on 28/12/2009.
//  Copyright 2009 ITL Business Ltd. All rights reserved.
//

#import "Loader.h"

static UIActivityIndicatorView *activityIndicator = nil;
//static UIWebView *webView;

@implementation Loader


+(void) showAsynchronousLoader {
	
	if (activityIndicator == nil) {
		CGSize size = [[CCDirector sharedDirector] winSize];	
		
		activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		//activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicator.frame = CGRectMake(size.width/2 - 20,size.height/2 - 20, activityIndicator.frame.size.width,activityIndicator.frame.size.height);
		activityIndicator.hidesWhenStopped = YES;
		[[[CCDirector sharedDirector] openGLView] addSubview:activityIndicator];
		
	}
	[activityIndicator startAnimating];
}

+(void) hideAsynchronousLoader {
		
	[activityIndicator stopAnimating];
}

+(void) showAsynchronousLoaderWithDelayedAction:(float)delay target:(id)target selector:(SEL)func {
	[Loader showAsynchronousLoader];
	
	[NSTimer scheduledTimerWithTimeInterval:delay target:target selector:func userInfo:nil repeats:NO];
}

/*
+(void) openWebView: (NSString *)_url {
	NSLog(@"Loader.openWebView");
	
	[[Director sharedDirector] pause];
	
	//CGRect webFrame = CGRectMake(8.0, 0.0, 480.0 - 16.0, 320.0 - 80.0 - 16.0);
	CGRect webFrame = CGRectMake(0.0, 0.0, 480.0, 320.0);
	webView = [[[UIWebView alloc] initWithFrame:webFrame] retain];
	webView.delegate = instance;
	[Loader rotateWebView];
	//webView.scalesPageToFit = YES;
	[webView setOpaque:NO];
	[webView setBackgroundColor:[UIColor grayColor]];
	
	NSString *urlAddress = _url;
	NSURL *url = [NSURL URLWithString:urlAddress];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url]; 
	[webView loadRequest:requestObj];
	
	[[[Director sharedDirector] openGLView] addSubview:webView];
	[[[Director sharedDirector] openGLView] sendSubviewToBack:webView];
	
	webView.alpha = 0.0;
	[UIView beginAnimations: @"fadeIn" context: nil];
	webView.alpha = 1.0;
	[UIView commitAnimations];
}

/ *
- (void)webViewDidStartLoad:(UIWebView *)webView {
	NSLog(@"Loader.webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	NSLog(@"Loader.webViewDidFinishLoad");
	[Loader hideAsynchronousLoader];
}
* /

-(void) checkWebLoaded: (ccTime) delta {
	if (webView.loading) {
		[NSTimer scheduledTimerWithTimeInterval:4.0f/fps target:instance selector:@selector(checkWebLoaded:) userInfo:nil repeats:NO];
		
	} else {
		NSLog(@"Loader.webViewDidFinishLoad");
		[Loader hideAsynchronousLoader];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	//NSLog(@"Loader.didFailLoadWithError: %@", error);
	
	/ *
	NSString *imagePath = [[NSBundle mainBundle] resourcePath];
	imagePath = [imagePath stringByReplacingOccurrencesOfString:@"/" withString:@"//"];
	imagePath = [imagePath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];	
	[webView loadHTMLString:@"<html><body><a href='http://itunes.apple.com/us/app/alone/id356286001?mt=8'><img src='Icon@2x.png' /></a></body></html>" baseURL:[NSURL URLWithString: [NSString stringWithFormat:@"file:/%@//",imagePath]]];
	
	[Loader showAsynchronousLoader];
	* /
	
	/ *
	[Loader closeWebView];
	MainMenu *layer = (MainMenu*)[(ExtendedMultiplexLayer*)[scene getChildByTag:4] getLayer: 0];
	[layer hideMenu];
	[layer openMessage:[Shared getMessage:@"SERVER_UNAVAILABLE"] title:[Shared getMessage:@"SORRY"]];
	* /
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
	NSLog(@"Loader.shouldStartLoadWithRequest: %@", urlString);
	
	// Manage events from web view to game controller
	
	NSRange range = [urlString rangeOfString:@"phobos.apple.com"];
	if (range.location != NSNotFound) {
		// Capture itunes link
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
		return NO;
		
	} else {
		
		if ([urlString isEqualToString:[NSString stringWithFormat:@"%@/games", urlServer]]) {
			// Open more games
			[Loader showAsynchronousLoader];
			[NSTimer scheduledTimerWithTimeInterval:4.0f/fps target:instance selector:@selector(checkWebLoaded:) userInfo:nil repeats:NO];
			[Loader initPlayHaven];
			return YES;
			
		} else if ([urlString isEqualToString:@"http://back/"]) {
			if ([webView canGoBack]) {
				[webView goBack];
				return NO;
			} else {
				[Loader closeWebView];
				return NO;
			}
			
		} else if ([urlString isEqualToString:@"http://playhaven/"]) {
			//[Loader closeWebView];
			[Loader openPlayHaven];
			return NO;
			
		} else {
			[Loader showAsynchronousLoader];
			[NSTimer scheduledTimerWithTimeInterval:4.0f/fps target:instance selector:@selector(checkWebLoaded:) userInfo:nil repeats:NO];
			return YES;
		}
	}
}

+(void) rotateWebView {
	float angle;
	AccelerometerLayer *currentLayer = (AccelerometerLayer*)[(ExtendedMultiplexLayer*)[scene getChildByTag:4] getActiveLayer];
	
	if ([[currentLayer class] getOrientation] == SET_RIGHT) {
		//[webView setCenter:CGPointMake(320-120, 240)];
		[webView setCenter:CGPointMake(160, 240)];
		angle = DEGREES_TO_RADIANS(-90);
	} else {
		//[webView setCenter:CGPointMake(120, 240)];
		[webView setCenter:CGPointMake(160, 240)];
		angle = DEGREES_TO_RADIANS(90);
	}
	
	CGAffineTransform cgCTM = CGAffineTransformMakeRotation(angle);
	webView.transform = cgCTM;
}

+(void) delayedCloseWebView {
	
}

+(void) closeWebView {
	NSLog(@"Loader.closeWebView");
	
	[Loader hideAsynchronousLoader];
	
	if (webView != nil) {
		if (webView.loading) [webView stopLoading];
		[UIView beginAnimations: @"fadeOut" context: nil];
		webView.alpha = 0.0;
		[UIView commitAnimations];
		[NSTimer scheduledTimerWithTimeInterval:4.0/fps target:instance selector:@selector(removeWebView:) userInfo:nil repeats:NO];
		
	} else {
		[[Director sharedDirector] resume];
	}
	
}

-(void) removeWebView: (ccTime) delta {
	NSLog(@"Loader.removeWebView");
	
	if (webView != nil) {
		if (webView.loading) [webView stopLoading];
		[webView removeFromSuperview];
		[webView release];
		webView = nil;
	}
	
	[[Director sharedDirector] resume];
	
}
*/


-(void) dealloc {
	[activityIndicator release];
	
	[super dealloc];
}

@end