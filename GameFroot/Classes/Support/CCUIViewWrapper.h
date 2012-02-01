//
//  CCUIViewWrapper.h
//  Cloneggs
//
//  Created by Jose Miguel on 19/03/2011.
//  Copyright 2011 ITL Business Ltd. All rights reserved.
//

#import "cocos2d.h"

@interface CCUIViewWrapper : CCSprite
{
	UIView *uiItem;
	float rotation;
}

@property (nonatomic, retain) UIView *uiItem;

+ (id) wrapperForUIView:(UIView*)ui;
- (id) initForUIView:(UIView*)ui;

- (void) updateUIViewTransform;

@end
