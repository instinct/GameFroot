////  SWScrollView.h//  SWGameLib//////  Copyright (c) 2010 Sangwoo Im////  Permission is hereby granted, free of charge, to any person obtaining a copy//  of this software and associated documentation files (the "Software"), to deal//  in the Software without restriction, including without limitation the rights//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell//  copies of the Software, and to permit persons to whom the Software is//  furnished to do so, subject to the following conditions:////  The above copyright notice and this permission notice shall be included in//  all copies or substantial portions of the Software.////  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN//  THE SOFTWARE.//  ////  Created by Sangwoo Im on 6/3/10.//  Copyright 2010 Sangwoo Im. All rights reserved.//#import "CCLayer.h"// Define a very high priority on touches so buttons don't block the scroll#define kSWTouchPriority -99999typedef enum {    SWScrollViewDirectionHorizontal,    SWScrollViewDirectionVertical,    SWScrollViewDirectionBoth} SWScrollViewDirection;@class SWScrollView;@protocol SWScrollViewDelegate<          NSObject>@optional-(void)scrollViewDidScroll:(SWScrollView *)view;-(void)scrollViewDidZoom:(SWScrollView *)view;@end/** * ScrollView support for cocos2d for iphone. * It provides scroll view functionalities to cocos2d projects natively. */@interface SWScrollView :          CCLayer {    /**     * Container holds scroll view contents     */    CCNode *container_;    /**     * Determiens whether user touch is moved after begin phase.     */    BOOL touchMoved_;    /**     * max inset point to limit scrolling by touch     */    CGPoint maxInset_;    /**     * min inset point to limit scrolling by touch     */    CGPoint minInset_;    /**     * If YES, touches are being moved     */    BOOL isDragging_;    /**     * Determines whether the scroll view is allowed to bounce or not.     */    BOOL bounces_;    /**     * Determines whether it clips its children or not.     */    BOOL clipsToBounds_;    /**     * scroll speed     */    CGPoint scrollDistance_;    /**     * Touch point     */    CGPoint touchPoint_;    /**     * length between two fingers     */    CGFloat touchLength_;    /**     * UITouch objects to detect multitouch     */    NSMutableArray *touches_;    /**     * size to clip. CCNode boundingBox uses contentSize directly.     * It's semantically different what it actually means to common scroll views.     * Hence, this scroll view will use a separate size property.     */    CGSize viewSize_;    /**     * scroll direction     */    SWScrollViewDirection direction_;    /**     * delegate to respond to scroll event     */    id<SWScrollViewDelegate> delegate_;    /**     * max and min scale     */    CGFloat minScale_, maxScale_;}/** * current zoom scale */@property (nonatomic, assign) CGFloat zoomScale;/** * min zoom scale */@property (nonatomic, assign) CGFloat minZoomScale;/** * max zoom scale */@property (nonatomic, assign) CGFloat maxZoomScale;/** * scroll view delegate */@property (nonatomic, assign) id<SWScrollViewDelegate> delegate;/** * If YES, the view is being dragged. */@property (nonatomic, assign, readonly) BOOL isDragging;/** * Determines whether the scroll view is allowed to bounce or not. */@property (nonatomic, assign) BOOL bounces;/** * direction allowed to scroll. CCScrollViewDirectionBoth by default. */@property (nonatomic, assign) SWScrollViewDirection direction;/** * If YES, it clips its children to the visible bounds (view size) * it is YES by default. */@property (nonatomic, assign) BOOL clipsToBounds;/** * Content offset. Note that left-bottom point is the origin */@property (nonatomic, assign) CGPoint contentOffset;/** * ScrollView size which is different from contentSize. This size determines visible  * bounding box. */@property (nonatomic, assign, setter=setViewSize:) CGSize viewSize;/** * Returns an autoreleased scroll view object. * * @param size view size * @return autoreleased scroll view object */+(id)viewWithViewSize:(CGSize)size;/** * Returns a scroll view object * * @param size view size * @return scroll view object */-(id)initWithViewSize:(CGSize)size;/** * Returns an autoreleased scroll view object. * * @param size view size * @param container parent object * @return autoreleased scroll view object */+(id)viewWithViewSize:(CGSize)size container:(CCNode *)container;/** * Returns a scroll view object * * @param size view size * @param container parent object * @return scroll view object */-(id)initWithViewSize:(CGSize)size container:(CCNode *)container;/** * Sets a new content offset. It ignores max/min offset. It just sets what's given. (just like UIKit's UIScrollView) * * @param offset new offset * @param If YES, the view scrolls to the new offset */-(void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;/** * Sets a new content offset. It ignores max/min offset. It just sets what's given. (just like UIKit's UIScrollView) * You can override the animation duration with this method. * * @param offset new offset * @param animation duration */-(void)setContentOffset:(CGPoint)offset animatedInDuration:(ccTime)dt; /** * Sets a new scale and does that for a predefined duration. * * @param s a new scale vale * @param animated if YES, scaling is animated */-(void)setZoomScale:(float)s animated:(BOOL)animated;/** * Sets a new scale for container in a given duration. * * @param s a new scale value * @param animation duration */-(void)setZoomScale:(float)s animatedInDuration:(ccTime)dt;/** * Returns the current container's minimum offset. You may want this while you animate scrolling by yourself */-(CGPoint)minContainerOffset;/** * Returns the current container's maximum offset. You may want this while you animate scrolling by yourself */-(CGPoint)maxContainerOffset; /** * Determines if a given node's bounding box is in visible bounds * * @return YES if it is in visible bounds */-(BOOL)isNodeVisible:(CCNode *)node;/** * Provided to make scroll view compatible with SWLayer's pause method */-(void)pause:(id)sender;/** * Provided to make scroll view compatible with SWLayer's resume method */-(void)resume:(id)sender;@end