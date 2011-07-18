//
//  DSGraphProvider.h
//  EdgeBundling
//
//  Created by David Selassie on 12/16/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import <OpenCL/OpenCL.h>

typedef struct {
	cl_uint x;
	cl_uint y;
} uint2 __attribute__((aligned(8))); //cl_uint2

typedef struct {
	cl_ushort x;
	cl_ushort y;
} ushort2 __attribute__((aligned(4))); //cl_ushort2

typedef struct {
	cl_float x;
	cl_float y;
} float2 __attribute__((aligned(8))); //cl_float2

typedef struct {
	cl_float x;
	cl_float y;
	cl_float z;
	cl_float w;
} float4 __attribute__((aligned(16))); //cl_float4

float2 MakeFloat2(cl_float x, cl_float y);

@protocol DSGraphProvider

@property (readonly) float2 *edgeMeshes;
@property (readonly) cl_float *edgeWeights;
@property (readonly) cl_uint edgeCount;
@property (readonly) cl_uint meshCount;
@property (readonly) cl_float *edgeMeshGroupWeights;
@property (readonly) cl_float edgeMeshGroupMaxCount;

@property (readonly) cl_float edgeMaxWidth;
@property (readonly) cl_float edgeMinWidth;
@property (readonly) cl_float bundleWidthPower;

@property (readonly) float2 *nodes;
@property (readonly) NSArray *nodeMetadata;
@property (readonly) cl_uint nodeCount;

@property (readonly) float dataAspect;
@property (readonly) float dataScale;

- (void)calcEdgeCompatibilities;

- (void)setMeshPoint:(cl_uint)index toPosition:(float2)pos;

@end
