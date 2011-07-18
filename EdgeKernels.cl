//
//  EdgeForce.cl
//  EdgeBundlingCL
//
//  Created by David Selassie on 12/14/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

uint TriIndex(uint,  uint,  uint);
float Length(float4);
float2 Midpoint(float4);
float2 Reduce(float4);
float4 ProjectOnto(float4, float4);
float AngleCompat(float4, float4);
float ScaleCompat(float4, float4);
float PosCompat(float4, float4);
float VisCompat(float4, float4);
float ConnectCompat(uint, __global uint2 *, __global float *, uint, uint);

uint TriIndex(uint row,  uint col,  uint N)
{
   if (row < col)
      return row * (N - 1) - (row - 1) * ((row - 1) + 1) / 2 + col - row - 1;
   else if (col < row)
      return col * (N - 1) - (col - 1) * ((col - 1) + 1) / 2 + row - col - 1;
   else
	  return 0;
      //printf("TRI ACCESS ERR\n");
}

float Length(float4 edge) {
	return distance((float2)(edge.x, edge.y), (float2)(edge.z, edge.w));
}

float2 Midpoint(float4 edge) {
	float dx = edge.z - edge.x;
	float dy = edge.w - edge.y;
	
	return (float2)(edge.x + dx / 2.0f, edge.y + dy / 2.0f);
}

float2 Reduce(float4 edge) {
	return (float2)(edge.z - edge.x, edge.w - edge.y);
}

float4 ProjectOnto(float4 one, float4 two) {
	float2 norm = normalize(Reduce(two));
	float2 toHead = (float2)(one.x - two.x, one.y - two.y);
	float2 toTail = (float2)(one.z - two.x, one.w - two.y);
	float2 headOnOther = norm * dot(norm, toHead);
	float2 tailOnOther = norm * dot(norm, toTail);
	
	float2 projHead = (float2)(two.x, two.y) + headOnOther;
	float2 projTail = (float2)(two.x, two.y) + tailOnOther;
	
	return (float4)(projHead.x, projHead.y, projTail.x, projTail.y);
}

float AngleCompat(float4 one, float4 two) {
	float lengthOne = Length(one);
	float lengthTwo = Length(two);
	
	if (lengthOne == 0.0f || lengthTwo == 0.0f)
		return 0.0f;
	
	float compat = dot(Reduce(one), Reduce(two)) / (lengthOne * lengthTwo);
	return fabs(compat);
}

float ScaleCompat(float4 one, float4 two) {
	float lengthOne = Length(one);
	float lengthTwo = Length(two);
	
	float avg = (lengthOne + lengthTwo) / 2.0f;
	
	if (avg == 0.0f)
		return 0.0f;
	
	// Mistake in original paper? The first denominator division befor MIN was written as multiplication.
	return 2.0f / (avg / min(lengthOne, lengthTwo) + max(lengthOne, lengthTwo) / avg);
}

float PosCompat(float4 one, float4 two) {
	float avg = (Length(one) + Length(two)) / 2.0f;
	
	if (avg == 0.0f)
		return 0.0f;

	return avg / (avg + distance(Midpoint(one), Midpoint(two)));
}

float VisCompat(float4 one, float4 two) {
	float4 I = ProjectOnto(one, two);
	float4 J = ProjectOnto(two, one);
	
	float Ilen = Length(I), Jlen = Length(J);
	
	// Another issue in original paper: perpendicular edges are trouble.
	// Just above 0 is OK because of the max calls below.
	if (Ilen == 0.0f || Jlen == 0.0f)
		return 0.0f;
	
	float midQmidI = distance(Midpoint(two), Midpoint(I));
	float VPQ = max(0.0f, 1.0f - (2.0f * midQmidI) / Ilen);
	
	float midPmidJ = distance(Midpoint(one), Midpoint(J));
	float VQP = max(0.0f, 1.0f - (2.0f * midPmidJ) / Jlen);
	
	return min(VPQ, VQP);
}

