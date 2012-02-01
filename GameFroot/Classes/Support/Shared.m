//
//  Shared.m
//  DoubleHappy
//
//  Created by Jose Gomez on 01/01/09.
//  Copyright 2008 ITL Business Ltd. All rights reserved.
//

#import "Shared.h"
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#include "Reachability.h"
#include "Constants.h"

@implementation Shared

static NSString *osVersion = @"";
static NSString *device = @"";

static NSString *levelDate = @"";
static int levelID;
static NSString *levelTitle = @"";

#pragma mark -
#pragma mark Generic functions

+(CGSize) getWinSize {
	return [[CCDirector sharedDirector] winSize];
}

+(NSString *) formattedStringUsingFormat:(NSString *)dateFormat
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    [formatter setCalendar:cal];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString *ret = [formatter stringFromDate:[NSDate date]];
    [formatter release];
    [cal release];
    return ret;
}

+(int) getLevel {
	return levelID;
}

+(void) setLevel: (int)_value {
	levelID = _value;
}

+(NSString *) getLevelDate {
	return levelDate;
}

+(void) setLevelDate: (NSString *)_value {
	levelDate = _value;
}

+(NSString *) getLevelTitle {
    return levelTitle;
}

+(void) setLevelTitle: (NSString *)_value {
    levelTitle = _value;
}

+(NSString *) getOSVersion {
	return osVersion;
}

+(void) detectOSVersion {
	// Get OS version
	osVersion = [[[UIDevice currentDevice] systemVersion] retain];
	CCLOG(@"OS version: %@", osVersion);
}

+(BOOL) isMultitaskingSupported {
	BOOL backgroundSupported = NO;
	
#ifdef OS3
	// ignore
#else
	UIDevice* device = [UIDevice currentDevice];
	if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
		backgroundSupported = device.multitaskingSupported;
	}
#endif
	
	return backgroundSupported;
}

+(NSString *) getDevice {
	return device;
}

+(void) setDevice: (NSString *)_value {
	device = _value;
}

+(BOOL) connectedToNetwork
{
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
	
	if(remoteHostStatus == NotReachable) return NO;
	else return TRUE;
}

