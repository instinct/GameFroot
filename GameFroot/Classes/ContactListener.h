//
//  ContactListener.h
//  SimpleBox2dScroller
//
//  Created by min on 3/17/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "Box2D.h"
#import "GameObject.h"

class ContactListener : public b2ContactListener {
public:
	ContactListener();
	~ContactListener();
	
    /*
    virtual bool Above(b2Contact *contact);
    virtual bool Below(b2Contact *contact);
    virtual bool BelowPos(GameObject *o1, GameObject *o2);
    virtual bool BelowCloud(GameObject *o1, GameObject *o2);
    virtual bool Right(b2Contact *contact);
    virtual bool Left(b2Contact *contact);
    */
    virtual CONTACT_IS solveContactPosition( b2Contact* contact );
    
	virtual void BeginContact(b2Contact *contact);
	virtual void EndContact(b2Contact *contact);
	virtual void PreSolve(b2Contact *contact, const b2Manifold *oldManifold);
	virtual void PostSolve(b2Contact *contact, const b2ContactImpulse *impulse);
};