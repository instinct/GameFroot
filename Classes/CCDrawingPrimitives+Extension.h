#import <Availability.h>
#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import <CoreGraphics/CGGeometry.h>	// for CGPoint
#endif


#ifdef __cplusplus
extern "C" {
#endif	


/** 
 draws a catmull-rom splines path
 */
void ccDrawCatmullRomSplines(CGPoint *points, unsigned int num, unsigned int segments);

/**
 draws smooth objects
 */
void ccFillSmoothRectangle(CGRect r, float width);
void ccDrawSmoothLine(CGPoint pos1, CGPoint pos2, float width);
void ccDrawSmoothPoint(CGPoint pos, float width);
void ccDrawLineWidth(CGPoint pt1, CGPoint pt2, unsigned int width, BOOL smooth);
void ccDrawDashedLine(CGPoint origin, CGPoint destination, float dashLength);

/**
 draw helpers
 */
float findAngle(CGPoint pt1, CGPoint pt2);
CGPoint findPoint(CGPoint pt, float angle, float distance);
	
#ifdef __cplusplus
}
#endif