+(NSString *) traceCGRect: (CGRect) rect {
	return [NSString stringWithFormat:@"%f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

+(void) drawCGRect: (CGRect) rect {
	const GLfloat lines[] = {
		rect.origin.x, rect.origin.y,
		rect.origin.x + rect.size.width, rect.origin.y,
		
		rect.origin.x + rect.size.width, rect.origin.y,
		rect.origin.x + rect.size.width, rect.origin.y - rect.size.height,
		
		rect.origin.x + rect.size.width, rect.origin.y - rect.size.height,
		rect.origin.x, rect.origin.y - rect.size.height,
		
		rect.origin.x, rect.origin.y - rect.size.height,
		rect.origin.x, rect.origin.y,
		
	};
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glLineWidth(0.1f);
	glColor4f(1.0f,1.0f,0.0f,1.0f); //line color
	glVertexPointer(2, GL_FLOAT, 0, lines);
	glDrawArrays(GL_LINES, 0, 8);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
}

+(void) drawTriangle: (CGRect) rect direction:(NSString *)direction {
	
	CGPoint *points = [Shared getTrianglePoints: rect direction:direction];
	const GLfloat lines[] = {
		points[0].x, points[0].y,
		points[1].x, points[1].y,
		
		points[1].x, points[1].y,
		points[2].x, points[2].y,
		
		points[2].x, points[2].y,
		points[0].x, points[0].y,
		
	};
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glLineWidth(0.1f);
	glColor4f(1.0f,1.0f,0.0f,1.0f); //line color
	glVertexPointer(2, GL_FLOAT, 0, lines);
	glDrawArrays(GL_LINES, 0, 6);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);	
	
}

CGFloat GBDot(const CGPoint v1, const CGPoint v2) {
	return v1.x*v2.x + v1.y*v2.y;
}

CGPoint GBSub(const CGPoint v1, const CGPoint v2) {
	return CGPointMake(v1.x - v2.x, v1.y - v2.y);
}

+(BOOL) pointInTriangle:(CGPoint) point pointA:(CGPoint) pointA pointB:(CGPoint) pointB pointC:(CGPoint) pointC {
	
	CGPoint v0 = GBSub(pointC, pointA);
	CGPoint v1 = GBSub(pointB, pointA);
	CGPoint v2 = GBSub(point, pointA);
	
	// Compute dot products
	CGFloat dot00 = GBDot(v0, v0);
	CGFloat dot01 = GBDot(v0, v1);
	CGFloat dot02 = GBDot(v0, v2);
	CGFloat dot11 = GBDot(v1, v1);
	CGFloat dot12 = GBDot(v1, v2);
	
	// Compute barycentric coordinates
	CGFloat invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
	CGFloat u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	CGFloat v = (dot00 * dot12 - dot01 * dot02) * invDenom;
	
	// Check if point is in triangle
	return (u > 0) && (v > 0) && (u + v < 1);
}

+(CGPoint *) getTrianglePoints: (CGRect) rect direction:(NSString *)direction {
	
	CGPoint *points = (CGPoint*)malloc(sizeof(CGPoint) * 3);
	
	if ([direction isEqualToString:@"north"]) {
		points[0] = CGPointMake(rect.origin.x, rect.origin.y);
		points[1] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
		points[2] = CGPointMake(rect.origin.x + (rect.size.width / 2), rect.origin.y - rect.size.height);
		
	} else if ([direction isEqualToString:@"south"]) {
		points[0] = CGPointMake(rect.origin.x + (rect.size.width / 2), rect.origin.y);
		points[1] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y - rect.size.height);
		points[2] = CGPointMake(rect.origin.x, rect.origin.y - rect.size.height);
		
	} else if ([direction isEqualToString:@"east"]) {
		points[0] = CGPointMake(rect.origin.x, rect.origin.y - (rect.size.height / 2));
		points[1] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
		points[2] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y - rect.size.height);
		
	} else if ([direction isEqualToString:@"west"]) {
		points[0] = CGPointMake(rect.origin.x, rect.origin.y);
		points[1] = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y - (rect.size.height / 2));
		points[2] = CGPointMake(rect.origin.x, rect.origin.y - rect.size.height);
		
	}
	
	return points;
}
	
+ (void) moveDocumentFilesToLibrary {
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// only run once kDidMoveSavedFiles
    if ([prefs integerForKey:@"movefiles"] < 1) {
        
		CCLOG(@"moving all /Document files to /Library");
		
        // documents folder
        NSArray *docFilePath = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES); 
        NSString *documentsDirectory = [docFilePath objectAtIndex: 0];
        
        // library folder
        NSArray *libFilePath = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES); 
        NSString *libraryDirectory = [libFilePath objectAtIndex: 0];
        
        // file manager
		BOOL success;
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *direnum = [fileManager enumeratorAtPath:documentsDirectory];
		NSString *pname;
		
		while ((pname = [direnum nextObject])) {
			NSString *orgFileName = [NSString stringWithFormat:@"%@/%@", documentsDirectory, pname];
			NSString *newFileName = [NSString stringWithFormat:@"%@/%@", libraryDirectory, pname];
			
			success = [fileManager moveItemAtPath:orgFileName toPath:newFileName error:&error];
			
			if (success) CCLOG(@"moved sucessfully %@ to %@", orgFileName, newFileName);
			else CCLOG(@"error moving %@ to %@", orgFileName, newFileName);
		}
		
        // now update NSUserDefaults so this will never run again
        [prefs setInteger:2 forKey:@"movefiles"];
    }    
}

+(BOOL) isEmpty:(id) object {
    return object == nil
	|| (object == [NSNull null])
	|| ([object respondsToSelector:@selector(length)]
        && [(NSData *) object length] == 0)
	|| ([object respondsToSelector:@selector(count)]
        && [(NSArray *) object count] == 0);
}

