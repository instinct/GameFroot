//
//  ContactListener.m
//  Scroller
//
//  Created by min on 1/16/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "ContactListener.h"
#import "Constants.h"
#import "Player.h"
#import "Enemy.h"
#import "Bullet.h"
#import "GameLayer.h"
#import "MovingPlatform.h"
#import "Switch.h"
#import "Robot.h"

ContactListener::ContactListener() {
}

ContactListener::~ContactListener() {
}

CONTACT_IS ContactListener::solveContactPosition( b2Contact* contact ) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    
    // check
    if ( lround( worldNormal.y ) ==  1 ) return( CONTACT_IS_BELOW );
    if ( lround( worldNormal.y ) == -1 ) return( CONTACT_IS_ABOVE );
    if ( lround( worldNormal.x ) ==  1 ) return( CONTACT_IS_LEFT );
    if ( lround( worldNormal.x ) == -1 ) return( CONTACT_IS_RIGHT );
    return( CONTACT_IS_UNDEFINED );
}

// BeginContact is only called once

void ContactListener::BeginContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
	if ( o1.removed || o2.removed ) {
		contact->SetEnabled( false ); // <- NO EFFECT
		return;
	}
	
    //if (!contact->IsTouching()) return;
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handleBeginCollision:data ];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handleBeginCollision:data ];
    
}

// PreSolve can be called several times
// Primary use is to ignore collisions

void ContactListener::PreSolve(b2Contact *contact, const b2Manifold *oldManifold) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
    //if (!contact->IsTouching()) return;
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handlePreSolve:data manifold:oldManifold];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handlePreSolve:data manifold:oldManifold];
    
}

void ContactListener::PostSolve(b2Contact *contact, const b2ContactImpulse *impulse) {
    GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
    //if (!contact->IsTouching()) return;
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handlePostSolve:data impulse:impulse];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handlePostSolve:data impulse:impulse];
}

// EndContact is only called once

void ContactListener::EndContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handleEndCollision:data ];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handleEndCollision:data ];
    
}