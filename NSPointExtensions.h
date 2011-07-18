//
//  NSPointExtensions.h
//  EdgeBundling
//
//  Created by David Selassie on 11/27/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "DSGraphProvider.h"

NSPoint NSPointDifference(NSPoint one, NSPoint two);
NSPoint NSPointSum(NSPoint one, NSPoint two);
CGFloat NSPointDotProduct(NSPoint one, NSPoint two);
CGFloat NSPointDistance(NSPoint one, NSPoint two);
NSPoint NSPointProd(NSPoint vec, CGFloat scal);
NSPoint NSPointMidpoint(NSPoint one, NSPoint two);
NSPoint NSPointNormalizedVectorTowards(NSPoint one, NSPoint two);
CGFloat NSPointCrossProduct(NSPoint one, NSPoint two);
NSPoint NSPointNormal(NSPoint vec);
NSPoint NSPointConstrainToNSRect(NSPoint point_ns, NSRect rect_ns);
NSPoint Float2ToNSPoint(float2 point);
