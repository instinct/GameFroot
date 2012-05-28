//
//  Shared.h
//  DoubleHappy
//
//  Created by Jose Gomez on 01/01/09.
//  Copyright 2008 ITL Business Ltd. All rights reserved.
//

#import "cocos2d.h"

@interface Shared : NSObject {
	
}

#pragma mark -
#pragma mark Generic functions

+(void) setBetaMode:(BOOL)m;
+(BOOL) isBetaMode;
+(CGSize) getWinSize;
+(NSString *) formattedStringUsingFormat:(NSString *)dateFormat;
+(BOOL) connectedToNetwork;
+(BOOL) isSimulator;
+(void) setSimulator: (BOOL)_value;
+(NSMutableDictionary *) getLevel;
+(void) setLevel: (NSMutableDictionary *)_value;
+(int) getLevelID;
+(NSString *) getLevelDate;
+(NSString *) getLevelTitle;
+(void) setNextLevelID: (int)_value;
+(int) getNextLevelID;
+(BOOL) isPlaying;
+(void) setPlaying: (BOOL)_value;
+(BOOL) isPaused;
+(void) setPaused: (BOOL)_value;
+(NSString *) getOSVersion;
+(void) detectOSVersion;
+(BOOL) isMultitaskingSupported;
+(NSString *) getDevice;
+(void) setDevice: (NSString *)_value;
+(NSString *) traceCGRect: (CGRect) rect;
+(void) drawCGRect: (CGRect) rect;
+(void) drawTriangle: (CGRect) rect direction:(NSString *)direction;
+(BOOL) pointInTriangle:(CGPoint) point pointA:(CGPoint) pointA pointB:(CGPoint) pointB pointC:(CGPoint) pointC;
+(CGPoint *) getTrianglePoints: (CGRect) rect direction:(NSString *)direction;
+(void) moveDocumentFilesToLibrary;
+(BOOL) isEmpty:(id) object;
+(BOOL) isNumeric:(NSString*) checkText;
+(NSString *) decode: (NSString *)value;
+(NSString*) md5: (NSString *)str;
+(NSString*) sha1: (NSString *)str;
+(NSString*) replaceAccents:(NSString*)a;
+(BOOL) getWelcomeShown;
+(void) setWelcomeShown:(BOOL)val;
+(NSString*) getCurrentGameBundle;
+(void) setCurrentGameBundle:(NSString *)gbName;

#pragma mark -
#pragma mark Remote Data Loading (all this is currently depreciated)

+(NSString*)stringWithContentsOfPostURL:(NSString*)url post:(NSString *)post;
+(NSString*)stringWithContentsOfURL:(NSString*)url ignoreCache:(BOOL)ignoreCache;
+(CCTexture2D*) getTexture2DFromWeb:(NSString*)url ignoreCache:(BOOL)ignoreCache;
+(NSMutableDictionary*) loadMusic:(NSArray*)urls fromServer:(NSString*)server ignoreCache:(BOOL)ignoreCache withDefault:(NSString*)d;
+(CCSprite *)maskedSpriteWithSprite:(CCSprite *)textureSprite maskSprite:(CCSprite *)maskSprite;
+(NSString *) generateMusicFileNameHashForUrl:(NSString *)url andFileName:(NSString *)musicFileName;
+(BOOL) existEmbeddedFile:(NSString *)name;

+(ccColor4B) colorForHex:(NSString *)hexColor withTransparency:(float)alpha;

#pragma mark -
#pragma mark IAP Bundle and asset management

+(NSString*) findAsset:(NSString *)fileName withType:(NSString *)type;
+(NSString*) findAssetInDefaultBundle:(NSString *)filename;

@end
