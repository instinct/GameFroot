//
//  InputController.h
//  isoEngine
//
//  Created by Jose Miguel on 23/09/2009.
//  Copyright 2009 ITL Business Ltd. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif	
	
	static inline double _icPointLineComparison(CGPoint point, CGPoint lineA, CGPoint lineB)
	{
		return (0.5) * (lineA.x*lineB.y - lineA.y*lineB.x -point.x*lineB.y + point.y*lineB.x + point.x*lineA.y - point.y*lineA.x);
	}
	
	static inline CGPoint _icRotateRealWorld(CGPoint location)
	{
		return [[CCDirector sharedDirector] convertToGL:location];
	}
	
	static inline CGFloat icDistanceBetweenTwoPoints(CGPoint fromPoint, CGPoint toPoint)
	{
		return ccpDistance(fromPoint, toPoint);
	}
	
	static inline bool icIsPointInside(CGPoint point, CGRect rect)
	{
		return CGRectContainsPoint(rect, point);
	}
	
	static inline int icFingerCount(NSSet * touches, UIEvent * event)
	{
		return [[event allTouches] count];
	}
	
	static inline CGPoint icFingerLocation(int finger, NSSet * touches, UIEvent* event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(finger == 0 || finger > [allTouches count])
		{
#ifdef ASSERT_DEBUG
			{
				@throw [[[NSException alloc] initWithName:@"InputController::fingerLocation" reason:@"No such finger" userInfo:nil] autorelease];
			}
#endif
			
			return CGPointZero;
		}
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:finger - 1];
		
		CGPoint location = [touch locationInView:[touch view]];
		
		return _icRotateRealWorld(location);
	}
	
	static inline CGPoint icPreviousFingerLocation(int finger, NSSet * touches, UIEvent* event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(finger == 0 || finger > [allTouches count])
		{
#ifdef ASSERT_DEBUG
			{
				@throw [[[NSException alloc] initWithName:@"InputController::previousFingerLocation" reason:@"No such finger" userInfo:nil] autorelease];
			}
#endif
			
			return CGPointZero;
		}
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:finger - 1];
		
		CGPoint location = [touch previousLocationInView:[touch view]];
		
		return _icRotateRealWorld(location);
	}
	
	static inline bool icWasSwipeLeft(NSSet * touches, UIEvent *event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(1 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start = [touch previousLocationInView:[touch view]];
		CGPoint end = [touch locationInView:[touch view]];
		start = _icRotateRealWorld(start);
		end = _icRotateRealWorld(end);
		
		if(start.x > end.x)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasSwipeRight(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(1 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start = [touch previousLocationInView:[touch view]];
		CGPoint end = [touch locationInView:[touch view]];
		start = _icRotateRealWorld(start);
		end = _icRotateRealWorld(end);
		
		if(start.x < end.x)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasSwipeUp(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(1 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start = [touch previousLocationInView:[touch view]];
		CGPoint end = [touch locationInView:[touch view]];
		start = _icRotateRealWorld(start);
		end = _icRotateRealWorld(end);
		
		if(start.y < end.y)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasSwipeDown(NSSet * touches ,UIEvent * event)
	{
		
		NSSet *allTouches = [event allTouches];
		
		if(1 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start = [touch previousLocationInView:[touch view]];
		CGPoint end = [touch locationInView:[touch view]];
		start = _icRotateRealWorld(start);
		end = _icRotateRealWorld(end);
		
		if(start.y > end.y)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasDragLeft(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);
		
		if(start1.x > end1.x && start2.x > end2.x)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasDragRight(NSSet * touches ,UIEvent * event)
	{
		
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);	
		
		if(start1.x < end1.x && start2.x < end2.x)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasDragUp(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);
		
		if(start1.y < end1.y && start2.y < end2.y)
		{
			return true;
		}
		
		return false;
		
	}
	
	static inline bool icWasDragDown(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);
		
		if(start1.y > end1.y && start2.y > end2.y)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasZoomIn(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);
		
		float initialDistance = icDistanceBetweenTwoPoints(start1, start2);
		float endDistance = icDistanceBetweenTwoPoints(end1, end2);
		
		if(endDistance > initialDistance)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasZoomOut(NSSet * touches ,UIEvent * event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(2 != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		touch = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint start2 = [touch previousLocationInView:[touch view]];
		CGPoint end2 = [touch locationInView:[touch view]];
		start2 = _icRotateRealWorld(start2);
		end2 = _icRotateRealWorld(end2);
		
		float initialDistance = icDistanceBetweenTwoPoints(start1, start2);
		float endDistance = icDistanceBetweenTwoPoints(end1, end2);
		
		if(endDistance < initialDistance)
		{
			return true;
		}
		
		return false;
	}
	
	static inline bool icWasAClickGeneric(NSSet * touches, UIEvent *event, int fingers, int taps)
	{
		NSSet *allTouches = [event allTouches];
		
		if(fingers != [allTouches count])
			return false;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		return [touch phase] == UITouchPhaseEnded && [touch tapCount] == taps;
	}
	
	static inline bool icWasAClick(NSSet * touches ,UIEvent * event)
	{
		return icWasAClickGeneric(touches, event, 1, 1);
	}
	
	static inline bool icWasADoubleClick(NSSet * touches ,UIEvent * event)
	{
		return icWasAClickGeneric(touches, event, 1, 2);
	}
	
	static inline CGPoint icDistance(int finger, NSSet* touches, UIEvent* event)
	{
		NSSet *allTouches = [event allTouches];
		
		if(finger == 0 || finger > [allTouches count])
			return CGPointZero;
		
		UITouch *touch = [[allTouches allObjects] objectAtIndex:finger - 1];
		
		CGPoint start1 = [touch previousLocationInView:[touch view]];
		CGPoint end1 = [touch locationInView:[touch view]];
		start1 = _icRotateRealWorld(start1);
		end1 = _icRotateRealWorld(end1);
		
		//float xDistance = ( fabs(start1.x - end1.x));
		//float yDistance =  ( fabs(start1.y - end1.y));
		float xDistance = (start1.x - end1.x);
		float yDistance =  (start1.y - end1.y);
		
		return CGPointMake(xDistance, yDistance);
	}
	
#ifdef __cplusplus
}
#endif