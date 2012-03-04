//
//  AppDelegate.m
//  GameFroot
//
//  Created by Jose Miguel on 01/02/2012.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import "cocos2d.h"

#import "AppDelegate.h"
#import "SplashLayer.h"
#import "GameLayer.h"
#import "GameConfig.h"
#import "RootViewController.h"
#import "Shared.h"
#import "Loader.h"
#import "DeviceHardware.h"
#import "GB2ShapeCache.h"
#import "SimpleAudioEngine.h"

@implementation AppDelegate

@synthesize window;
@synthesize facebook;

- (void) removeStartupFlicker
{
	//
	// THIS CODE REMOVES THE STARTUP FLICKER
	//
	// Uncomment the following code if you Application only supports landscape mode
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
	
	//	CC_ENABLE_DEFAULT_GL_STATES();
	//	CCDirector *director = [CCDirector sharedDirector];
	//	CGSize size = [director winSize];
	//	CCSprite *sprite = [CCSprite spriteWithFile:@"Default.png"];
	//	sprite.position = ccp(size.width/2, size.height/2);
	//	sprite.rotation = -90;
	//	[sprite visit];
	//	[[director openGLView] swapBuffers];
	//	CC_ENABLE_DEFAULT_GL_STATES();
	
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController	
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
    // Detect device model
	DeviceHardware *hardware = [[[DeviceHardware alloc] init] autorelease];
	CCLOG(@"Device: %@", [hardware platformString]);
	[Shared setSimulator:[[hardware platformString] isEqualToString:@"Simulator"]];
    
    // Detect OS version
    [Shared detectOSVersion];
    
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //Add a firstlaunch flag so we can run different stuff on firstlaunch
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"firstlaunch", nil]];
    
	
	// Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
	
	
	CCDirector *director = [CCDirector sharedDirector];
	
	// Init the View Controller
	viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
	viewController.wantsFullScreenLayout = YES;
	
	//
	// Create the EAGLView manually
	//  1. Create a RGB565 format. Alternative: RGBA8
	//	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
	//
	//
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if( ! [director enableRetinaDisplay:YES] )
		CCLOG(@"Retina Display Not supported");
	
	//
	// VERY IMPORTANT:
	// If the rotation is going to be controlled by a UIViewController
	// then the device orientation should be "Portrait".
	//
	// IMPORTANT:
	// By default, this template only supports Landscape orientations.
	// Edit the RootViewController.m file to edit the supported orientations.
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];
#else
	//[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
#endif
	
	[director setAnimationInterval:1.0/60];
	[director setDisplayFPS:YES];

	
	// make the OpenGLView a child of the view controller
	[viewController setView:glView];
	
	// make the View Controller a child of the main window
	[window addSubview: viewController.view];
	
    // enable multitouch
	[glView setMultipleTouchEnabled:YES];
    
	[window makeKeyAndVisible];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    
	// Set 2D projection and disable depth test
	[[CCDirector sharedDirector] setProjection:CCDirectorProjection2D];
	[[CCDirector sharedDirector] setDepthTest:NO];

	
	// Removes the startup flicker
	[self removeStartupFlicker];
	
	// Init spritesheets
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"hud_spritesheet.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"controls.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"game_detail.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"pause_screen.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"main_menu.plist"];
	[[GB2ShapeCache sharedShapeCache] addShapesWithFile:@"shapes.plist"];
	
	// Init audio
	[[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"collect.caf"];
	
	// Run the intro Scene
	[[CCDirector sharedDirector] runWithScene: [SplashLayer scene]];
	
	// Init FB
	// For more info: https://developers.facebook.com/docs/mobile/ios/build/
	NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
	NSDictionary *properties = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
	facebook = [[Facebook alloc] initWithAppId:[properties objectForKey:@"fb_app_key"] andDelegate:self];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
	}
}


- (void)applicationWillResignActive:(UIApplication *)application 
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstlaunch"];
    
	if (![Shared isPaused])[[CCDirector sharedDirector] pause];
    if ([Shared isPlaying] && ![Shared isPaused]) [[GameLayer getInstance] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	//[[CCDirector sharedDirector] resume];
	
	// If we schedule the resume, we fix the issue of drop to 40fps on iOS4.X
	[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(resumeGame:) userInfo:nil repeats:NO];
}

-(void) resumeGame:(NSTimer *) sender 
{
	if (![Shared isPaused]) [[CCDirector sharedDirector] resume];
    if ([Shared isPlaying] && ![Shared isPaused]) [[GameLayer getInstance] resume];
}

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [facebook handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [facebook handleOpenURL:url]; 
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	CCDirector *director = [CCDirector sharedDirector];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstlaunch"];
	[[director openGLView] removeFromSuperview];
	[viewController release];
	[window release];
	[director end];	
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[CCDirector sharedDirector] end];
	[window release];
	[super dealloc];
}

@end
