//
//  Collectable.h
//  DoubleHappy
//
//  Created by Jose Miguel on 30/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameObject.h"

typedef enum{
	kCollectableMoney,
	kCollectableAmmo,
	kCollectableWeapon,
	kCollectableJetpack,
	kCollectableHealth,
	kCollectableTime,
	kCollectableLive,
	kCollectableFinal
} CollectableItemType;

@interface Collectable : GameObject {
	CollectableItemType itemType;
	int itemValue;
}

@property (nonatomic,assign) CollectableItemType itemType;
@property (nonatomic,assign) int itemValue;

@end
