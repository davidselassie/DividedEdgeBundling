//
//  DSGraphView.m
//  EdgeBundling
//
//  Created by David Selassie on 11/22/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DSBundledGraph.h"

#define DEBUG_PRINT 0

@interface DSBundledGraph ()

- (void)shutdownCLDevice;
- (void)setupCLDeviceOfType:(cl_int)deviceType;

- (void)addNode:(float2)newNode;
- (void)addEdgeFromIndex:(cl_uint)node1 toIndex:(cl_uint)node2 weight:(cl_float)weight;

@property (readwrite, retain) NSURL *url;

@property (readwrite) cl_uint edgeCount;
@property (readwrite) cl_uint meshCount;
@property (readwrite) cl_uint nodeCount;

@end

cl_uint TriIndex(cl_uint row, cl_uint col, cl_uint N)
{
	if (row < col)
		return row * (N - 1) - (row - 1) * ((row - 1) + 1) / 2 + col - row - 1;
	else if (col < row)
		return col * (N - 1) - (col - 1) * ((col - 1) + 1) / 2 + row - col - 1;
	else
		assert(FALSE);
}

@implementation DSBundledGraph

- (id)init {
	if ((self = [super init])) {
		edgeList = nil;
		edgeListInCL = nil;
		edgeWeights = nil;
		edgeWeightsInCL = nil;
		self.edgeCount = 0;
		self.meshCount = 2;
		
		edgeMeshes = nil;
		edgeMeshesInCL = nil;
		edgeMeshVelocities = nil;
		edgeMeshVelocitiesInCL = nil;
        edgeMeshAccelerations = nil;
        edgeMeshAccelerationsInCL = nil;
		edgeCompats = nil;
		edgeCompatsInCL = nil;
		edgeDots = nil;
		edgeDotsInCL = nil;
		
		nodes = nil;
        nodeMetadata = [[NSMutableArray alloc] init];
		self.nodeCount = 0;
		
		nodeDistances = nil;
		nodeDistancesInCL = nil;
		
		dataAspect = 0.0;
		self.dataScale = 1000.0;
		self.velocityDamping = 0.1;
		
		self.nodeSpringRestLength = 200.0;
		self.nodeSpringConstant = 0.1;
		
		self.edgeSpringConstant = 0.5;
		self.edgeCoulombConstant = 0.5;
		self.edgeLaneWidth = 25.0;
		self.edgeMaxWidth = 5.0;
        self.edgeMinWidth = 1.0;
		self.bundleWidthPower = 1.0;
        self.edgeCoulombDecay = 35.0;
		
		self.useCompat = TRUE;
		self.useConnectCompat = FALSE;
        self.useNewForce = FALSE;
        
        [self addObserver:self forKeyPath:@"useConnectCompat" options:NSKeyValueObservingOptionNew context:nil];

		self.useGPUDevice = FALSE;
        
        self.url = nil;
	}
	
	return self;
}

- (BOOL)useGPUDevice {
	return clDeviceType == CL_DEVICE_TYPE_GPU;
}

- (void)setUseGPUDevice:(BOOL)val {
	if (val)
		clDeviceType = CL_DEVICE_TYPE_GPU;
	else
		clDeviceType = CL_DEVICE_TYPE_CPU;
	
	[self shutdownCLDevice];
	[self setupCLDeviceOfType:clDeviceType];
}

- (void)shutdownCLDevice {
	if (edgeListInCL) {
		clReleaseMemObject(edgeListInCL);
		edgeListInCL = nil;
	}
	if (edgeWeightsInCL) {
		clReleaseMemObject(edgeWeightsInCL);
		edgeWeightsInCL = nil;
	}
	
	if (edgeMeshesInCL) {
		clReleaseMemObject(edgeMeshesInCL);
		edgeMeshesInCL = nil;
	}
	if (edgeMeshVelocitiesInCL) {
		clReleaseMemObject(edgeMeshVelocitiesInCL);
		edgeMeshVelocitiesInCL = nil;
	}
    if (edgeMeshAccelerationsInCL) {
		clReleaseMemObject(edgeMeshAccelerationsInCL);
		edgeMeshAccelerationsInCL = nil;
	}
	if (edgeCompatsInCL) {
		clReleaseMemObject(edgeCompatsInCL);
		edgeCompatsInCL = nil;
	}
	if (edgeDotsInCL) {
		clReleaseMemObject(edgeDotsInCL);
		edgeDotsInCL = nil;
	}
	if (edgeMeshGroupWeightsInCL) {
		clReleaseMemObject(edgeMeshGroupWeightsInCL);
		edgeMeshGroupWeightsInCL = nil;
	}
	
	if (nodeDistancesInCL) {
		clReleaseMemObject(nodeDistancesInCL);
		nodeDistancesInCL = nil;
	}
	
	if (edgeForceKernel) {
		clReleaseKernel(edgeForceKernel);
		edgeForceKernel = nil;
	}
	if (edgeCalcKernel) {
		clReleaseKernel(edgeCalcKernel);
		edgeCalcKernel = nil;
	}
	if (edgeSmoothKernel) {
		clReleaseKernel(edgeSmoothKernel);
		edgeSmoothKernel = nil;
	}
	if(nodeDistanceKernel) {
		clReleaseKernel(nodeDistanceKernel);
		nodeDistanceKernel = nil;
	}
	if (clQueue) {
		clReleaseCommandQueue(clQueue);
		clQueue = nil;
	}
	if (clContext) {
		clReleaseContext(clContext);
		clContext = nil;
	}
}