float ConnectCompat(uint nodeCount, __global uint2 *edgeListInCL, __global float *nodeDistancesInCL, uint oneEdgeIndex, uint twoEdgeIndex) {	
	uint oneHeadIndex = edgeListInCL[oneEdgeIndex].x;
	uint oneTailIndex = edgeListInCL[oneEdgeIndex].y;
	uint twoHeadIndex = edgeListInCL[twoEdgeIndex].x;
	uint twoTailIndex = edgeListInCL[twoEdgeIndex].y;
	
	if (oneHeadIndex == twoHeadIndex || oneHeadIndex == twoTailIndex ||
		oneTailIndex == twoHeadIndex || oneTailIndex == twoTailIndex)
		return 1.0f;

	float minPath = 
	min(nodeDistancesInCL[TriIndex(oneHeadIndex, twoHeadIndex, nodeCount)],
	min(nodeDistancesInCL[TriIndex(oneHeadIndex, twoTailIndex, nodeCount)],
	min(nodeDistancesInCL[TriIndex(oneTailIndex, twoHeadIndex, nodeCount)],
	nodeDistancesInCL[TriIndex(oneTailIndex, twoTailIndex, nodeCount)])));
	
	return 1.0f / (minPath + 1.0f);
}

__kernel void EdgeForce(
	float dtVal,
	float edgeSpringConstant,
	float edgeCoulombConstant,
	float edgeLaneWidth,
	uint meshCount, // Number of mesh points in each edge. We need to know so we don't spring force between edges.
	__global float2 *edgeMeshesInCL, // This is just one long list of all the mesh points from every edge.
	__global float2 *edgeMeshVelocitiesInCL,
	__global float2 *edgeMeshAccelerationsInCL,
	__global float *edgeCompatsInCL,
	__global float *edgeDotsInCL,
	__global float *edgeWeightsInCL,
	int useCompat,
	__global float *edgeMeshGroupWeightsInCL,
	float velocityDamping,
	float edgeMaxWidth,
    float edgeMinWidth,
	float bundleWidthPower,
	float edgeMeshGroupMaxCount,
    int useNewForce,
    float edgeCoulombDecay
	) {
	
	uint globalPointIndex = get_global_id(0);
	uint edgeCount = get_global_size(0) / meshCount;
	
	uint edgeIndex = (uint)(globalPointIndex / meshCount);	// index of the edge this mesh point is part of
	float edgeWeight = edgeWeightsInCL[edgeIndex];
	
	// TODO: use fast local memory?

	// Start with this point being in its own group, then see if it joins any other groups as you force.
	float pointGroupWeight = edgeWeight;
        
    uint edgePointIndex = globalPointIndex % meshCount;
        
    float2 pointPos = edgeMeshesInCL[globalPointIndex];
    float2 pointVelocity = edgeMeshVelocitiesInCL[globalPointIndex];
    float2 pointAcceleration = edgeMeshAccelerationsInCL[globalPointIndex];
        
    // Integrate ===============================
    float2 dt = (float2)(dtVal, dtVal);
    
    pointVelocity += pointAcceleration * dt / 2.0f;
    pointVelocity *= velocityDamping;
    pointPos += pointVelocity * dt;
    edgeMeshesInCL[globalPointIndex] = pointPos;

	// Force ===================================
    pointAcceleration = (float2)(0.0f, 0.0f);
	
	// Spring ------------------------------
	float2 pointAdjPos = edgeMeshesInCL[globalPointIndex - 1];
	float2 dr = pointAdjPos - pointPos;
	float dist = sqrt(dr.x * dr.x + dr.y * dr.y);
	float force = edgeSpringConstant / 1000.0f * (meshCount - 1) * dist * edgeWeight;
	pointAcceleration += force * normalize(dr);
	
	pointAdjPos = edgeMeshesInCL[globalPointIndex + 1];
	dr = pointAdjPos - pointPos;
	dist = sqrt(dr.x * dr.x + dr.y * dr.y);
	force = edgeSpringConstant / 1000.0f * (meshCount - 1) * dist * edgeWeight;
	pointAcceleration += force * normalize(dr);
	
	// Coulomb ---------------------------
	// correct to the same average charge density.
	edgeCoulombConstant /= sqrt((float)edgeCount);
        
	for (uint otherEdgeIndex = 0; otherEdgeIndex < edgeCount; otherEdgeIndex++) {
		if (edgeIndex == otherEdgeIndex)
			continue;
        
        float otherCompat = edgeCompatsInCL[TriIndex(edgeIndex, otherEdgeIndex, edgeCount)];
        if (useCompat && otherCompat <= 0.05)
            continue;
			
		float edgeDot = edgeDotsInCL[TriIndex(edgeIndex, otherEdgeIndex, edgeCount)];
		float otherEdgeWeight = edgeWeightsInCL[otherEdgeIndex];
		
		uint globalOtherPointIndex;
		if (edgeDot >= 0.0f)
			globalOtherPointIndex = otherEdgeIndex * meshCount + edgePointIndex;
		else
			globalOtherPointIndex = otherEdgeIndex * meshCount + meshCount - 1 - edgePointIndex;
		
		float2 otherPointPos;
		// If we're going the same direction is edge1, then the potential minimum is at the point.
		if (edgeDot >= 0.0f)
			otherPointPos = edgeMeshesInCL[globalOtherPointIndex];
		// If we're going the opposite direction, the potential minimum is edgeLaneWidth to the "right."
		else {
			float2 tangent = normalize(edgeMeshesInCL[globalOtherPointIndex + 1] - edgeMeshesInCL[globalOtherPointIndex - 1]);
			float2 normal = (float2)(-tangent.y, tangent.x);
			otherPointPos = edgeMeshesInCL[globalOtherPointIndex] + normal * edgeLaneWidth;
		}
		
		dr = otherPointPos - pointPos;
		dist = sqrt(dr.x * dr.x + dr.y * dr.y);
		
		// If the point is on an edge that is being attracted directly to the other point and it's close enough,
		//	(depending on the size of the other bundle) say they're in the same group.
        float maxGroupRadius = pow(edgeWeight, bundleWidthPower) * edgeMaxWidth;
        
		if (edgeDot >= 0.0f && (dist <= edgeMinWidth || dist <= maxGroupRadius))
			pointGroupWeight += otherEdgeWeight;
        
        // If an immovable point, stop before force calculations. We only want to be adding up the weigts of other control points.
        if (edgePointIndex <= 0 || edgePointIndex >= meshCount - 1)
            continue;
		
        // Inverse force.
        if (!useNewForce)
            force = edgeCoulombConstant * 30.0f / (meshCount - 1) / (dist + 0.01f);
        // New force.
        else
            force = 4.0f * 10000.0f / (meshCount - 1) * edgeCoulombDecay * edgeCoulombConstant * dist / (3.1415926f * pown(edgeCoulombDecay * edgeCoulombDecay + dist * dist, 2));
		force *= otherEdgeWeight;
		
		if (useCompat)
			force *= otherCompat;

		pointAcceleration += force * normalize(dr);	// Mass is 1
	}
    // If an immovable point, skip integration.
    if (!(edgePointIndex <= 0 || edgePointIndex >= meshCount - 1)) {
        pointVelocity += pointAcceleration * dt / 2.0f;
        edgeMeshVelocitiesInCL[globalPointIndex] = pointVelocity;
        edgeMeshAccelerationsInCL[globalPointIndex] = pointAcceleration;
    }

    edgeMeshGroupWeightsInCL[globalPointIndex] = pointGroupWeight;
}

