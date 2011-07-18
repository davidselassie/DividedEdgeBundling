//
//  DSBundledGraphView.m
//  EdgeBundling
//
//  Created by David Selassie on 12/16/10.
//  Copyright 2010 David Selassie. All rights reserved.
//

#import "DSBundledGraphView.h"

#import "NSPointExtensions.h"

NSBezierPath * _meshPointPath = nil;

@implementation DSBundledGraphView

+ (NSBezierPath *)meshPointPath {
	if (!_meshPointPath) {
		_meshPointPath = [NSBezierPath bezierPath];
		[_meshPointPath appendBezierPathWithArcWithCenter:NSMakePoint(0, 0) radius:3 startAngle:0 endAngle:360];
		[_meshPointPath setLineWidth:2];
	}
	
	return _meshPointPath;
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.edgeWidth = 4.0;
		self.edgeAlpha = 0.25;
		self.edgeColorType = 0;
		self.showMeshPoints = FALSE;
		
		self.dataSource = nil;
		
		[self addObserver:self forKeyPath:@"edgeWidth" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"edgeAlpha" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"edgeColorType" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"showMeshPoints" options:NSKeyValueObservingOptionNew context:nil];
    }
	
    return self;
}

@synthesize dataSource;

@synthesize edgeWidth;
@synthesize edgeAlpha;
@synthesize edgeColorType;
@synthesize showMeshPoints;

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:dirtyRect];
	
	int edgeCount = [dataSource edgeCount];
	int meshCount = [dataSource meshCount];
	float2 *edgeMeshes = [dataSource edgeMeshes];
	
	/*for (int i = 0; i < nodeCount; i++) {
		NSPoint point = Float2ToNSPoint(nodes[i]);
		[self translateOriginToPoint:point];
		[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.25] set];
		[[DSGraphView meshPointPath] fill];
		[self translateOriginToPoint:NSMakePoint(-point.x, -point.y)];
	}*/
	
	if (showMeshPoints && edgeCount * meshCount > 0) {
		[self translateOriginToPoint:Float2ToNSPoint(edgeMeshes[0])];
		[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.25] set];
		[[DSBundledGraphView meshPointPath] fill];
		[self translateOriginToPoint:NSMakePoint(-edgeMeshes[0].x, -edgeMeshes[0].y)];
	}
	
	for (int i = 1; i < edgeCount * meshCount; i++) {
		int edgeIndex = i % meshCount;
		int e = i / meshCount;
		
		if (edgeIndex == 0)
			continue;
		
		CGFloat plusDot;
		if (edgeColorType == 0) {
			float2 *eMesh = &edgeMeshes[e * meshCount];
			NSPoint head = Float2ToNSPoint(eMesh[0]);
			NSPoint tail = Float2ToNSPoint(eMesh[meshCount - 1]);
			plusDot = NSPointDotProduct(NSPointNormalizedVectorTowards(head, tail),
										NSMakePoint(1.0, 0.0)) + 1.0;
		}
		
		NSPoint lastPoint = Float2ToNSPoint(edgeMeshes[i - 1]);
		NSPoint point = Float2ToNSPoint(edgeMeshes[i]);
		
		[NSBezierPath setDefaultLineWidth:edgeWidth];
		
		// Hue for direction. Doesn't really work on its own, as you know two edges are going in different directions, but not specifics.
		if (edgeColorType == 0)
			[[NSColor colorWithCalibratedHue:plusDot / 4.0 saturation:1.0 brightness:1.0 alpha:edgeAlpha] set];
		// Only red.
		else if (edgeColorType == 2) 
			[[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:edgeAlpha] set];
		
		// Gradient.
		if (edgeColorType == 1) {
			// If we don't have enough subdivision points to make a nice looking gradient, add more.
			const NSUInteger minPoints = 16;
			if (meshCount < minPoints) {
				CGFloat DX = point.x - lastPoint.x;
				CGFloat DY = point.y - lastPoint.y;
				
				CGFloat pctl = (CGFloat)(edgeIndex - 1) / (CGFloat)(meshCount - 1);
				CGFloat pct = (CGFloat)edgeIndex / (CGFloat)(meshCount - 1);
				CGFloat dpct = pct - pctl;
				
				for (NSUInteger g = 0; g < minPoints; g++) {
					CGFloat pctg = pctl + (CGFloat)g/(CGFloat)minPoints * dpct;
					[[NSColor colorWithCalibratedRed:pctg
											   green:pctg
												blue:1.0 - pctg
											   alpha:edgeAlpha] set];
					
					CGFloat xl = lastPoint.x + (CGFloat)g/(CGFloat)minPoints * DX;
					CGFloat yl = lastPoint.y + (CGFloat)g/(CGFloat)minPoints * DY;
					CGFloat x = lastPoint.x + (CGFloat)(g + 1)/(CGFloat)minPoints * DX;
					CGFloat y = lastPoint.y + (CGFloat)(g + 1)/(CGFloat)minPoints * DY;
					
					[NSBezierPath strokeLineFromPoint:NSMakePoint(xl, yl) toPoint:NSMakePoint(x, y)];
				}
			}
			else {
				CGFloat pct = (CGFloat)edgeIndex / (CGFloat)(meshCount - 1);
				[[NSColor colorWithCalibratedRed:pct
										   green:pct
											blue:1.0 - pct
										   alpha:edgeAlpha] set];
				[NSBezierPath strokeLineFromPoint:lastPoint toPoint:point];
				//[edgePath stroke];
			}
		}
		else
			[NSBezierPath strokeLineFromPoint:lastPoint toPoint:point];//[edgePath stroke];
		
		if (showMeshPoints) {
			[self translateOriginToPoint:point];
			[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.25] set];
			[[DSBundledGraphView meshPointPath] fill];
			[self translateOriginToPoint:NSMakePoint(-point.x, -point.y)];
		}
		
		//[edgePath lineToPoint:self.tail.pos];
		
		// Draw directional arrow
		/*NSPoint realMidpoint;
		 if (pointCount % 2) {
		 // Even
		 realMidpoint = NSPointMidpoint([[points objectAtIndex:(NSUInteger)(pointCount / 2) - 1] pos],
		 [[points	objectAtIndex:(NSUInteger)(pointCount / 2)] pos]);
		 }
		 else {
		 // Odd
		 realMidpoint = [[points objectAtIndex:(NSUInteger)(pointCount / 2)] pos];
		 }*/
	}
}

- (BOOL)isFlipped {
	return TRUE;
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
}

- (void)mouseUp:(NSEvent *)theEvent {
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == self)
		[self setNeedsDisplay:TRUE];
}

@end