- (void)setupCLDeviceOfType:(cl_int)deviceType {
	NSLog(@"Setting up device of type %@.", deviceType == CL_DEVICE_TYPE_CPU ? @"CL_DEVICE_TYPE_CPU" : @"CL_DEVICE_TYPE_GPU");
	
	cl_int err;
	err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_CPU, 1, &clCPUDevice, NULL);
	assert(err == CL_SUCCESS);
	err = clGetDeviceIDs(NULL, deviceType, 1, &clDevice, NULL);
	if (err != CL_SUCCESS) {
		NSLog(@"Unable to setup device of type %@, falling back on CL_DEVICE_TYPE_CPU!", deviceType == CL_DEVICE_TYPE_CPU ? @"CL_DEVICE_TYPE_CPU" : @"CL_DEVICE_TYPE_GPU");
		
		clDevice = clCPUDevice;
	}
	
	clContext = clCreateContext(0, 1, &clDevice, clLogMessagesToStdoutAPPLE, NULL, &err);
	assert(err == CL_SUCCESS);
	
	clQueue = clCreateCommandQueue(clContext, clDevice, 0, NULL);
	
	NSError *errNS = nil;
	const char *program_source = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"EdgeKernels" ofType:@"cl"] encoding:NSASCIIStringEncoding error:&errNS] cStringUsingEncoding:NSASCIIStringEncoding];
	if (errNS)
		NSLog(@"%@", errNS);
	cl_program clProgram = clCreateProgramWithSource(clContext, 1, (const char**)&program_source,
													 NULL, &err);
	
	// "-cl-fast-relaxed-math"
	err = clBuildProgram(clProgram, 0, NULL, "", NULL, NULL);
	char log[10240];
	clGetProgramBuildInfo(clProgram, clDevice, CL_PROGRAM_BUILD_LOG, sizeof(char) * 10240, log, nil);
	if (err != CL_SUCCESS)
		NSLog(@"%s", log);
	assert(err == CL_SUCCESS);
	
	edgeForceKernel = clCreateKernel(clProgram, "EdgeForce", &err);
	assert(err == CL_SUCCESS);
	
	edgeCalcKernel = clCreateKernel(clProgram, "EdgeCalc", &err);
	assert(err == CL_SUCCESS);
	
	edgeSmoothKernel = clCreateKernel(clProgram, "EdgeSmooth", &err);
	assert(err == CL_SUCCESS);
	
	nodeDistanceKernel = clCreateKernel(clProgram, "NodeDistanceCalc", &err);
	assert(err == CL_SUCCESS);
	
    cl_ulong mem_size;
    clGetDeviceInfo(clDevice, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(mem_size), &mem_size, NULL);
    NSLog(@"CL_DEVICE_GLOBAL_MEM_SIZE:\t\t%u MByte\n", (unsigned int)(mem_size / (1024 * 1024)));

    clGetDeviceInfo(clDevice, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(mem_size), &mem_size, NULL);
    NSLog(@"CL_DEVICE_LOCAL_MEM_SIZE:\t\t%u KByte\n", (unsigned int)(mem_size / 1024));

    clGetDeviceInfo(clDevice, CL_DEVICE_MAX_MEM_ALLOC_SIZE, sizeof(clDeviceMaxMemAllocSize), &clDeviceMaxMemAllocSize, NULL);
    NSLog(@"CL_DEVICE_MAX_MEM_ALLOC_SIZE:\t\t%u MByte\n", (unsigned int)(clDeviceMaxMemAllocSize / (1024 * 1024)));
}

- (void)dealloc {
	[self reset];
    [nodeMetadata release];
	
	[self shutdownCLDevice];
	
	[super dealloc];
}

- (void)reset {
	if (edgeList) {
		free(edgeList);
		edgeList = nil;
	}
	if (edgeListInCL) {
		clReleaseMemObject(edgeListInCL);
		edgeListInCL = nil;
	}
	if (edgeWeights) {
		free(edgeWeights);
		edgeWeights = nil;
	}
	if (edgeWeightsInCL) {
		clReleaseMemObject(edgeWeightsInCL);
		edgeWeightsInCL = nil;
	}
	self.edgeCount = 0;
	self.meshCount = 2;
	
	if (edgeMeshes){
		free(edgeMeshes);
		edgeMeshes = nil;
	}
	if (edgeMeshesInCL) {
		clReleaseMemObject(edgeMeshesInCL);
		edgeMeshesInCL = nil;
	}
	if (edgeMeshVelocities) {
		free(edgeMeshVelocities);
		edgeMeshVelocities = nil;
	}
	if (edgeMeshVelocitiesInCL) {
		clReleaseMemObject(edgeMeshVelocitiesInCL);
		edgeMeshVelocitiesInCL = nil;
	}
    if (edgeMeshAccelerations) {
		free(edgeMeshAccelerations);
		edgeMeshAccelerations = nil;
	}
	if (edgeMeshAccelerationsInCL) {
		clReleaseMemObject(edgeMeshAccelerationsInCL);
		edgeMeshAccelerationsInCL = nil;
	}
	if (edgeCompats) {
		free(edgeCompats);
		edgeCompats = nil;
	}
	if (edgeCompatsInCL) {
		clReleaseMemObject(edgeCompatsInCL);
		edgeCompatsInCL = nil;
	}
	if (edgeDots) {
		free(edgeDots);
		edgeDots = nil;
	}
	if (edgeDotsInCL) {
		clReleaseMemObject(edgeDotsInCL);
		edgeDotsInCL = nil;
	}
	
	if (nodes) {
		free(nodes);
		nodes = nil;
	}
	self.nodeCount = 0;
    [nodeMetadata removeAllObjects];
	
	if (nodeDistances) {
		free(nodeDistances);
		nodeDistances = nil;
	}
	if (nodeDistancesInCL) {
		clReleaseMemObject(nodeDistancesInCL);
		nodeDistancesInCL = nil;
	}
	
	dataAspect = 1.0;
}

- (void)addNode:(float2)newNode withLabel:(NSString *)newLabel {
    [self addNode:newNode];
    
    if (newLabel)
        [nodeMetadata addObject:newLabel];
    else
        [nodeMetadata addObject:[NSString stringWithFormat:@"(%.3f, %.3f)", newNode.x, newNode.y]];
}

- (void)addNode:(float2)newNode {
	self.nodeCount += 1;
	int newIndex = nodeCount - 1;
	
	nodes = (float2 *)realloc(nodes, sizeof(float2) * nodeCount);
	nodes[newIndex] = newNode;
}

