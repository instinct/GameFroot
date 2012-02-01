#import <math.h>
#import <stdlib.h>
#import <string.h>

#import "CCDrawingPrimitives+Extension.h"
#import "CCDrawingPrimitives.h"
#import "ccTypes.h"
#import "ccMacros.h"

CGPoint tangent(CGPoint p1, CGPoint p2) {
	return CGPointMake((p1.x - p2.x) / 2.0f, (p1.y - p2.y) / 2.0f);
}

void ccDrawCatmullRomSplines(CGPoint *points, unsigned int num, unsigned int segments)
{
	float px, py;
	float tt, _1t, _2t;
	float h00, h10, h01, h11;
	CGPoint m0;
	CGPoint m1;
	CGPoint m2;
	CGPoint m3;
	
	float rez = 1.0f / segments;
	CGPoint vertices[segments * num];
	unsigned int count = 0;
	
	vertices[count++] = CGPointMake(points[0].x * CC_CONTENT_SCALE_FACTOR(), points[0].y * CC_CONTENT_SCALE_FACTOR());
	
	for (int n = 0; n < num; n++) {
		
		for (float t = 0.0f; t < 1.0f; t += rez) {
			tt = t * t;
			_1t = 1 - t;
			_2t = 2 * t;
			h00 =  (1 + _2t) * (_1t) * (_1t);
			h10 =  t  * (_1t) * (_1t);
			h01 =  tt * (3 - _2t);
			h11 =  tt * (t - 1);
			
			if (!n) {
				m0 = tangent(points[n+1], points[n]);  
				m1 = tangent(points[n+2], points[n]);  
				px = h00 * points[n].x * CC_CONTENT_SCALE_FACTOR() + h10 * m0.x * CC_CONTENT_SCALE_FACTOR() + h01 * points[n+1].x * CC_CONTENT_SCALE_FACTOR() + h11 * m1.x * CC_CONTENT_SCALE_FACTOR();
				py = h00 * points[n].y * CC_CONTENT_SCALE_FACTOR() + h10 * m0.y * CC_CONTENT_SCALE_FACTOR() + h01 * points[n+1].y * CC_CONTENT_SCALE_FACTOR() + h11 * m1.y * CC_CONTENT_SCALE_FACTOR();
				
				vertices[count++] = CGPointMake(px, py);
			}
			else if (n < num-2)
			{
				m1 = tangent(points[n+1], points[n-1]);  
				m2 = tangent(points[n+2], points[n]);  
				px = h00 * points[n].x * CC_CONTENT_SCALE_FACTOR() + h10 * m1.x * CC_CONTENT_SCALE_FACTOR() + h01 * points[n+1].x * CC_CONTENT_SCALE_FACTOR() + h11 * m2.x * CC_CONTENT_SCALE_FACTOR();
				py = h00 * points[n].y * CC_CONTENT_SCALE_FACTOR() + h10 * m1.y * CC_CONTENT_SCALE_FACTOR() + h01 * points[n+1].y * CC_CONTENT_SCALE_FACTOR() + h11 * m2.y * CC_CONTENT_SCALE_FACTOR();
				
				vertices[count++] = CGPointMake(px, py);
			}
			else if (n == num-1)
			{
				m2 = tangent(points[n], points[n-2]);  
				m3 = tangent(points[n], points[n-1]);  
				px = h00 * points[n-1].x * CC_CONTENT_SCALE_FACTOR() + h10 * m2.x * CC_CONTENT_SCALE_FACTOR() + h01 * points[n].x * CC_CONTENT_SCALE_FACTOR() + h11 * m3.x * CC_CONTENT_SCALE_FACTOR();
				py = h00 * points[n-1].y * CC_CONTENT_SCALE_FACTOR() + h10 * m2.y * CC_CONTENT_SCALE_FACTOR() + h01 * points[n].y * CC_CONTENT_SCALE_FACTOR() + h11 * m3.y * CC_CONTENT_SCALE_FACTOR();
				
				vertices[count++] = CGPointMake(px, py);
			}  
			
		}
	}
	
	vertices[count++] = CGPointMake(points[num-1].x * CC_CONTENT_SCALE_FACTOR(), points[num-1].y * CC_CONTENT_SCALE_FACTOR());
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	//glEnableClientState(GL_VERTEX_ARRAY);
	
	glDrawArrays(GL_LINE_STRIP, 0, count);
	
	//glDisableClientState(GL_VERTEX_ARRAY);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
}

