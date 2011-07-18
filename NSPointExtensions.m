//
//  NSPointExtensions.c
//  EdgeBundling
//
//  Created by David Selassie on 11/27/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "NSPointExtensions.h"

NSPoint NSPointDifference(NSPoint one, NSPoint two) {
	return NSMakePoint(one.x - two.x, one.y - two.y);
}

NSPoint NSPointSum(NSPoint one, NSPoint two) {
	return NSMakePoint(one.x + two.x, one.y + two.y);
}

CGFloat NSPointDotProduct(NSPoint one, NSPoint two) {
	return one.x * two.x + one.y * two.y;
}

CGFloat NSPointDistance(NSPoint one, NSPoint two) {
	return sqrt(pow(one.x - two.x, 2.0) + pow(one.y - two.y, 2.0));
}

NSPoint NSPointProd(NSPoint vec, CGFloat scal) {
	return NSMakePoint(vec.x * scal, vec.y * scal);
}

NSPoint NSPointMidpoint(NSPoint one, NSPoint two) {
	return NSMakePoint((two.x - one.x) / 2.0 + one.x,
					   (two.y - one.y) / 2.0 + one.y);
}

NSPoint NSPointNormalizedVectorTowards(NSPoint one, NSPoint two) {
	NSPoint reduced = NSPointDifference(two, one);
	CGFloat length = NSPointDistance(one, two);
	
	if (length > 0.0)
		return NSPointProd(reduced, 1.0 / length);
	else
		return NSMakePoint(0.0, 0.0);
}

CGFloat NSPointCrossProduct(NSPoint one, NSPoint two) {
	return one.x * two.y - one.y * two.x;
}

NSPoint NSPointNormal(NSPoint vec) {
	return NSMakePoint(vec.y, -vec.x);
}

NSPoint NSPointConstrainToNSRect(NSPoint point_ns, NSRect rect_ns) {
	CGRect rect = NSRectToCGRect(rect_ns);
	CGPoint point = NSPointToCGPoint(point_ns);
	
	if (!CGRectContainsPoint(rect, point)) {
		if (point.x < CGRectGetMinX(rect))
			point = CGPointMake(CGRectGetMinX(rect), point.y);
		else if (point.x > CGRectGetMaxX(rect))
			point = CGPointMake(CGRectGetMaxX(rect), point.y);
		
		if (point.y < CGRectGetMinY(rect))
			point = CGPointMake(point.x, CGRectGetMinY(rect));
		else if (point.y > CGRectGetMaxY(rect))
			point = CGPointMake(point.x, CGRectGetMaxY(rect));
	}
	
	return NSPointFromCGPoint(point);
}

NSPoint Float2ToNSPoint(float2 point) {
	return NSMakePoint(point.x, point.y);
}