- (void)addEdgeFromIndex:(cl_uint)node1 toIndex:(cl_uint)node2 weight:(cl_float)weight {
	if (node1 < nodeCount && node2 < nodeCount) {
		cl_uint newEdgeCount = edgeCount + 1;
		cl_uint newIndex = newEdgeCount - 1;
		
		edgeList = (uint2 *)realloc(edgeList, sizeof(uint2) * newEdgeCount);
		edgeList[newIndex].x = node1;
		edgeList[newIndex].y = node2;
		edgeWeights = (cl_float *)realloc(edgeWeights, sizeof(cl_float) * newEdgeCount);
		edgeWeights[newIndex] = weight;
		if (edgeListInCL) {
			clReleaseMemObject(edgeListInCL);
			edgeListInCL = nil;
		}
		if (edgeWeightsInCL) {
			clReleaseMemObject(edgeWeightsInCL);
			edgeWeightsInCL = nil;
		}
		
		edgeMeshes = (float2 *)realloc(edgeMeshes, sizeof(float2) * newEdgeCount * meshCount);
		edgeMeshVelocities = (float2 *)realloc(edgeMeshVelocities, sizeof(float2) * newEdgeCount * meshCount);
        edgeMeshAccelerations = (float2 *)realloc(edgeMeshAccelerations, sizeof(float2) * newEdgeCount * meshCount);
		edgeMeshGroupWeights = (cl_float *)realloc(edgeMeshGroupWeights, sizeof(cl_float) * newEdgeCount * meshCount);
		cl_float dx = nodes[node2].x - nodes[node1].x;
		cl_float dy = nodes[node2].y - nodes[node1].y;
		for (cl_uint i = 0; i < meshCount; i++) {
			edgeMeshes[newIndex * meshCount + i].x = nodes[node1].x + dx * (cl_float)i / (cl_float)(meshCount - 1);
			edgeMeshes[newIndex * meshCount + i].y = nodes[node1].y + dy * (cl_float)i / (cl_float)(meshCount - 1);
			
			edgeMeshVelocities[newIndex * meshCount + i].x = 0.0f;
			edgeMeshVelocities[newIndex * meshCount + i].y = 0.0f;
            edgeMeshAccelerations[newIndex * meshCount + i].x = 0.0f;
			edgeMeshAccelerations[newIndex * meshCount + i].y = 0.0f;
			
			edgeMeshGroupWeights[newIndex * meshCount + i] = weight;
		}
		
		self.edgeCount = newEdgeCount;
		
		if (edgeMeshesInCL) {
			clReleaseMemObject(edgeMeshesInCL);
			edgeMeshesInCL = nil;
		}
		if (edgeMeshVelocitiesInCL) {
			clReleaseMemObject(edgeMeshVelocitiesInCL);
			edgeMeshVelocitiesInCL = nil;
		}
        if (edgeMeshAccelerationsInCL) {
			clReleaseMemObject(edgeMeshAccelerationsInCL);
			edgeMeshAccelerationsInCL = nil;
		}
		
		if(edgeMeshGroupWeightsInCL) {
			clReleaseMemObject(edgeMeshGroupWeightsInCL);
			edgeMeshGroupWeightsInCL = nil;
		}
	}
	else
		NSLog(@"Attempting to add an edge between node indicies that don't exist!");
}

- (void)loadGraphFromURL:(NSURL *)openURL {
	if ([openURL.pathExtension isEqual:@"graphml"])
		[self loadGraphMLFromURL:openURL];
	else if ([openURL.pathExtension isEqual:@"gexf"])
		[self loadGEXFFromURL:openURL];
}

- (void)loadGraphMLFromURL:(NSURL *)openURL {
	NSError *err = nil;
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:openURL
															  options:NSXMLDocumentTidyXML
																error:&err];
	
	[self reset];
	
	if (err) {
		NSLog(@"Unable to parse GraphML URL %@: %@", openURL, err);
        
        [doc release];
		return;
	}
	
	//NSMutableDictionary *edgesDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *nodesDict = [[NSMutableDictionary alloc] init];
	
	NSArray *nodeNodes = [doc nodesForXPath:@"/graphml/graph/node" error:nil];
	for (NSXMLElement *nodeElement in nodeNodes) {
		NSString *nodeID = [[nodeElement attributeForName:@"id"] objectValue];
		if (!nodeID)
			nodeID = [nodeElement description];
		
		NSString *newX = nil, *newY = nil, *label = nil;
		
		NSArray *dataNodes = [nodeElement nodesForXPath:@".//data" error:nil];
		for (NSXMLElement *dataElement in dataNodes) {
			NSXMLNode *dataAttributeNode = [dataElement attributeForName:@"key"];
			NSString *key = [dataAttributeNode objectValue];
			if ([key isEqual:@"x"])
				newX = [dataElement stringValue];
			else if ([key isEqual:@"y"])
				newY = [dataElement stringValue];
            else if ([key isEqual:@"tooltip"])
                label = [dataElement stringValue];
		}
		
		if (newX && newY)
		{
			float2 newNode;
			newNode.x = [newX floatValue];
			newNode.y = [newY floatValue];
			
			[self addNode:newNode withLabel:label];
			
			[nodesDict setObject:[NSNumber numberWithInt:nodeCount - 1] forKey:nodeID];
		}
	}
	
	[self scaleNodes];
	
	NSArray *edgeNodes = [doc nodesForXPath:@"/graphml/graph/edge" error:nil];
	for (NSXMLElement *edgeElement in edgeNodes) {
		NSString *edgeID = [[edgeElement attributeForName:@"id"] objectValue];
		if (!edgeID)
			edgeID = [edgeElement description];
		
		NSString *sourceID = [[edgeElement attributeForName:@"source"] objectValue];
		NSString *targetID = [[edgeElement attributeForName:@"target"] objectValue];
		
		NSNumber *sourceIndex;
		NSNumber *targetIndex;
		if (sourceID && targetID) {
			sourceIndex = [nodesDict objectForKey:sourceID];
			targetIndex = [nodesDict objectForKey:targetID];
			
			if (sourceIndex == targetIndex) {
				NSLog(@"Tried to form an loop edge. Ignoring. (NID: %@)", sourceID);
				continue;
			}
		}
		else {
			NSLog(@"Tried to load edge without a source or a target! (EID: %@)", edgeID);
			continue;
		}
		
		if(sourceIndex && targetIndex)
			[self addEdgeFromIndex:[sourceIndex intValue] toIndex:[targetIndex intValue] weight:1.0f];
		else
			NSLog(@"Tried to load edge between node IDs that dont exist! (%@, %@)", sourceID, targetID);
	}
	
	[self normalizeEdgeWeights];
	[self calcEdgeCompatibilities];
	
	[nodesDict release];
	[doc release];
    
    self.url = openURL;
    
    NSLog(@"Loaded %@. %i nodes, %i edges", openURL, nodeCount, edgeCount);
}

