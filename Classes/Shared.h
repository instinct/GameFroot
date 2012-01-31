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

+(CGSize) getWinSize;
+(NSString *) formattedStringUsingFormat:(NSString *)dateFormat;
+(BOOL) connectedToNetwork;
+(int) getLevel;
+(void) setLevel: (int)_value;
+(NSString *) getLevelDate;
+(void) setLevelDate: (NSString *)_value;
+(NSString *) getLevelTitle;
+(void) setLevelTitle: (NSString *)_value;
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
+(NSString *) decode: (NSString *)value;
+(NSString*) md5: (NSString *)str;
+(NSString*) sha1: (NSString *)str;
+(NSString*) replaceAccents:(NSString*)a;

#pragma mark -
#pragma mark Remote Data Loading

+(NSString*)stringWithContentsOfPostURL:(NSString*)url post:(NSString *)post;
+(NSString*)stringWithContentsOfURL:(NSString*)url ignoreCache:(BOOL)ignoreCache;
+(CCTexture2D*) getTexture2DFromWeb:(NSString*)url ignoreCache:(BOOL)ignoreCache;

+(CCSprite *)maskedSpriteWithSprite:(CCSprite *)textureSprite maskSprite:(CCSprite *)maskSprite;

@end