__kernel void EdgeCalc(
	__global float4 *edgePosInCL,
	__global float *edgeCompatsInCL,
	__global float *edgeDotsInCL,
	__global uint2 *edgeListInCL,
	__global float *nodeDistancesInCL,
	uint nodeCount,
	uint useConnectCompat
	) {
	uint globalEdgeIndex = get_global_id(0);
	uint edgeCount = get_global_size(0);
	
	float4 edge1 = edgePosInCL[globalEdgeIndex];
	float2 reduceNormEdge1 = normalize(Reduce(edge1));
	
	for (uint otherGlobalEdgeIndex = globalEdgeIndex + 1; otherGlobalEdgeIndex < edgeCount; otherGlobalEdgeIndex++) {
			
		float4 edge2 = edgePosInCL[otherGlobalEdgeIndex];
		
		float compat = 1.0f;
		compat *= AngleCompat(edge1, edge2);
		compat *= ScaleCompat(edge1, edge2);
		compat *= PosCompat(edge1, edge2);
		compat *= VisCompat(edge1, edge2);
		
		if (useConnectCompat)
			compat *= ConnectCompat(nodeCount, edgeListInCL, nodeDistancesInCL, globalEdgeIndex, otherGlobalEdgeIndex);
		
		float dotVal = dot(reduceNormEdge1, normalize(Reduce(edge2)));
			
		edgeCompatsInCL[TriIndex(globalEdgeIndex, otherGlobalEdgeIndex, edgeCount)] = compat;
		edgeDotsInCL[TriIndex(globalEdgeIndex, otherGlobalEdgeIndex, edgeCount)] = dotVal;
	}
}