- (void)loadGEXFFromURL:(NSURL *)openURL {
	NSError *err = nil;
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:openURL
															  options:NSXMLDocumentTidyXML
																error:&err];
	
	[self reset];
	
	if (err) {
		NSLog(@"Unable to parse GEXF URL %@: %@", openURL, err);
        
        [doc release];
		return;
	}
	
	//NSMutableDictionary *edgesDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *nodesDict = [[NSMutableDictionary alloc] init];
	
	NSArray *nodeNodes = [doc nodesForXPath:@"/gexf/graph/nodes/node" error:nil];
	for (NSXMLElement *nodeElement in nodeNodes) {
		NSString *nodeID = [[nodeElement attributeForName:@"id"] objectValue];
		if (!nodeID)
			nodeID = [nodeElement description];
		
		NSString *newX = nil, *newY = nil;
		
		NSArray *dataNodes = [nodeElement nodesForXPath:@".//viz:position" error:nil];
		for (NSXMLElement *dataElement in dataNodes) {
			newX = [[dataElement attributeForName:@"x"] objectValue];
			newY = [[dataElement attributeForName:@"y"] objectValue];
		}
		
		if (newX && newY)
		{
			float2 newNode;
			newNode.x = [newX floatValue];
			newNode.y = [newY floatValue];
			
			[self addNode:newNode withLabel:[[nodeElement attributeForName:@"label"] objectValue]];
			
			[nodesDict setObject:[NSNumber numberWithInt:nodeCount - 1] forKey:nodeID];
		}
		else
			NSLog(@"Tried to load a node which didn't have coordinates specified! (NID: %@)", nodeID);
	}
	
	[self scaleNodes];
	
	NSArray *edgeNodes = [doc nodesForXPath:@"/gexf/graph/edges/edge" error:nil];
	for (NSXMLElement *edgeElement in edgeNodes) {
		NSString *edgeID = [[edgeElement attributeForName:@"id"] objectValue];
		if (!edgeID)
			edgeID = [edgeElement description];
		
		NSString *sourceID = [[edgeElement attributeForName:@"source"] objectValue];
		NSString *targetID = [[edgeElement attributeForName:@"target"] objectValue];
		
		NSNumber *sourceIndex;
		NSNumber *targetIndex;
		if (sourceID && targetID) {
			sourceIndex = [nodesDict objectForKey:sourceID];
			targetIndex = [nodesDict objectForKey:targetID];
			
			if (sourceIndex == targetIndex) {
				NSLog(@"Tried to form an loop edge. Ignoring. (NID: %@)", sourceID);
				continue;
			}
		}
		else {
			NSLog(@"Tried to load edge without a source or a target! (EID: %@)", edgeID);
			continue;
		}
		
		if(sourceIndex && targetIndex) {
			NSString *weightString = [[edgeElement attributeForName:@"weight"] objectValue];
			CGFloat weight = 1.0;
			
			if (weightString)
				weight = [weightString floatValue];
			[self addEdgeFromIndex:[sourceIndex intValue] toIndex:[targetIndex intValue] weight:weight];
		}
		else
			NSLog(@"Tried to load edge between node IDs that dont exist! (EID %@: NID %@ -> NID %@)", edgeID, sourceID, targetID);
	}
	
	[self normalizeEdgeWeights];
	[self calcEdgeCompatibilities];
	
	[nodesDict release];
	[doc release];
    
    self.url = openURL;
    
    NSLog(@"Loaded %@. %i nodes, %i edges", openURL, nodeCount, edgeCount);
}

@synthesize url;

- (void)loadDefaultGraph {
	[self reset];
	
	[self addNode:MakeFloat2(20, 20) withLabel:@"Lower Left"];
	[self addNode:MakeFloat2(20, 27) withLabel:@"Lower Right"];
	[self addNode:MakeFloat2(25, 27) withLabel:@"Upper Right"];
	[self addNode:MakeFloat2(25, 20) withLabel:@"Upper Left"];
	
	[self scaleNodes];
	
	[self addEdgeFromIndex:0 toIndex:1 weight:2.0];
	[self addEdgeFromIndex:2 toIndex:3 weight:1.0];
	
	[self normalizeEdgeWeights];
	[self calcEdgeCompatibilities];
}

- (void)setupTest5 {
	[self reset];
	
	[self addNode:MakeFloat2(0, 50)];
	[self addNode:MakeFloat2(0, -50)];
	[self addNode:MakeFloat2(50, 0)];
	[self addNode:MakeFloat2(-50, 0)];
	
	[self scaleNodes];
	
	[self addEdgeFromIndex:0 toIndex:1 weight:1.0];
	[self addEdgeFromIndex:2 toIndex:3 weight:1.0];
	//[self addEdgeFromIndex:0 toIndex:2 weight:1.0];
	//[self addEdgeFromIndex:1 toIndex:3 weight:1.0];
    
	[self normalizeEdgeWeights];
	[self calcEdgeCompatibilities];
}


@synthesize edgeMeshes;
@synthesize edgeWeights;
@synthesize edgeCount;
@synthesize meshCount;
@synthesize edgeMeshGroupWeights;
@synthesize edgeMeshGroupMaxCount;

