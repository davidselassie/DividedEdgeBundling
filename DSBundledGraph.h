//
//  DSGraphView.h
//  EdgeBundling
//
//  Created by David Selassie on 11/22/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import <OpenCL/OpenCL.h>

#import "DSGraphProvider.h"

@interface DSBundledGraph : NSObject <DSGraphProvider> {
	uint2 *edgeList;
	cl_mem edgeListInCL;
	cl_uint edgeCount;
	cl_uint meshCount;
	cl_float *edgeWeights;
	cl_mem edgeWeightsInCL;
	
	float2 *edgeMeshes;			// Coordinates of every mesh point. Since every edge has the same number of mesh points,
								//	you can % and / to select an edge.
	cl_mem edgeMeshesInCL;
	float2 *edgeMeshVelocities;
	cl_mem edgeMeshVelocitiesInCL;
    float2 *edgeMeshAccelerations;
    cl_mem edgeMeshAccelerationsInCL;
	cl_float *edgeMeshGroupWeights;
	cl_mem edgeMeshGroupWeightsInCL;
	cl_float edgeMeshGroupMaxCount;
	cl_float *edgeCompats;			// Triangular matrix of edge compatabilities. Use TriIndex(,,edgeCount) to access.
	cl_mem edgeCompatsInCL;
	cl_float *edgeDots;			// Triangular matrix of edge dot products. Use TriIndex(,,edgeCount) to access.
	cl_mem edgeDotsInCL;
	
	float2 *nodes;				// Coordinates of every node.
    NSMutableArray *nodeMetadata;
	cl_uint nodeCount;
	float4 *nodeColors;
	
	cl_float *nodeDistances;		// Triangular matrix of node distances via the graph topology (not spatial coordinates).
								//	use TriIndex(,,nodeCount) to access.
	cl_mem nodeDistancesInCL;
	
	cl_float dataAspect;
	cl_float dataScale;
	cl_float velocityDamping;
	
	cl_float nodeSpringRestLength;
	cl_float nodeSpringConstant;
	cl_float edgeSpringConstant;
	cl_float edgeCoulombConstant;
	cl_float edgeLaneWidth;
	cl_float edgeMaxWidth;
    cl_float edgeMinWidth;
	cl_float bundleWidthPower;
    cl_float edgeCoulombDecay;
	
	cl_int useCompat;				// If TRUE, then Holten's compatability coeffs are used to scale forces. When changed
								//	edgeCompats are recalculated, which could cause a pause.
	cl_int useConnectCompat;		// If TRUE, then my graph topology compatability coeff is used to scale forces.
								//	Also causes recalcualtion of edgeCompats AND nodeDistances when changed.
    cl_int useNewForce;
	
	cl_device_id clDevice;
	cl_device_id clCPUDevice;
	cl_context clContext;
	cl_command_queue clQueue;
	cl_kernel edgeForceKernel;
	cl_kernel edgeCalcKernel;
	cl_kernel edgeSmoothKernel;
	cl_kernel nodeDistanceKernel;
	cl_int clDeviceType;
    cl_ulong clDeviceMaxMemAllocSize;
    
    NSURL *url;
}

- (void)loadDefaultGraph;
- (void)loadGraphFromURL:(NSURL *)url;
- (void)loadGraphMLFromURL:(NSURL *)url;
- (void)loadGEXFFromURL:(NSURL *)url;

@property (readonly) NSURL *url;

- (void)reset;

@property (readwrite, assign) cl_float nodeSpringRestLength;
@property (readwrite, assign) cl_float nodeSpringConstant;
@property (readwrite, assign) cl_float edgeSpringConstant;
@property (readwrite, assign) cl_float edgeCoulombConstant;
@property (readwrite, assign) cl_float edgeLaneWidth;
@property (readwrite, assign) cl_float edgeMaxWidth;
@property (readwrite, assign) cl_float edgeMinWidth;
@property (readwrite, assign) cl_float bundleWidthPower;
@property (readwrite, assign) cl_float edgeCoulombDecay;

@property (readwrite) BOOL useCompat;
@property (readwrite) BOOL useConnectCompat;
@property (readwrite) BOOL useGPUDevice;
@property (readwrite) BOOL useNewForce;

@property (readonly) float2 *edgeMeshes;
@property (readonly) cl_float *edgeWeights;
@property (readonly) cl_uint edgeCount;
@property (readonly) cl_uint meshCount;
@property (readonly) cl_float *edgeMeshGroupWeights;
@property (readonly) cl_float edgeMeshGroupMaxCount;

@property (readonly) float2 *nodes;
@property (readonly) NSArray *nodeMetadata;
@property (readonly) cl_uint nodeCount;

@property (readonly) cl_float dataAspect;
@property (readwrite, assign) cl_float dataScale;
@property (readwrite, assign) cl_float velocityDamping;

- (void)scaleNodes;

- (void)simulateNodeStep:(cl_float)dt;
- (void)simulateEdgeStep:(cl_float)dt;
- (void)simulateEdgeStep:(cl_float)dt backCopy:(BOOL)backCopy;

- (void)normalizeEdgeWeights;
- (void)calcEdgeCompatibilities;
- (void)smoothEdgeMeshPoints;
- (void)doubleEdgeMeshResolution;

- (void)setMeshPoint:(cl_uint)index toPosition:(float2)pos;
- (void)setNode:(cl_uint)index toPosition:(float2)pos;

@end