__kernel void NodeDistanceCalc(
	__global uint2 *edgeListInCL,
	uint edgeCount,
	__global float *nodeDistancesInCL
	) {
	// Bellman-Ford Algorithm
	
	uint sourceIndex = get_global_id(0);
	uint nodeCount = get_global_size(0);
	
	for (uint j = sourceIndex + 1; j < nodeCount; j++)
		nodeDistancesInCL[TriIndex(sourceIndex, j, nodeCount)] = INFINITY;
	
	for (uint j = 0; j < nodeCount; j++) {
		for (uint e = 0; e < edgeCount; e++) {
			 uint headIndex = edgeListInCL[e].x;
			 uint tailIndex = edgeListInCL[e].y;
			
			if (tailIndex == sourceIndex)
				continue;
			
			// Do this becaue this is a triangular array which does not include the diagonal. On the diagonal nodeDistances = 0.
			float sum = 1.0f;
			if (sourceIndex != headIndex)
				sum = nodeDistancesInCL[TriIndex(sourceIndex, headIndex, nodeCount)] + 1.0f;
				
			if (sum < nodeDistancesInCL[TriIndex(sourceIndex, tailIndex, nodeCount)])
				nodeDistancesInCL[TriIndex(sourceIndex, tailIndex, nodeCount)] = sum;
		}
	}
}

__kernel void EdgeSmooth(
	 uint meshCount,
    __global float2 *originalEdgeMeshesInCL,
	__global float2 *edgeMeshesInCL
	) {
	// From Mathematica Total[GaussianMatrix[{3, 3}]]
	const uint kernelSize = 3;
	// Has to sum to 1.0 to be correct.
	const float gaussianKernel[] = {0.10468, 0.139936, 0.166874, 0.177019, 0.166874, 0.139936, 0.10468};
	
	uint globalPointIndex = get_global_id(0);
	
	uint edgePointIndex = globalPointIndex % meshCount;
	if (edgePointIndex <= 0 || edgePointIndex >= meshCount - 1) {
		edgeMeshesInCL[globalPointIndex] = originalEdgeMeshesInCL[globalPointIndex];
		return;
	}

	float2 smoothedPointPos = (float2)(0.0f, 0.0f);
	
	for (uint kernelIndex = 0; kernelIndex <= kernelSize * 2 + 1; kernelIndex++) {
		int smoothPointEdgeIndex = (int)edgePointIndex + (int)kernelIndex - (int)kernelSize;
		if(smoothPointEdgeIndex < 0)
			smoothPointEdgeIndex = 0;
		else if ((uint)smoothPointEdgeIndex >= meshCount)
			smoothPointEdgeIndex = meshCount - 1;
			
		 uint smoothPointGlobalIndex = globalPointIndex - edgePointIndex + smoothPointEdgeIndex;
			
		smoothedPointPos += gaussianKernel[kernelIndex] * originalEdgeMeshesInCL[smoothPointGlobalIndex];
	}
	
	edgeMeshesInCL[globalPointIndex] = smoothedPointPos;
}
