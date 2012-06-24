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

#import "ZipFile.h"
#import "ZipException.h"
#import "FileInZipInfo.h"
//#import "ZipWriteStream.h"
#import "ZipReadStream.h"


@implementation AppDelegate

@synthesize window;
@synthesize facebook;
@synthesize viewController;

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


// check for our built in game resources in the cache and unzip if required
void EnsureCachedResourcesExist()
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *appDir = [[NSBundle mainBundle] resourcePath];
    NSString *filePath= [appDir stringByAppendingPathComponent:@"CachedGames.zip"];
    ZipFile *zipFile= [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(SAVE_FOLDER, NSUserDomainMask, YES);
	NSString *cacheDirectory = [paths objectAtIndex:0];

    int nFiles = [zipFile numFilesInZip];
    for (int i=0; i<nFiles; ++i){
        if (i == 0){
            [zipFile goToFirstFileInZip];
        } else {
            [zipFile goToNextFileInZip];
        }
        FileInZipInfo *info = [zipFile getCurrentFileInZipInfo];
        NSString *fileInCache = [cacheDirectory stringByAppendingPathComponent:info.name]; 
        CCLOG(@"- %@ %d %@\n", info.name, info.size, fileInCache);
        
        if ([fileManager fileExistsAtPath:fileInCache]){
            NSDictionary *attr = [fileManager attributesOfItemAtPath:fileInCache error:NULL];
            CCLOG(@"FIle exists, skipping %@ vs %@\n", [attr valueForKey:NSFileModificationDate], info.date);
            continue;
        }
        
        // TODO should read in a loop, in case it can't read all?
        ZipReadStream *read = [zipFile readCurrentFileInZip];
        NSData *data = [read readDataOfLength:info.size];
        [read finishedReading];
        [data writeToFile:fileInCache atomically:YES];
        NSDictionary *attr = [[fileManager attributesOfItemAtPath:fileInCache error:NULL] mutableCopy];
        NSDate *fileDate = info.date;
        [attr setValue:fileDate forKey:NSFileModificationDate];
        [fileManager setAttributes:attr ofItemAtPath:fileInCache error:NULL];
    }

    [zipFile close];
    [zipFile release];
}


- (void) applicationDidFinishLaunching:(UIApplication*)application
{
    EnsureCachedResourcesExist();
    
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
    
    [director setDisplayFPS:NO];

	
	// make the OpenGLView a child of the view controller
	[viewController setView:glView];
    
    // init iAd banner REMOVED FOR RELEASE 1!
    //[viewController createBannerView];
	
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
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"custom_menu.plist"];
	[[GB2ShapeCache sharedShapeCache] addShapesWithFile:@"shapes.plist"];
	
	// Init audio
	[[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Check Point - Harp.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Death.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Enemy Damage.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Hero Damage.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Jetpack.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Speech and speech page changes.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Star and gem.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Switches 2.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Transporter.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Ammo.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Coin.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Food items.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Change weapon.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Lasergun.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Machine Gun single shot.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Machine gun.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Pistol.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Rocket launcher boom.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Rocket launcher launch.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Shotgun.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"W Sword swoosh.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Story point page turn.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"IG Story point.caf"];
    
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