void ccFillSmoothRectangle(CGRect r, float width)
{
    GLfloat rectVertices[10][2];
    GLfloat curc[4]; 
    GLint   ir, ig, ib, ia;
	
	r.origin.x *= CC_CONTENT_SCALE_FACTOR();
	r.origin.y *= CC_CONTENT_SCALE_FACTOR();
	r.size.width *= CC_CONTENT_SCALE_FACTOR();
	r.size.height *= CC_CONTENT_SCALE_FACTOR();
	width *= CC_CONTENT_SCALE_FACTOR();
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	//glEnable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    // fill the inside of the rectangle
    rectVertices[0][0] = r.origin.x;
    rectVertices[0][1] = r.origin.y;
    rectVertices[1][0] = r.origin.x+r.size.width;
    rectVertices[1][1] = r.origin.y;
    rectVertices[2][0] = r.origin.x;
    rectVertices[2][1] = r.origin.y+r.size.height;
    rectVertices[3][0] = r.origin.x+r.size.width;
    rectVertices[3][1] = r.origin.y+r.size.height;
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, rectVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
    rectVertices[0][0] = r.origin.x;
    rectVertices[0][1] = r.origin.y;
    rectVertices[1][0] = r.origin.x-width;
    rectVertices[1][1] = r.origin.y-width;
    rectVertices[2][0] = r.origin.x+r.size.width;
    rectVertices[2][1] = r.origin.y;
    rectVertices[3][0] = r.origin.x+r.size.width+width;
    rectVertices[3][1] = r.origin.y-width;
    rectVertices[4][0] = r.origin.x+r.size.width;
    rectVertices[4][1] = r.origin.y+r.size.height;
    rectVertices[5][0] = r.origin.x+r.size.width+width;
    rectVertices[5][1] = r.origin.y+r.size.height+width;
    rectVertices[6][0] = r.origin.x;
    rectVertices[6][1] = r.origin.y+r.size.height;
    rectVertices[7][0] = r.origin.x-width;
    rectVertices[7][1] = r.origin.y+r.size.height+width;
    rectVertices[8][0] = r.origin.x;
    rectVertices[8][1] = r.origin.y;
    rectVertices[9][0] = r.origin.x-width;
    rectVertices[9][1] = r.origin.y-width;
	
    glGetFloatv(GL_CURRENT_COLOR, curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];
	
    const GLubyte rectColors[] = {
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
    };
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, rectVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, rectColors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 10);
    glDisableClientState(GL_COLOR_ARRAY);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
}

void ccDrawSmoothLine(CGPoint pos1, CGPoint pos2, float width)
{
    GLfloat lineVertices[12], curc[4];
    GLint   ir, ig, ib, ia;
    CGPoint dir, tan;
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	//glEnable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	pos1.x *= CC_CONTENT_SCALE_FACTOR();
	pos1.y *= CC_CONTENT_SCALE_FACTOR();
	pos2.x *= CC_CONTENT_SCALE_FACTOR();
	pos2.y *= CC_CONTENT_SCALE_FACTOR();
	width *= CC_CONTENT_SCALE_FACTOR();
	
    width = width*8;
    dir.x = pos2.x - pos1.x;
    dir.y = pos2.y - pos1.y;
    float len = sqrtf(dir.x*dir.x+dir.y*dir.y);
    if(len<0.00001)
        return;
    dir.x = dir.x/len;
    dir.y = dir.y/len;
    tan.x = -width*dir.y;
    tan.y = width*dir.x;
	
    lineVertices[0] = pos1.x + tan.x;
    lineVertices[1] = pos1.y + tan.y;
    lineVertices[2] = pos2.x + tan.x;
    lineVertices[3] = pos2.y + tan.y;
    lineVertices[4] = pos1.x;
    lineVertices[5] = pos1.y;
    lineVertices[6] = pos2.x;
    lineVertices[7] = pos2.y;
    lineVertices[8] = pos1.x - tan.x;
    lineVertices[9] = pos1.y - tan.y;
    lineVertices[10] = pos2.x - tan.x;
    lineVertices[11] = pos2.y - tan.y;
	
    glGetFloatv(GL_CURRENT_COLOR,curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];
	
    const GLubyte lineColors[] = {
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
    };
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, lineVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, lineColors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);
    glDisableClientState(GL_COLOR_ARRAY);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
}


