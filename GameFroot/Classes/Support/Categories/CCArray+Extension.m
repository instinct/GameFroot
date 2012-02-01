//
//  CCArray+Extension.m
//  IsoEngine
//
//  Created by Jose Miguel on 04/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCArray+Extension.h"

@implementation CCArray (ClassName)

- (void) replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
	[self insertObject:anObject atIndex:index];
	[self removeObjectAtIndex: index+1];
}

- (void) fastReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
	// this works to me cos I reorder from same array, otherwise will leak
	data->arr[index] = anObject;
	
	// otherwise use
	//[data->arr[index] release];
	//data->arr[index] = [anObject retain];
}

- (BOOL) isEqualToArray:(CCArray*)otherArray {
	for (int i = 0; i< [self count]; i++)
	{
		if (![[self objectAtIndex:i] isEqual: [otherArray objectAtIndex:i]])
		{
			return FALSE;
		}
	}
	return YES;
}


@end
