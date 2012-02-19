//
//  SpriteItem.h
//  Cloneggs
//
//  Created by Jose Miguel on 05/04/2011.
//  Copyright 2011 ITL Business Ltd. All rights reserved.
//

#import "cocos2d.h"

@interface ButtonLabelItem : CCMenuItem <CCRGBAProtocol> {
	
	CCSprite *button_;
	CCLabelBMFont *label_;
	
	CGPoint origianlPosition;
}

@property (nonatomic,readwrite,retain) CCSprite<CCRGBAProtocol> *button;
@property (nonatomic,readwrite,retain) CCLabelBMFont<CCRGBAProtocol> *label;

+(id) itemFromSprite:(CCNode<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label;

+(id) itemFromSprite:(CCNode<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label target:(id)target selector:(SEL)selector;

-(id) initFromSprite:(CCNode<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label target:(id)target selector:(SEL)selector;

@end