void ccDrawSmoothPoint(CGPoint pos, float width)
{
    GLfloat pntVertices[12], curc[4]; 
    GLint   ir, ig, ib, ia;
	
	pos.x *= CC_CONTENT_SCALE_FACTOR();
	pos.y *= CC_CONTENT_SCALE_FACTOR();
	width *= CC_CONTENT_SCALE_FACTOR();
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	//glEnable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    pntVertices[0] = pos.x;
    pntVertices[1] = pos.y;
    pntVertices[2] = pos.x - width;
    pntVertices[3] = pos.y - width;
    pntVertices[4] = pos.x - width;
    pntVertices[5] = pos.y + width;
    pntVertices[6] = pos.x + width;
    pntVertices[7] = pos.y + width;
    pntVertices[8] = pos.x + width;
    pntVertices[9] = pos.y - width;
    pntVertices[10] = pos.x - width;
    pntVertices[11] = pos.y - width;
	
    glGetFloatv(GL_CURRENT_COLOR,curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];
	
    const GLubyte pntColors[] = {
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
    };
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, pntVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, pntColors);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 6);
    glDisableClientState(GL_COLOR_ARRAY);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);	
}

void ccDrawLineWidth(CGPoint pt1, CGPoint pt2, unsigned int width, BOOL smooth) {
	GLfloat curc[4]; 
	glGetFloatv(GL_CURRENT_COLOR,curc);
	
	width *= CC_CONTENT_SCALE_FACTOR();
	
	if (smooth) {
		//glEnable(GL_LINE_SMOOTH);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	}
	
	float distance = 0.5f;
	float angle = findAngle(pt1, pt2);
	
	if (width > 1) {
		for (unsigned int i=0; i < width; i++) {
			if (smooth) glColor4f(curc[0], curc[1], curc[2], curc[3] * (((width - i + 2.0f) * 100.0f)/(width + 2.0f) / 100.0f));
			CGPoint pt1_1 = findPoint(pt1, angle + 90, (i*distance) + distance);
			CGPoint pt2_1 = findPoint(pt2, angle + 90, (i*distance) + distance);
			ccDrawLine(pt1_1, pt2_1);
		}
	}
	
	glColor4f(curc[0], curc[1], curc[2], curc[3]);
	ccDrawLine(pt1, pt2); 
	
	if (width > 1) {
		for (unsigned int i=0; i < width; i++) {
			if (smooth) glColor4f(curc[0], curc[1], curc[2], curc[3] * (((width - i + 2.0f) * 100.0f)/(width + 2.0f) / 100.0f));
			CGPoint pt1_2 = findPoint(pt1, angle - 90, (i*distance) + distance);
			CGPoint pt2_2 = findPoint(pt2, angle - 90, (i*distance) + distance);
			ccDrawLine(pt1_2, pt2_2);
		}
	}
	
}

void ccDrawDashedLine(CGPoint origin, CGPoint destination, float dashLength)
{
	origin.x *= CC_CONTENT_SCALE_FACTOR();
	origin.y *= CC_CONTENT_SCALE_FACTOR();
	destination.x *= CC_CONTENT_SCALE_FACTOR();
	destination.y *= CC_CONTENT_SCALE_FACTOR();
	dashLength *= CC_CONTENT_SCALE_FACTOR();
	
	float dx = destination.x - origin.x;
	float dy = destination.y - origin.y;
	float dist = sqrtf(dx * dx + dy * dy);
	float x = dx / dist * dashLength;
	float y = dy / dist * dashLength;
	
	CGPoint p1 = origin;
	NSUInteger segments = (int)(dist / dashLength);
	NSUInteger lines = (int)((float)segments / 2.0);
	
	CGPoint *vertices = malloc(sizeof(CGPoint) * segments);
	for(int i = 0; i < lines; i++)
	{
		vertices[i*2] = p1;
		p1 = CGPointMake(p1.x + x, p1.y + y);
		vertices[i*2+1] = p1;
		p1 = CGPointMake(p1.x + x, p1.y + y);
	}
	
	/*
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_LINES, 0, segments);
	glDisableClientState(GL_VERTEX_ARRAY);
	*/
	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);	
	glDrawArrays(GL_LINES, 0, segments);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	free(vertices);
}

float findAngle(CGPoint pt1, CGPoint pt2) {
	float angle = atan2(pt1.y - pt2.y, pt1.x - pt2.x) * (180 / M_PI);
	angle = angle < 0 ? angle + 360 : angle;
	
	return angle;
}

CGPoint findPoint(CGPoint pt, float angle, float distance) {
	float x = distance * cos(angle * (M_PI/180));
	float y = distance * sin(angle * (M_PI/180));
	
	return CGPointMake(pt.x + x, pt.y + y);
}
