//
//  CCLabelBMFont+AddToBatchNode.h
//  Cloneggs
//
//  Created by Jose Miguel on 07/05/2011.
//  Copyright 2011 ITL Business Ltd. All rights reserved.
//

#import "cocos2d.h"

@interface CCLabelBMFont (AddToBatchNode) 

-(void)addToBatchNode:(CCSpriteBatchNode *)batchnode zOrder:(int)order position:(CGPoint)position;

@end