+(NSString *) decode: (NSString *)value {
	//CCLOG(@"Shared.decode: %@", value);
	if ([Shared isEmpty:value]) {
		return @"";
		
	} else {
		
		// START: Memory leak fixes
		NSString * decoded = [[[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"]; 
		// not sure we really need it here ???????? 
		//NSString * decoded = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
		//decoded = [decoded stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		//decoded = [decoded stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
		// END: Memory leak fixes
		
		//CCLOG(@"decoded: %@", decoded);
		return decoded;
	}
}

+(NSString*) md5: (NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, strlen(cStr), result );
	return [[NSString  stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], result[4],
			result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12],
			result[13], result[14], result[15]
			] lowercaseString];
}

+(NSString*) sha1: (NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1( cStr, strlen(cStr), result );
	return [[NSString  stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], result[4],
			result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12],
			result[13], result[14], result[15]
			] lowercaseString];
}

+(NSString*) replaceAccents:(NSString*)a { 
    //remove any accents and punctuation; 
    a=[[[NSString alloc] initWithData:[a 
							dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
							encoding:NSASCIIStringEncoding] autorelease]; 
    a=[a stringByReplacingOccurrencesOfString:@"\"" withString:@""]; 
    a=[a stringByReplacingOccurrencesOfString:@"'" withString:@""]; 
    a=[a stringByReplacingOccurrencesOfString:@"`" withString:@""]; 
    a=[a stringByReplacingOccurrencesOfString:@"-" withString:@""]; 
    a=[a stringByReplacingOccurrencesOfString:@"_" withString:@""]; 
    a=[a lowercaseString]; 
    return a; 
}

#pragma mark -
#pragma mark Remote Data Loading

+(NSString*)stringWithContentsOfPostURL:(NSString*)url post:(NSString *)post
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	NSData *requestBody = [post dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:requestBody];
	NSURLResponse *response = NULL;
	NSError *requestError = NULL;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
	NSString *responseString = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	return responseString;
}

+(NSString*)stringWithContentsOfURL:(NSString*)url ignoreCache:(BOOL)ignoreCache
{
	NSString *cachedFile = [Shared md5:url];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(SAVE_FOLDER, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *resource = [documentsDirectory stringByAppendingPathComponent:cachedFile];
	
	NSArray *urlValues = [url componentsSeparatedByString:@"/"];
	NSString *embeddedResource = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[urlValues lastObject]];
	BOOL embedded = [fileManager fileExistsAtPath:embeddedResource];
	//CCLOG(@"Shared.stringWithContentsOfURL (CHECK IF EMBEDDED): %@ exists %i", [urlValues lastObject], embedded);
	
	if (embedded && (!ignoreCache || ![Shared connectedToNetwork])) {
		NSString *data = [NSString stringWithContentsOfFile:embeddedResource encoding:NSASCIIStringEncoding error:nil];
		//CCLOG(@"Shared.stringWithContentsOfURL (EMBEDDED): %@", embeddedResource);
		return data;
		
	} else if ([fileManager fileExistsAtPath:resource] && (!ignoreCache || ![Shared connectedToNetwork])) {
		NSString *data = [NSString stringWithContentsOfFile:resource encoding:NSASCIIStringEncoding error:nil];
		//CCLOG(@"Shared.stringWithContentsOfURL (CACHED): %@", cachedFile);
		return data;
		
	} else {
		NSError *error = nil;
		NSString *data = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSASCIIStringEncoding error:&error];
		//CCLOG(@"%@", error);
		
		if (error == nil) {
			BOOL saved = [data writeToFile:resource atomically:YES encoding:NSASCIIStringEncoding error:nil];
			if (saved) {
				//CCLOG(@"Shared.stringWithContentsOfURL (ONLINE, SAVED:%i): %@", saved, cachedFile);
				return data;
				
			} else {
				//CCLOG(@"Shared.stringWithContentsOfURL (ONLINE, NOT SAVED:%i): %@", saved, cachedFile);
				return data;
			}
		
		} else if ([fileManager fileExistsAtPath:resource]) {
			NSString *data = [NSString stringWithContentsOfFile:resource encoding:NSASCIIStringEncoding error:nil];
			//CCLOG(@"Shared.stringWithContentsOfURL (ERROR, CACHED): %@", cachedFile);
			return data;
			
		} else {
			return nil;
		}
	}
}

