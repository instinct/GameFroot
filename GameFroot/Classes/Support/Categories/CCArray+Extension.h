//
//  CCArray+Extension.h
//  IsoEngine
//
//  Created by Jose Miguel on 04/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface CCArray (ClassName)

- (void) replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (void) fastReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (BOOL) isEqualToArray:(CCArray*)otherArray;

@end