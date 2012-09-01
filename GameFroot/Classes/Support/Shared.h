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

+(void) setBetaMode:(int)m;
+(BOOL) isBetaMode;
+(BOOL) isAdminMode;
+(CGSize) getWinSize;
+(NSString *) formattedStringUsingFormat:(NSString *)dateFormat;
+(BOOL) connectedToNetwork;
+(BOOL) isSimulator;
+(void) setSimulator: (BOOL)_value;
+(NSMutableDictionary *) getLevel;
+(void) setLevel: (NSMutableDictionary *)_value;
+(void) replaceLevelID: (int)_levelID;
+(void) restoreLevelID;
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

#pragma mark -
#pragma mark Remote Data Loading

+(NSString*)stringWithContentsOfPostURL:(NSString*)url post:(NSString *)post;
+(NSString*)stringWithContentsOfURL:(NSString*)url ignoreCache:(BOOL)ignoreCache;
+(CCTexture2D*) getTexture2DFromWeb:(NSString*)url ignoreCache:(BOOL)ignoreCache;
+(NSMutableDictionary*) loadMusic:(NSArray*)urls fromServer:(NSString*)server ignoreCache:(BOOL)ignoreCache withDefault:(NSString*)d;
+(CCSprite *)maskedSpriteWithSprite:(CCSprite *)textureSprite maskSprite:(CCSprite *)maskSprite;
+(NSString *) generateMusicFileNameHashForUrl:(NSString *)url andFileName:(NSString *)musicFileName;
+(BOOL) existEmbeddedFile:(NSString *)name;

+(ccColor4B) colorForHex:(NSString *)hexColor withTransparency:(float)alpha;

@end