+(CCTexture2D*) getTexture2DFromWeb:(NSString*)url ignoreCache:(BOOL)ignoreCache
{
	NSArray *urlComponents = [url componentsSeparatedByString:@"."];
	NSString *extension = [urlComponents lastObject];
	if ([extension length] > 4) extension = @"png";
	NSString *cachedFile = [NSString stringWithFormat:@"%@.%@", [Shared md5:url], extension];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(SAVE_FOLDER, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *resource = [documentsDirectory stringByAppendingPathComponent:cachedFile];
	
	NSArray *urlValues = [url componentsSeparatedByString:@"/"];
	NSString *embeddedResource = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[urlValues lastObject]];
	BOOL embedded = [fileManager fileExistsAtPath:embeddedResource];
	//CCLOG(@"Shared.getTexture2DFromWeb (CHECK IF EMBEDDED): %@ exists %i", [urlValues lastObject], embedded);
	
	if (embedded && (!ignoreCache || ![Shared connectedToNetwork])) {
		CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:embeddedResource];
		//CCLOG(@"Shared.getTexture2DFromWeb (EMBEDDED): %@", embeddedResource);
		return tex;
		
	} else if ([fileManager fileExistsAtPath:resource] && (!ignoreCache || ![Shared connectedToNetwork])) {
		CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:resource];
		
		if (tex != nil) {
			//CCLOG(@"Shared.getTexture2DFromWeb (CACHED): %@", cachedFile);
			return tex;
			
		} else {
			//CCLOG(@"Shared.getTexture2DFromWeb (RE-CACHED): %@", cachedFile);
			CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:resource];
			return tex;
		}
		
	} else {
		NSError *error = nil;
		NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url] options:NSDataReadingMapped error:&error];
		
		if (error == nil) {
			BOOL saved = [imgData writeToFile:resource atomically:YES];
			if (saved) {
				//CCLOG(@"Shared.getTexture2DFromWeb (ONLINE, SAVED:%i): %@", saved, cachedFile);
				CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:resource];
				return tex;
				
			} else {
				//CCLOG(@"Shared.getTexture2DFromWeb (ONLINE, NOT SAVED:%i): %@", saved, cachedFile);
				UIImage *img = [[UIImage alloc] initWithData:imgData];
				CCTexture2D *tex = [[CCTexture2D alloc] initWithImage:img];
				return tex;
			}
			
		} else if ([fileManager fileExistsAtPath:resource]) {
			CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:resource];
			
			if (tex != nil) {
				//CCLOG(@"Shared.getTexture2DFromWeb (ERROR, CACHED): %@", cachedFile);
				return tex;
				
			} else {
				UIImage *img = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:resource]];
				//CCLOG(@"Shared.getTexture2DFromWeb (ERROR, NOT CACHED): %@", cachedFile);
				CCTexture2D *tex = [[CCTexture2D alloc] initWithImage:img];
				return tex;
			}
			
		} else {
			return nil;
		}
	}
}

+(CCSprite *)maskedSpriteWithSprite:(CCSprite *)textureSprite maskSprite:(CCSprite *)maskSprite 
{ 
    CCRenderTexture * rt = [CCRenderTexture renderTextureWithWidth:maskSprite.contentSize.width height:maskSprite.contentSize.height];
	
    maskSprite.position = ccp(maskSprite.contentSize.width/2, maskSprite.contentSize.height/2);
    textureSprite.position = ccp(textureSprite.contentSize.width/2, textureSprite.contentSize.height/2);
	
    [maskSprite setBlendFunc:(ccBlendFunc){GL_ONE, GL_ZERO}];
    [textureSprite setBlendFunc:(ccBlendFunc){GL_DST_ALPHA, GL_ZERO}];
	
    [rt begin];
    [maskSprite visit];        
    [textureSprite visit];    
    [rt end];
	
    CCSprite *retval = [CCSprite spriteWithTexture:rt.sprite.texture];
    retval.flipY = YES;
    return retval;
}

@end