@synthesize nodes;
@synthesize nodeMetadata;
@synthesize nodeCount;

@synthesize nodeSpringRestLength;
@synthesize nodeSpringConstant;
@synthesize edgeSpringConstant;
@synthesize edgeCoulombConstant;
@synthesize edgeLaneWidth;
@synthesize edgeMaxWidth;
@synthesize edgeMinWidth;
@synthesize bundleWidthPower;
@synthesize edgeCoulombDecay;

- (BOOL)useNewForce {
	return (BOOL)useNewForce;
}

- (void)setUseNewForce:(BOOL)val {
	useNewForce = (cl_int)val;
}

- (BOOL)useCompat {
	return (BOOL)useCompat;
}

- (void)setUseCompat:(BOOL)val {
	useCompat = (cl_int)val;
}

- (BOOL)useConnectCompat {
	return (BOOL)useCompat;
}

- (void)setUseConnectCompat:(BOOL)value {
	useConnectCompat = (cl_int)value;
}

@synthesize dataAspect;
@synthesize dataScale;
@synthesize velocityDamping;

- (void)calcNodeDistances {
	const size_t nodeCountTemp = nodeCount;
	cl_uint nodeDistancesSize = sizeof(cl_float) * (nodeCount * nodeCount - nodeCount) / 2;
	cl_uint edgeListSize = sizeof(uint2) * edgeCount;
    
    if (nodeDistancesSize >= clDeviceMaxMemAllocSize) {
        NSLog(@"Graph is too large to allocate all memory on current CL device. Switching to CPU.");
        self.useGPUDevice = FALSE;
    }
	
	nodeDistances = (cl_float *)realloc(nodeDistances, nodeDistancesSize);
	if (nodeDistancesInCL) {
		clReleaseMemObject(nodeDistancesInCL);
		nodeDistancesInCL = nil;
	}
	
	if (nodeCount <= 0)
		return;
	
	cl_int err;
	if (!edgeListInCL) {
		edgeListInCL = clCreateBuffer(clContext, CL_MEM_READ_ONLY, edgeListSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeListInCL, CL_TRUE, 0, edgeListSize,
								   (void *)edgeList, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!nodeDistancesInCL) {
		nodeDistancesInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nodeDistancesSize, NULL, &err);
		assert(err == CL_SUCCESS);
	}
	
	clFinish(clQueue);
	
	err = clSetKernelArg(nodeDistanceKernel, 0, sizeof(cl_mem), &edgeListInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(nodeDistanceKernel, 1, sizeof(cl_uint), &edgeCount);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(nodeDistanceKernel, 2, sizeof(cl_mem), &nodeDistancesInCL);
	assert(err == CL_SUCCESS);
	
	err = clEnqueueNDRangeKernel(clQueue, nodeDistanceKernel, 1, NULL, 
								 &nodeCountTemp, NULL, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
	err = clEnqueueReadBuffer(clQueue, nodeDistancesInCL, CL_TRUE, 0, nodeDistancesSize, 
							  nodeDistances, 0, NULL, NULL);
	assert(err == CL_SUCCESS);

#if DEBUG_PRINT
	printf("nodeDistances:\n");
	for (cl_uint i = 0; i < nodeCount; i++) {
		for (cl_uint j = i; j < nodeCount; j++) {
			if (i != j)
				printf("%.3f ", nodeDistances[TriIndex(i, j, nodeCount)]);
			else
				printf("%.3f ", 0.0f);

		}
		printf("\n");
	}
#endif
	
	clFinish(clQueue);
}

- (void)normalizeEdgeWeights {
	// TODO: NOTE THAT YOU HAVE TO RELOAD A GRAPH IF YOU ADD AN EDGE, since unnormalized values are forgotten
	cl_float maxWeight = 0.0f;
	for (cl_uint e = 0; e < edgeCount; e++) {
		if (fabs(edgeWeights[e]) > maxWeight)
			maxWeight = fabs(edgeWeights[e]);
	}
	
	if (maxWeight)
		for (cl_uint e = 0; e < edgeCount; e++) {
			edgeWeights[e] /= maxWeight;
			
			for(cl_uint i = 0; i < meshCount; i++) {
				edgeMeshGroupWeights[e * meshCount + i] = edgeWeights[e];
			}
		}
	
	edgeMeshGroupMaxCount = 1.0f; // After normaliztion, max weight is 1.
}

- (void)calcEdgeCompatibilities {
    NSDate *begin = [NSDate date];
    
	const size_t edgeCountTemp = edgeCount;
	cl_uint nodeDistancesSize = sizeof(cl_float) * (nodeCount * nodeCount - nodeCount) / 2;
	cl_uint edgeCalcSize = sizeof(cl_float) * (edgeCount * edgeCount - edgeCount) / 2;
	cl_uint edgePosSize = sizeof(float4) * edgeCount;
	cl_uint edgeListSize = sizeof(uint2) * edgeCount;
    
    if (edgeCalcSize >= clDeviceMaxMemAllocSize || nodeDistancesSize >= clDeviceMaxMemAllocSize) {
        NSLog(@"Graph is too large to allocate all memory on current CL device. Switching to CPU.");
        self.useGPUDevice = FALSE;
    }
	
	if (useConnectCompat)
		[self calcNodeDistances];
	else {
		// We need it to be an actual array, even if we don't use it.
		nodeDistances = (cl_float *)realloc(nodeDistances, nodeDistancesSize);
		if (nodeDistancesInCL) {
			clReleaseMemObject(nodeDistancesInCL);
			nodeDistancesInCL = nil;
		}
	}

	edgeCompats = (cl_float *)realloc(edgeCompats, edgeCalcSize);
	if (edgeCompatsInCL) {
		clReleaseMemObject(edgeCompatsInCL);
		edgeCompatsInCL = nil;
	}
	
	edgeDots = (cl_float *)realloc(edgeDots, edgeCalcSize);
	if (edgeDotsInCL) {
		clReleaseMemObject(edgeDotsInCL);
		edgeDotsInCL = nil;
	}
	
	if (edgeCount <= 0)
		return;
	
	float4 *edgePos = (float4 *)malloc(sizeof(float4) * edgeCount);
	
	// Look through the list of mesh points since it has the actual positions
	for (cl_uint e = 0; e < edgeCount; e++) {
		float2 *eMesh = &edgeMeshes[e * meshCount];
		
		edgePos[e].x = eMesh[0].x;
		edgePos[e].y = eMesh[0].y;
		edgePos[e].z = eMesh[meshCount - 1].x;
		edgePos[e].w = eMesh[meshCount - 1].y;
	}
	
	cl_int err;
	cl_mem edgePosInCL = clCreateBuffer(clContext, CL_MEM_READ_ONLY, edgePosSize, NULL, NULL);
	err = clEnqueueWriteBuffer(clQueue, edgePosInCL, CL_TRUE, 0, edgePosSize,
							   (void *)edgePos, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	if (!edgeCompatsInCL) {
		edgeCompatsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, edgeCalcSize, NULL, &err);
		assert(err == CL_SUCCESS);
	}
	if (!edgeDotsInCL) {
		edgeDotsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, edgeCalcSize, NULL, &err);
		assert(err == CL_SUCCESS);
	}
	if (!edgeListInCL) {
		edgeListInCL = clCreateBuffer(clContext, CL_MEM_READ_ONLY, edgeListSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeListInCL, CL_TRUE, 0, edgeListSize,
								   (void *)edgeList, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!nodeDistancesInCL) {
		nodeDistancesInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nodeDistancesSize, NULL, &err);
		err = clEnqueueWriteBuffer(clQueue, nodeDistancesInCL, CL_TRUE, 0, nodeDistancesSize,
								   (void *)nodeDistances, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	
	clFinish(clQueue);
	
	err = clSetKernelArg(edgeCalcKernel, 0, sizeof(cl_mem), &edgePosInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 1, sizeof(cl_mem), &edgeCompatsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 2, sizeof(cl_mem), &edgeDotsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 3, sizeof(cl_mem), &edgeListInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 4, sizeof(cl_mem), &nodeDistancesInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 5, sizeof(cl_uint), &nodeCount);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeCalcKernel, 6, sizeof(cl_int), &useConnectCompat);
	assert(err == CL_SUCCESS);
	
	err = clEnqueueNDRangeKernel(clQueue, edgeCalcKernel, 1, NULL, 
								 &edgeCountTemp, NULL, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
	err = clEnqueueReadBuffer(clQueue, edgeCompatsInCL, CL_TRUE, 0, edgeCalcSize, 
							  edgeCompats, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	err = clEnqueueReadBuffer(clQueue, edgeDotsInCL, CL_TRUE, 0, edgeCalcSize, 
							  edgeDots, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
	if (edgePosInCL) {
		clReleaseMemObject(edgePosInCL);
		edgePosInCL = nil;
	}
    
    NSLog(@"Calcuating compatibilities took %f seconds.", -[begin timeIntervalSinceNow]);
	
#if DEBUG_PRINT
	printf("edges:\n");
	for (cl_uint e = 0; e < edgeCount; e++) {
		cl_uint head = edgeList[e].x;
		cl_uint tail = edgeList[e].y;
		
		printf("%i\t(%.3f,%.3f)\t-[%.3f]-> (%.3f,%.3f)\n", (int)e, nodes[head].x, nodes[head].y, edgeWeights[e], nodes[tail].x, nodes[tail].y);
	}
	
	printf("\n");
	
	printf("edgeCompats:\n");
	for (cl_uint i = 0; i < edgeCount; i++) {
		for (cl_uint j = i; j < edgeCount; j++) {
			if (i != j)
				printf("%.3f ", edgeCompats[TriIndex(i, j, edgeCount)]);
			else
				printf("%.3f ", 1.0f);
		}
		printf("\n");
	}
/*	printf("edgeDots:\n");
	for (cl_uint i = 0; i < edgeCount; i++) {
		for (cl_uint j = 0; j < edgeCount; j++) {
			if (i != j)
				printf("%.3f ", edgeDots[TriIndex(i, j, edgeCount)]);
			else
				printf("eq ");

		}
		printf("\n");
	}
*/	
#endif
}

// Scale the positions of nodes so that the longest dimension is some dataScale units. This means that every graph can use the
//  same bundling parameters.
- (void)scaleNodes {
	if (!nodes)
		return;
	
	float2 max = {nodes[0].x, nodes[0].y};
	float2 min = {nodes[0].x, nodes[0].y};
	
	for (cl_uint i = 0; i < nodeCount; i++) {
		float2 point = nodes[i];
		if (point.x > max.x)
			max.x = point.x;
		else if (point.x < min.x)
			min.x = point.x;
		
		if (point.y > max.y)
			max.y = point.y;
		else if (point.y < min.y)
			min.y = point.y;
	}
	
/*    cl_float DX = max.x - min.x, DY = max.y - min.y;
	const cl_float margin = 0.1;
	max.x += fabs(margin * DX);
	min.x -= fabs(margin * DX);
	max.y += fabs(margin * DY);
	min.y -= fabs(margin * DY);
*/
	cl_float DX = max.x - min.x, DY = max.y - min.y;
	dataAspect = DX / DY;
	
	//NSRect bounds = NSMakeRect(0.0, 0.0, 1000.0, 1000.0);
	for (cl_uint i = 0; i < nodeCount; i++) {
		float2 point = nodes[i];
		
		if (dataAspect > 1.0) {
			nodes[i].x = (point.x - min.x) / DX * dataScale;
			nodes[i].y = (point.y - min.y) / DY * dataScale / dataAspect;
		}
		else {
			nodes[i].x = (point.x - min.x) / DX * dataScale * dataAspect;
			nodes[i].y = (point.y - min.y) / DY * dataScale;
		}
	}
}

- (void)simulateNodeStep:(cl_float)dt {

}

- (void)simulateEdgeStep:(cl_float)dt {
    [self simulateEdgeStep:dt backCopy:TRUE];
}

- (void)simulateEdgeStep:(cl_float)dt backCopy:(BOOL)backCopy {
	cl_uint unionMeshCount = edgeCount * meshCount;
	const size_t unionMeshCountTemp = unionMeshCount;
	cl_uint unionMeshSize = sizeof(float2) * unionMeshCount;
	cl_uint groupCountSize = sizeof(cl_float) * unionMeshCount;
	
	cl_uint edgeCalcSize = sizeof(cl_float) * (edgeCount * edgeCount - edgeCount) / 2;
    
    if (edgeCalcSize >= clDeviceMaxMemAllocSize || unionMeshSize >= clDeviceMaxMemAllocSize) {
        NSLog(@"Graph is too large to allocate all memory on current CL device. Switching to CPU.");
        self.useGPUDevice = FALSE;
    }
	
	cl_int err;
	if (!edgeMeshesInCL) {
		edgeMeshesInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, unionMeshSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeMeshesInCL, CL_TRUE, 0, unionMeshSize,
								   (void *)edgeMeshes, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeCompatsInCL) {
		edgeCompatsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, edgeCalcSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeCompatsInCL, CL_TRUE, 0, edgeCalcSize,
								   (void *)edgeCompats, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeDotsInCL) {
		edgeDotsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, edgeCalcSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeDotsInCL, CL_TRUE, 0, edgeCalcSize,
								   (void *)edgeDots, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeWeightsInCL) {
		edgeWeightsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, sizeof(cl_float) * edgeCount, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeWeightsInCL, CL_TRUE, 0, sizeof(cl_float) * edgeCount,
								   (void *)edgeWeights, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeMeshVelocitiesInCL) {
		edgeMeshVelocitiesInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, unionMeshSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeMeshVelocitiesInCL, CL_TRUE, 0, unionMeshSize,
								   (void *)edgeMeshVelocities, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeMeshAccelerationsInCL) {
		edgeMeshAccelerationsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, unionMeshSize, NULL, &err);
		assert(err == CL_SUCCESS);
		err = clEnqueueWriteBuffer(clQueue, edgeMeshAccelerationsInCL, CL_TRUE, 0, unionMeshSize,
								   (void *)edgeMeshAccelerations, 0, NULL, NULL);
		assert(err == CL_SUCCESS);
	}
	if (!edgeMeshGroupWeightsInCL) {
		edgeMeshGroupWeightsInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, groupCountSize, NULL, &err);
		assert(err == CL_SUCCESS);
	}
	
	clFinish(clQueue);
	
	err = clSetKernelArg(edgeForceKernel, 0, sizeof(cl_float), &dt);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 1, sizeof(cl_float), &edgeSpringConstant);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 2, sizeof(cl_float), &edgeCoulombConstant);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 3, sizeof(cl_float), &edgeLaneWidth);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 4, sizeof(cl_uint), &meshCount);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 5, sizeof(cl_mem), &edgeMeshesInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 6, sizeof(cl_mem), &edgeMeshVelocitiesInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 7, sizeof(cl_mem), &edgeMeshAccelerationsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 8, sizeof(cl_mem), &edgeCompatsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 9, sizeof(cl_mem), &edgeDotsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 10, sizeof(cl_mem), &edgeWeightsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 11, sizeof(cl_int), &useCompat);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 12, sizeof(cl_mem), &edgeMeshGroupWeightsInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 13, sizeof(cl_float), &velocityDamping);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 14, sizeof(cl_float), &edgeMaxWidth);
	assert(err == CL_SUCCESS);
    err = clSetKernelArg(edgeForceKernel, 15, sizeof(cl_float), &edgeMinWidth);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 16, sizeof(cl_float), &bundleWidthPower);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 17, sizeof(cl_float), &edgeMeshGroupMaxCount);
	assert(err == CL_SUCCESS);
    err = clSetKernelArg(edgeForceKernel, 18, sizeof(cl_int), &useNewForce);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeForceKernel, 19, sizeof(cl_float), &edgeCoulombDecay);
	assert(err == CL_SUCCESS);
	
	err = clEnqueueNDRangeKernel(clQueue, edgeForceKernel, 1, NULL, 
								 &unionMeshCountTemp, NULL, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
    if (backCopy) {
        err = clEnqueueReadBuffer(clQueue, edgeMeshesInCL, CL_TRUE, 0, unionMeshSize, 
                            edgeMeshes, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueReadBuffer(clQueue, edgeMeshVelocitiesInCL, CL_TRUE, 0, unionMeshSize, 
                                  edgeMeshVelocities, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueReadBuffer(clQueue, edgeMeshAccelerationsInCL, CL_TRUE, 0, unionMeshSize, 
                                  edgeMeshAccelerations, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueReadBuffer(clQueue, edgeMeshGroupWeightsInCL, CL_TRUE, 0, groupCountSize, 
                                  edgeMeshGroupWeights, 0, NULL, NULL);
        assert(err == CL_SUCCESS);

        clFinish(clQueue);

        edgeMeshGroupMaxCount = 0.0f;
        for (cl_uint i = 0; i < unionMeshCount; i++)
            if (edgeMeshGroupWeights[i] > edgeMeshGroupMaxCount)
                edgeMeshGroupMaxCount = edgeMeshGroupWeights[i];
    }
}

- (void)smoothEdgeMeshPoints {
	cl_uint unionMeshCount = edgeCount * meshCount;
	const size_t unionMeshCountTemp = unionMeshCount;
	cl_uint unionMeshSize = sizeof(float2) * unionMeshCount;
	
	cl_int err;
	if (!edgeMeshesInCL) {
		edgeMeshesInCL = clCreateBuffer(clContext, CL_MEM_READ_WRITE, unionMeshSize, NULL, &err);
		assert(err == CL_SUCCESS);
        // Don't copy in since the smoothing code writes every position form the originalEdgeMeshesInCL list.
		//err = clEnqueueWriteBuffer(clQueue, edgeMeshesInCL, CL_TRUE, 0, unionMeshSize,
		//						   (void *)edgeMeshes, 0, NULL, NULL);
		//assert(err == CL_SUCCESS);
	}
    cl_mem originalEdgeMeshesInCL = clCreateBuffer(clContext, CL_MEM_READ_ONLY, unionMeshSize, NULL, &err);
    assert(err == CL_SUCCESS);
    err = clEnqueueWriteBuffer(clQueue, originalEdgeMeshesInCL, CL_TRUE, 0, unionMeshSize,
    						   (void *)edgeMeshes, 0, NULL, NULL);
    assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
	err = clSetKernelArg(edgeSmoothKernel, 0, sizeof(cl_uint), &meshCount);
	assert(err == CL_SUCCESS);
    err = clSetKernelArg(edgeSmoothKernel, 1, sizeof(cl_mem), &originalEdgeMeshesInCL);
	assert(err == CL_SUCCESS);
	err = clSetKernelArg(edgeSmoothKernel, 2, sizeof(cl_mem), &edgeMeshesInCL);
	assert(err == CL_SUCCESS);
	
	err = clEnqueueNDRangeKernel(clQueue, edgeSmoothKernel, 1, NULL, 
								 &unionMeshCountTemp, NULL, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
	
	clFinish(clQueue);
	
	err = clEnqueueReadBuffer(clQueue, edgeMeshesInCL, CL_TRUE, 0, unionMeshSize, 
							  edgeMeshes, 0, NULL, NULL);
	assert(err == CL_SUCCESS);
    
    if (originalEdgeMeshesInCL) {
        clReleaseMemObject(originalEdgeMeshesInCL);
        originalEdgeMeshesInCL = nil;
    }
	
	clFinish(clQueue);
    
    // Run one step with no timestep so that bundle thicknesses are calculated properly.
    [self simulateEdgeStep:0.0f];
}

- (void)doubleEdgeMeshResolution {
	cl_uint newMeshCount = (meshCount - 1) * 2 + 1;
	float2 *newEdgeMeshes = (float2 *)malloc(sizeof(float2) * edgeCount * newMeshCount);
	float2 *newEdgeMeshVelocities = (float2 *)malloc(sizeof(float2) * edgeCount * newMeshCount);
    float2 *newEdgeMeshAccelerations = (float2 *)malloc(sizeof(float2) * edgeCount * newMeshCount);
	cl_float *newEdgeMeshGroupCounts = (cl_float *)malloc(sizeof(cl_float) * edgeCount * newMeshCount);
	
	for (cl_uint i = 0; i < newMeshCount * edgeCount; i++) {
		newEdgeMeshGroupCounts[i] = edgeWeights[(uint)(i / newMeshCount)];
		newEdgeMeshVelocities[i].x = 0.0f;
		newEdgeMeshVelocities[i].y = 0.0f;
        newEdgeMeshAccelerations[i].x = 0.0f;
		newEdgeMeshAccelerations[i].y = 0.0f;
	}
	
	// Go through every edge
	for (cl_uint e = 0; e < edgeCount; e++) {
		// these helper arrays are aligned to the mesh points correspoinding to edge e.
		float2 *oldEM = &edgeMeshes[e * meshCount];
		float2 *newEM = &newEdgeMeshes[e * newMeshCount];
		
		// go through every old mesh point
		for (cl_uint iOld = 0; iOld < meshCount - 1; iOld++) {
			// copy in the existing mesh points spaced out so there's room for the new ones
			newEM[iOld * 2] = oldEM[iOld];
			
			// put in the new one
			cl_float dx = oldEM[iOld + 1].x - oldEM[iOld].x;
			cl_float dy = oldEM[iOld + 1].y - oldEM[iOld].y;
			newEM[iOld * 2 + 1].x = oldEM[iOld].x + dx / 2.0f;
			newEM[iOld * 2 + 1].y = oldEM[iOld].y + dy / 2.0f;
		}
		
		// put in the last mesh point
		newEM[newMeshCount - 1] = oldEM[meshCount - 1];
	}
	
	self.meshCount = newMeshCount;
	
	if (edgeMeshes)
		free(edgeMeshes);
	edgeMeshes = newEdgeMeshes;
	if (edgeMeshVelocities)
		free(edgeMeshVelocities);
	edgeMeshVelocities = newEdgeMeshVelocities;
    if (edgeMeshAccelerations)
		free(edgeMeshAccelerations);
	edgeMeshAccelerations = newEdgeMeshAccelerations;
	if (edgeMeshGroupWeights)
		free(edgeMeshGroupWeights);
	edgeMeshGroupWeights = newEdgeMeshGroupCounts;
	
	// Set caches = nil so we know to copy them to the GPU next time.
	if (edgeMeshesInCL)
		clReleaseMemObject(edgeMeshesInCL);
	edgeMeshesInCL = nil;
	if (edgeMeshVelocitiesInCL)
		clReleaseMemObject(edgeMeshVelocitiesInCL);
	edgeMeshVelocitiesInCL = nil;
    if (edgeMeshAccelerationsInCL)
		clReleaseMemObject(edgeMeshAccelerationsInCL);
	edgeMeshAccelerationsInCL = nil;
	if (edgeMeshGroupWeightsInCL)
		clReleaseMemObject(edgeMeshGroupWeightsInCL);
	edgeMeshGroupWeightsInCL = nil;
}

- (void)setMeshPoint:(cl_uint)index toPosition:(float2)pos {
	if (index <= edgeCount * meshCount) {
		edgeMeshes[index] = pos;
		
		if (index % meshCount == 0 || index % meshCount == meshCount - 1) {
			cl_uint edgeIndex = index / meshCount, nodeIndex = -1;
			if (index % meshCount == 0)
				nodeIndex = edgeList[edgeIndex].x;
			else
				nodeIndex = edgeList[edgeIndex].y;
			nodes[nodeIndex] = pos;
		}
		
		// Set caches = nil so we know to copy them to the GPU next time.
		if (edgeMeshesInCL)
			clReleaseMemObject(edgeMeshesInCL);
		edgeMeshesInCL = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self calcEdgeCompatibilities];
}

@end
