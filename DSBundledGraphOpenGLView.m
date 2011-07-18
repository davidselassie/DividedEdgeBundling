//
//  DSBundledGraphView.m
//  EdgeBundling
//
//  Created by David Selassie on 12/16/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DSBundledGraphOpenGLView.h"

#import "NSPointExtensions.h"

void glDrawRectLine2vf(GLfloat i[2], GLfloat j[2], GLfloat widthi, GLfloat widthj) {
	GLfloat r[2] = {j[0] - i[0], j[1] - i[1]};
	GLfloat rmag = sqrtf(r[0] * r[0] + r[1] * r[1]);
	GLfloat nr[2] = {r[0] / rmag, r[1] / rmag};
	GLfloat nt[2] = {nr[1], -nr[0]};
	
	glBegin(GL_QUADS);
		glVertex2f(i[0] - nt[0] * widthi / 2.0, i[1] - nt[1] * widthi / 2.0);
		glVertex2f(i[0] + nt[0] * widthi / 2.0, i[1] + nt[1] * widthi / 2.0);
		glVertex2f(j[0] + nt[0] * widthj / 2.0, j[1] + nt[1] * widthj / 2.0);
		glVertex2f(j[0] - nt[0] * widthj / 2.0, j[1] - nt[1] * widthj / 2.0);
	glEnd();
}

NSXMLElement *svgRectLine2vf(GLfloat i[2], GLfloat j[2], GLfloat widthi, GLfloat widthj) {
	GLfloat r[2] = {j[0] - i[0], j[1] - i[1]};
	GLfloat rmag = sqrtf(r[0] * r[0] + r[1] * r[1]);
	GLfloat nr[2] = {r[0] / rmag, r[1] / rmag};
	GLfloat nt[2] = {nr[1], -nr[0]};
	
	NSXMLElement *poly = [[NSXMLElement alloc] initWithName:@"polygon"];
    [poly addAttribute:[NSXMLNode attributeWithName:@"points" stringValue:[NSString stringWithFormat:@"%.2f,%.2f %.2f,%.2f %.2f,%.2f %.2f,%.2f", i[0], i[1] + widthi, i[0], i[1] - widthi, i[0] + rmag, i[1] - widthj, i[0] + rmag, i[1] + widthj]]];
    [poly addAttribute:[NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"rotate(%.2f %.2f %.2f)", atan2f(j[1] - i[1], j[0] - i[0]) * 90.0 / M_PI_2, i[0], i[1]]]];
    
    return [poly autorelease];
}

/*NSXMLElement *svgSealedRectLine2vf(GLfloat h[2], GLfloat i[2], GLfloat j[2], GLfloat k[2], GLfloat c1[4], GLfloat c2[4], GLfloat widthi, GLfloat widthj) {
	GLfloat hi[2] = {i[0] - h[0], i[1] - h[1]};
    GLfloat ij[2] = {j[0] - i[0], j[1] - i[1]};
    GLfloat jk[2] = {k[0] - j[0], k[1] - j[1]};
	GLfloat hi_mag = sqrtf(hi[0] * hi[0] + hi[1] * hi[1]);
    GLfloat ij_mag = sqrtf(ij[0] * ij[0] + ij[1] * ij[1]);
    GLfloat jk_mag = sqrtf(jk[0] * jk[0] + jk[1] * jk[1]);
	GLfloat hij_bisect[2] = {hi[0] * ij_mag + ij[0] * hi_mag, hi[1] * ij_mag + ij[1] * hi_mag};
    GLfloat hij_bisect_mag = sqrtf(hij_bisect[0] * hij_bisect[0] + hij_bisect[1] * hij_bisect[1]);
    GLfloat n_hij_bisect[2] = {hij_bisect[0] / hij_bisect_mag, hij_bisect[1] / hij_bisect_mag};
    GLfloat ijk_bisect[2] = {ij[0] * jk_mag + jk[0] * ij_mag, ij[1] * jk_mag + jk[1] * ij_mag};
    GLfloat ijk_bisect_mag = sqrtf(ijk_bisect[0] * ijk_bisect[0] + ijk_bisect[1] * ijk_bisect[1]);
    GLfloat n_ijk_bisect[2] = {ijk_bisect[0] / ijk_bisect_mag, ijk_bisect[1] / ijk_bisect_mag};
	
	NSXMLElement *poly = [[NSXMLElement alloc] initWithName:@"polygon"];
    [poly addAttribute:[NSXMLNode attributeWithName:@"points" stringValue:[NSString stringWithFormat:@"%f,%f %f,%f %f,%f %f,%f", i[0], i[1] + widthi, i[0], i[1] - widthi, i[0] + ij_mag, i[1] - widthj, i[0] + ij_mag, i[1] + widthj]]];
    [poly addAttribute:[NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"rotate(%f %f %f)", atan2f(j[1] - i[1], j[0] - i[0]) * 90.0 / M_PI_2, i[0], i[1]]]];
    
    return [poly autorelease];
}*/

void glDrawRectLineColor2vf(GLfloat i[2], GLfloat j[2], GLfloat c1[4], GLfloat c2[4], GLfloat widthi, GLfloat widthj) {
	GLfloat r[2] = {j[0] - i[0], j[1] - i[1]};
	GLfloat rmag = sqrtf(r[0] * r[0] + r[1] * r[1]);
	GLfloat nr[2] = {r[0] / rmag, r[1] / rmag};
	GLfloat nt[2] = {nr[1], -nr[0]};
	
	glBegin(GL_QUADS);
		glColor4fv(c1);
		glVertex2f(i[0] - nt[0] * widthi, i[1] - nt[1] * widthi);
		glVertex2f(i[0] + nt[0] * widthi, i[1] + nt[1] * widthi);
		glColor4fv(c2);
		glVertex2f(j[0] + nt[0] * widthj, j[1] + nt[1] * widthj);
		glVertex2f(j[0] - nt[0] * widthj, j[1] - nt[1] * widthj);
	glEnd();
}

/*void glDrawStripRectLineColor2vf(GLfloat h[2], GLfloat i[2], GLfloat j[2], GLfloat k[2], GLfloat c1[4], GLfloat c2[4], GLfloat widthi, GLfloat widthj) {
	GLfloat r[2] = {j[0] - i[0], j[1] - i[1]};
	GLfloat rmag = sqrtf(r[0] * r[0] + r[1] * r[1]);
	GLfloat nr[2] = {r[0] / rmag, r[1] / rmag};
	GLfloat nt[2] = {nr[1], -nr[0]};
	
    glColor4fv(c1);
    glVertex2f(i[0] - nt[0] * widthi, i[1] - nt[1] * widthi);
    glVertex2f(i[0] + nt[0] * widthi, i[1] + nt[1] * widthi);
    glColor4fv(c2);
    glVertex2f(j[0] + nt[0] * widthj, j[1] + nt[1] * widthj);
    glVertex2f(j[0] - nt[0] * widthj, j[1] - nt[1] * widthj);
}*/

@implementation DSBundledGraphOpenGLView

+ (NSOpenGLPixelFormat *) defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)1,
		NSOpenGLPFAMultisample,
		NSOpenGLPFASampleBuffers, (NSOpenGLPixelFormatAttribute)1,
		NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute)8,
        (NSOpenGLPixelFormatAttribute)0 // nil
    };
	
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame pixelFormat:[DSBundledGraphOpenGLView defaultPixelFormat]])) {
		self.nodeSize = 5;
		self.edgeAlpha = 0.75;
        self.edgeDeselectAlpha = 0.05;
		self.edgeColorType = 1;
		self.showMesh = FALSE;
		self.showNodes = TRUE;
		
		self.dataSource = nil;
        
        self.selectedNodeIndex = -1;
        self.selectedMeshIndex = -1;
		
		viewAspect = self.bounds.size.width / self.bounds.size.height;
		self.scale = 0.9f;
		pan.x = mouseDown.x = 0.0f;
		pan.y = mouseDown.y = 0.0f;
		
		[self addObserver:self forKeyPath:@"nodeSize" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"edgeAlpha" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"edgeDeselectAlpha" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"edgeColorType" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"showMesh" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"showNodes" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"flipY" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"scale" options:NSKeyValueObservingOptionNew context:nil];
    }
	
    return self;
}

- (void)dealloc {
    if (disk)
        gluDeleteQuadric(disk);
    
    if (selectedEdges)
        free(selectedEdges);
}

// Called by super.
- (void)prepareOpenGL
{
	GLint swapInterval = 1;
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
	
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glPixelZoom(1.0, 1.0);
	glShadeModel(GL_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glEnable(GL_POINT_SMOOTH);
//	glEnable(GL_POLYGON_SMOOTH);
//	glEnable(GL_LINE_SMOOTH);
//	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
//	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
//	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
	glEnable(GL_MULTISAMPLE_ARB);
    glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
	
	glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
    
    disk = gluNewQuadric();
}

- (void)setDataSource:(id)object {
	if (dataSource) {
		[self removeObserver:self forKeyPath:@"bundleWidthPower"];
		[self removeObserver:self forKeyPath:@"edgeMaxWidth"];
	}
	
	dataSource = object;
	
	if (dataSource) {
		[dataSource addObserver:self forKeyPath:@"bundleWidthPower" options:NSKeyValueObservingOptionNew context:nil];
		[dataSource addObserver:self forKeyPath:@"edgeMaxWidth" options:NSKeyValueObservingOptionNew context:nil];
        [dataSource addObserver:self forKeyPath:@"edgeMinWidth" options:NSKeyValueObservingOptionNew context:nil];
	}
}

- (id)dataSource {
    return dataSource;
}

@synthesize nodeSize;
@synthesize edgeAlpha;
@synthesize edgeDeselectAlpha;
@synthesize edgeColorType;
@synthesize showMesh;
@synthesize showNodes;

@synthesize selectedMeshIndex;
@synthesize selectedNodeIndex;

+ (NSSet *)keyPathsForValuesAffectingSelectedNodeLabel {
    return [NSSet setWithObjects:@"selectedNodeIndex", nil];
}

+ (NSSet *)keyPathsForValuesAffectingSelectedMeshGroupID {
    return [NSSet setWithObjects:@"selectedMeshIndex", nil];
}

- (NSString *)selectedNodeLabel {
    if (selectedNodeIndex >= 0)
        return [[dataSource nodeMetadata] objectAtIndex:selectedNodeIndex];
    else
        return nil;
}

- (cl_float)selectedMeshGroupWeight {
    if (selectedMeshIndex >= 0)
        return [dataSource edgeMeshGroupWeights][selectedMeshIndex];
    else
        return -1.0;
}

- (void)update {
   	[super update];
    
	glViewport(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
	
	viewAspect = self.bounds.size.width / self.bounds.size.height;
}

- (void)drawRect:(NSRect)dirtyRect {
	glClear(GL_COLOR_BUFFER_BIT);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	cl_float dataAspect = [dataSource dataAspect];
	cl_float dataScale = [dataSource dataScale];
	
    //NSLog(@"dataA = %f", dataAspect);
    //NSLog(@"viewA = %f", viewAspect);
    //NSLog(@"dataS = %f", dataScale);
    
    // "Landscape" data
	if (dataAspect >= 1.0f && dataAspect <= viewAspect) {
		viewSize.x = dataScale / dataAspect * viewAspect;
		viewSize.y = dataScale / dataAspect;
	}
	else if (dataAspect >= 1.0f && dataAspect > viewAspect) {
		viewSize.x = dataScale;
		viewSize.y = dataScale / viewAspect;
	}
    // "Portrait" data
	else if (dataAspect <= viewAspect) {
		viewSize.x = dataScale * viewAspect;
		viewSize.y = dataScale;
	}
	else {
		viewSize.x = dataScale * dataAspect;
		viewSize.y = dataScale * dataAspect / viewAspect;
	}

    GLfloat lowX = 0.0, highX = viewSize.x;
    GLfloat lowY = 0.0, highY = viewSize.y;
    
    GLfloat DX = highX - lowX, DY = highY - lowY;
    center.x = lowX + (DX / 2.0), center.y = lowY + (DY / 2.0);
    
//    NSLog(@"center = (%f, %f)", centerX, centerY);
//    NSLog(@"D = (%f, %f)", DX, DY);
    
    // Zoom in on the center of the original view.
    lowX = center.x - DX / (scale * 2.0) - pan.x;
    highX = center.x + DX / (scale * 2.0) - pan.x;
    lowY = center.y - DY / (scale * 2.0) - pan.y;
    highY = center.y + DY / (scale * 2.0) - pan.y;
    
//    NSLog(@"X = (%f, %f)", lowX, highX);
//    NSLog(@"Y = (%f, %f)", lowY, highY);
    
//    NSLog(@"pan = (%f, %f)", pan.x, pan.y);
    
    currentViewRect.origin.x = lowX;
    currentViewRect.origin.y = lowY;
    currentViewRect.size.width = highX - lowX;
    currentViewRect.size.height = highY - lowY;
    
	glOrtho(lowX, highX, lowY, highY, 0.0f, 1.0f);
	
	glMatrixMode(GL_MODELVIEW);
	
	glPushMatrix();
	
    // Load all of the data from the structure.
	cl_uint edgeCount = [dataSource edgeCount];
	cl_uint meshCount = [dataSource meshCount];
	float2 *edgeMeshes = [dataSource edgeMeshes];
	cl_float *edgeMeshGroupWeights = [dataSource edgeMeshGroupWeights];
	
	cl_float maxGroupCount = [dataSource edgeMeshGroupMaxCount];
	
	cl_float edgeMaxWidth = [dataSource edgeMaxWidth];
    cl_float edgeMinWidth = [dataSource edgeMinWidth];
	cl_float bundleWidthPower = [dataSource bundleWidthPower];
	
	//NSLog(@"BEGIN FRAME");
	
	// Draw unselected edges on bottom, so first.
    if (selectedEdges)
        for (cl_uint i = 1; i < edgeCount * meshCount; i++) {
            cl_uint edgeIndex = i % meshCount;	// Index WITHIN this edge.
            cl_uint e = i / meshCount;	// Index of edge that this mesh point belongs to.
            
            float2 *point = &edgeMeshes[i];
            float2 *lastPoint = &edgeMeshes[i - 1];
            
            cl_float groupCount = edgeMeshGroupWeights[i];
            cl_float lastGroupCount = edgeMeshGroupWeights[i - 1];

            if (edgeIndex == 0)
                continue;
            
            // If we've selected edges and this edge isn't one of them. Draw it in grey.
            if (selectedEdges[e])
                continue;
            glColor4f(0.5, 0.5, 0.5, edgeDeselectAlpha);
            
            GLfloat lastWidth = powf(lastGroupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
            GLfloat width = powf(groupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
            
            if (lastWidth < edgeMinWidth)
                lastWidth = edgeMinWidth;
            if (width < edgeMinWidth)
                width = edgeMinWidth;
            
            glDrawRectLine2vf((GLfloat *)lastPoint,
                              (GLfloat *)point,
                              lastWidth,
                              width);
        }
    
	for (cl_uint i = 1; i < edgeCount * meshCount; i++) {
		cl_uint edgeIndex = i % meshCount;	// Index WITHIN this edge.
		cl_uint e = i / meshCount;	// Index of edge that this mesh point belongs to.
		
		float2 *point = &edgeMeshes[i];
		float2 *lastPoint = &edgeMeshes[i - 1];
		
		cl_float groupCount = edgeMeshGroupWeights[i];
		cl_float lastGroupCount = edgeMeshGroupWeights[i - 1];
		
		//NSLog(@"counts: (%.3f, %.3f) / %.3f", lastGroupCount, groupCount, maxGroupCount);
        
        // Since the edges are drawn as many line segments connecting the last mesh point to the current one, skip everything if we're drawing the first mesh point in an edge. It'll get drawn when it is connected to the second mesh point in the next cycle.
        if (edgeIndex == 0)
			continue;
		
        // Draw mesh points if necessary. Don't draw them if they'll overlap with a node (be the first or last mesh point).
		if (showMesh && edgeIndex > 0 && edgeIndex < meshCount - 1) {
			glColor4f(0.0f, 0.0f, 0.0f, 0.25f);
			glPushMatrix();
			glTranslatef(point->x, point->y, 0.0f);
            if (i == selectedMeshIndex)
                gluDisk(disk, nodeSize / 2.0 * 0.75, nodeSize / 2.0 * 1.75, 8, 1);
            else
                gluDisk(disk, 0.0, nodeSize / 2.0, 8, 1);
			glPopMatrix();
		}
		
        // If we've selected edges and this edge isn't one of them, we drew it above so skip it now.
        if (selectedEdges && !selectedEdges[e])
            continue;
        // If we chose angle hue based coloring.
		else if (edgeColorType == 0) {
			float2 *eMesh = &edgeMeshes[e * meshCount];
			NSPoint head = Float2ToNSPoint(eMesh[0]);
			NSPoint tail = Float2ToNSPoint(eMesh[meshCount - 1]);
			CGFloat plusDotHue = (NSPointDotProduct(NSPointNormalizedVectorTowards(head, tail),
										NSMakePoint(1.0, 0.0)) + 1.0) / 4.0 * 6.0;
		
			// Hue for direction. Doesn't really work on its own, as you know two edges are going in different directions, but not specifics.
			// See http://en.wikipedia.org/wiki/HSV_color_space#From_HSV for definition.
			CGFloat hue[4] = {0.0, 0.0, 0.0, edgeAlpha};
			CGFloat x = (1.0 - fabs(fmod(plusDotHue, 2.0) - 1.0));
			switch ((int)plusDotHue) {
				case 0:
					hue[0] = 1.0;
					hue[1] = x;
					hue[2] = 0.0;
					break;
				case 1:
					hue[0] = x;
					hue[1] = 1.0;
					hue[2] = 0.0;
					break;
				case 2:
					hue[0] = 0.0;
					hue[1] = 1.0;
					hue[2] = x;
					break;
				case 3:
					hue[0] = 0.0;
					hue[1] = x;
					hue[2] = 1.0;
					break;
				case 4:
					hue[0] = x;
					hue[1] = 0.0;
					hue[2] = 1.0;
					break;
				case 5:
					hue[0] = 1.0;
					hue[1] = 0.0;
					hue[2] = x;
					break;
			}
			glColor4dv((GLdouble *)hue);
		}
		// If we chose solid red coloring, draw in red.
		else if (edgeColorType == 2) 
			glColor4f(1.0f, 0.0f, 0.0f, edgeAlpha);
        
        GLfloat lastWidth = powf(lastGroupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
        GLfloat width = powf(groupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
        
        if (lastWidth < edgeMinWidth)
            lastWidth = edgeMinWidth;
        if (width < edgeMinWidth)
            width = edgeMinWidth;
		
		// If we chose gradient coloring and this is a selected edge or no edges are selected.
        // Since the coloring selected above will be ignored, we have to again, only draw color if the edge is selected or if no edges are selected.
		if ((!selectedEdges || selectedEdges[e]) && edgeColorType == 1) {
			CGFloat lastPct = (CGFloat)(edgeIndex - 1) / (CGFloat)(meshCount - 1);
			GLfloat lastColor[4] = {lastPct, 0.5 - lastPct / 2.0, 1.0 - lastPct, edgeAlpha};
			CGFloat pct = (CGFloat)edgeIndex / (CGFloat)(meshCount - 1);
			GLfloat color[4] = {pct, 0.5 - pct / 2.0, 1.0 - pct, edgeAlpha};
			
			glDrawRectLineColor2vf((GLfloat *)lastPoint,
								   (GLfloat *)point,
								   lastColor,
								   color,
								   lastWidth,
								   width);
		}
        // If we're not drawing a gradient, use this call. Will use the color picked in the if complex above.
		else {
			glDrawRectLine2vf((GLfloat *)lastPoint,
							  (GLfloat *)point,
							  lastWidth,
							  width);
		}
	}
	
	// Draw nodes.
	if (showNodes) {
        cl_uint nodeCount = [dataSource nodeCount];
        float2 *nodes = [dataSource nodes];        

		glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
		
		for (cl_uint n = 0; n < nodeCount; n++) {
			float2 *point = &nodes[n];
			
			glPushMatrix();
			glTranslatef(point->x, point->y, 0.0f);
            if (n == selectedNodeIndex)
                gluDisk(disk, nodeSize * 0.75, nodeSize * 1.75, 16, 1);
            else
                gluDisk(disk, 0.0, nodeSize, 16, 1);
			glPopMatrix();
		}
	}
    
    // Draw selection rectangle.
    if (selectionRect.size.width != 0.0 && selectionRect.size.height != 0.0) {
        glColor4f(0.5, 0.5, 0.5, 0.25);
        glBegin(GL_QUADS);
        glVertex2f(selectionRect.origin.x, selectionRect.origin.y);
        glVertex2f(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y);
        glVertex2f(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y + selectionRect.size.height);
        glVertex2f(selectionRect.origin.x, selectionRect.origin.y + selectionRect.size.height);
        glEnd();
        glLineWidth(1.0);
        glColor4f(0.5, 0.5, 0.5, 1.0);
        glBegin(GL_LINE_LOOP);
        glVertex2f(selectionRect.origin.x, selectionRect.origin.y);
        glVertex2f(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y);
        glVertex2f(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y + selectionRect.size.height);
        glVertex2f(selectionRect.origin.x, selectionRect.origin.y + selectionRect.size.height);
        glEnd();
    }
	
	glPopMatrix();
	
	[[self openGLContext] flushBuffer];
    
    //NSLog(@"currentViewRect = %@", [NSString stringWithFormat:@"%f %f %f %f", currentViewRect.origin.x, currentViewRect.origin.y, currentViewRect.size.width, currentViewRect.size.height]);
}

- (void)mouseDown:(NSEvent *)theEvent {
	GLint viewport[4];
	GLdouble modelview[16];
	GLdouble projection[16];
	
	glGetDoublev(GL_MODELVIEW_MATRIX, modelview);
	glGetDoublev(GL_PROJECTION_MATRIX, projection);
	glGetIntegerv(GL_VIEWPORT, viewport);
	
	NSPoint mouseWindowPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	GLdouble mouseX, mouseY, mouseZ;
	gluUnProject((GLdouble)mouseWindowPoint.x, (GLdouble)mouseWindowPoint.y, 0.0, modelview, projection, viewport, &mouseX, &mouseY, &mouseZ);
    
	if (([theEvent modifierFlags] & NSShiftKeyMask))
        selectionRect = NSMakeRect(mouseX, mouseY, 0.0, 0.0);
	else if (([theEvent modifierFlags] & NSCommandKeyMask)) {
		NSPoint mousePoint = NSMakePoint(mouseX, mouseY);
		ptrdiff_t minMeshIndex = -1, minNodeIndex = -1;
		float minMeshDist = FLT_MAX, minNodeDist = FLT_MAX;
		
        cl_uint edgeCount = [dataSource edgeCount];
        cl_uint meshCount = [dataSource meshCount];
        float2 *edgeMeshes = [dataSource edgeMeshes];
        
        for (cl_uint m = 0; m < edgeCount * meshCount; m++) {
            NSPoint point = Float2ToNSPoint(edgeMeshes[m]);
            float dist = NSPointDistance(mousePoint, point);
            
            if (dist < minMeshDist && m != selectedMeshIndex){
                minMeshDist = dist;
                minMeshIndex = m;
            }
        }
        
        if (minMeshDist <= 20.0f && minMeshIndex >= 0)
            self.selectedMeshIndex = minMeshIndex;
        else
            self.selectedMeshIndex = -1;
        
        cl_uint nodeCount = [dataSource nodeCount];
        float2* nodes = [dataSource nodes];
            
        for (cl_uint n = 0; n < nodeCount; n++) {
            NSPoint point = Float2ToNSPoint(nodes[n]);
            float dist = NSPointDistance(mousePoint, point);
            
            if (dist < minNodeDist && n != selectedNodeIndex) {
				minNodeDist = dist;
				minNodeIndex = n;
			}
        }
        
        if (minNodeDist <= 20.0f && minNodeIndex >= 0)
			self.selectedNodeIndex = minNodeIndex;
		else
			self.selectedNodeIndex = -1;
        
        //NSLog(@"sel: %i %i", selectedNodeIndex, selectedMeshIndex);
		
		[self setNeedsDisplay:TRUE];
	}
    else {
		mouseDown.x = mouseX;
		mouseDown.y = mouseY;
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	GLint viewport[4];
	GLdouble modelview[16];
	GLdouble projection[16];
	
	glGetDoublev(GL_MODELVIEW_MATRIX, modelview);
	glGetDoublev(GL_PROJECTION_MATRIX, projection);
	glGetIntegerv(GL_VIEWPORT, viewport);
	
	NSPoint mouseWindowPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	GLdouble mouseX, mouseY, mouseZ;
	gluUnProject((GLdouble)mouseWindowPoint.x, (GLdouble)mouseWindowPoint.y, 0.0, modelview, projection, viewport, &mouseX, &mouseY, &mouseZ);
	
    if(([theEvent modifierFlags] & NSShiftKeyMask)) {
        selectionRect.size.width = mouseX - selectionRect.origin.x;
        selectionRect.size.height = mouseY - selectionRect.origin.y;
    }
	else if(([theEvent modifierFlags] & NSCommandKeyMask)) {
        if(([theEvent modifierFlags] & NSAlternateKeyMask))
            [dataSource setMeshPoint:selectedMeshIndex toPosition:MakeFloat2(mouseX, mouseY)];
    }
    else {
        // Undo the live panning during the drag by subtracting pan, so that there isn't positive feedback.
		pan.x = mouseX - mouseDown.x + pan.x;
		pan.y = mouseY - mouseDown.y + pan.y;
		//NSLog(@"%f %f %f %f", mouseX, mouseDown.x, mouseY, mouseDown.y);
        //NSLog(@"pan = (%f, %f)", pan.x, pan.y);
	}
	
	[self setNeedsDisplay:TRUE];
}

- (void)mouseUp:(NSEvent *)theEvent {
    if(([theEvent modifierFlags] & NSShiftKeyMask)) {
        if(([theEvent modifierFlags] & NSCommandKeyMask)) {
            pan.x = center.x - (selectionRect.origin.x + selectionRect.size.width / 2.0);
            pan.y = center.y - (selectionRect.origin.y + selectionRect.size.height / 2.0);
            
            if (fabs(selectionRect.size.width) > fabs(selectionRect.size.height))
                scale = viewSize.x / fabs(selectionRect.size.width);
            else
                scale = viewSize.y / fabs(selectionRect.size.height);
            //NSLog(@"scale = %f", scale);
        }
        else {
            // Highlight bundles.
            cl_uint edgeCount = [dataSource edgeCount];
            cl_uint meshCount = [dataSource meshCount];
            float2 *edgeMeshes = [dataSource edgeMeshes];
            cl_float *edgeMeshGroupWeights = [dataSource edgeMeshGroupWeights];
            
            if (selectedEdges)
                free(selectedEdges);
            selectedEdges = malloc(sizeof(bool) * edgeCount);
            
            for (cl_uint e = 0; e < edgeCount; e++)
                selectedEdges[e] = FALSE;
            
            NSLog(@"Selected:");
            BOOL anyTrue = FALSE;
            for (cl_uint i = 0; i < meshCount * edgeCount; i++) {
                if (([theEvent modifierFlags] & NSAlternateKeyMask) && i % meshCount != 0 && i % meshCount != meshCount - 1)
                    continue;
                
                //if (NSPointInRect(NSMakePoint(x, y), selectionRect)) {
                if (edgeMeshes[i].x >= MIN(selectionRect.origin.x, selectionRect.origin.x + selectionRect.size.width) && edgeMeshes[i].x <= MAX(selectionRect.origin.x, selectionRect.origin.x + selectionRect.size.width) &&
                    edgeMeshes[i].y >= MIN(selectionRect.origin.y, selectionRect.origin.y + selectionRect.size.height) && edgeMeshes[i].y <= MAX(selectionRect.origin.y, selectionRect.origin.y + selectionRect.size.height)) {
                    cl_uint e = i / meshCount;
                    
                    selectedEdges[e] = TRUE;
                    anyTrue = TRUE;
                    
                    NSLog(@"Mesh #%i (%.3f, %.3f) in with localWeight %.3f.", i, edgeMeshes[i].x, edgeMeshes[i].y, edgeMeshGroupWeights[i]);
                }
            }
            
            if (!anyTrue) {
                free(selectedEdges);
                selectedEdges = nil;
            }
        }
        
        selectionRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
        [self setNeedsDisplay:TRUE];
    }
    // If we moved a node, recalculate all edge compatabilities.
    else if(([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask) && selectedNodeIndex >= 0)
        [dataSource calcEdgeCompatibilities];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    self.scale += scale * theEvent.deltaY / 100.0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	//if (object == self || object == dataSource)
	[self setNeedsDisplay:TRUE];
}

- (NSBitmapImageRep *)bitmapImageFromRect:(NSRect)rect {
	NSBitmapImageRep *flippedRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																		   pixelsWide:rect.size.width
																		   pixelsHigh:rect.size.height
																		bitsPerSample:8
																	  samplesPerPixel:3
																			 hasAlpha:FALSE
																			 isPlanar:FALSE
																	   colorSpaceName:NSDeviceRGBColorSpace
																		  bytesPerRow:((NSInteger)rect.size.width) * 3
																		 bitsPerPixel:0];
	NSBitmapImageRep *correctRef = nil;
	
	if (flippedRep) {
		[[self openGLContext] makeCurrentContext];
		glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, GL_RGB, GL_UNSIGNED_BYTE, [flippedRep bitmapData]);
		
		NSImage *correctImage = [[[NSImage alloc] init] autorelease];
		
		[correctImage addRepresentation:flippedRep];
		[correctImage lockFocusFlipped:TRUE];
		[flippedRep draw];
		[correctImage unlockFocus];
		
		correctRef = [NSBitmapImageRep imageRepWithData:[correctImage TIFFRepresentation]];
		
		[flippedRep release];
	}
	
	return correctRef;
}

- (NSBitmapImageRep *)bitmapImageOfSize:(NSPoint)size {
//    [[self openGLContext] setOffScreen:<#(void *)#> width:<#(GLsizei)#> height:<#(GLsizei)#> rowbytes:<#(GLint)#>];
}

- (NSXMLDocument *)SVGDocument {
    NSXMLElement *svg = [NSXMLElement elementWithName:@"svg"];
    
    [svg addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"http://www.w3.org/2000/svg"]];
    [svg addAttribute:[NSXMLNode attributeWithName:@"xmlns:xlink" stringValue:@"http://www.w3.org/1999/xlink"]];
    [svg addAttribute:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%fpx", self.bounds.size.width]]];
    [svg addAttribute:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%fpx", self.bounds.size.height]]];
    // We have to undo our clever Y-basis flipping because SVG won't interpret negative heights at all.
    GLfloat minY = currentViewRect.origin.y, maxY = currentViewRect.size.height;
    [svg addAttribute:[NSXMLNode attributeWithName:@"viewBox" stringValue:[NSString stringWithFormat:@"%.2f %.2f %.2f %.2f", currentViewRect.origin.x, minY, currentViewRect.size.width, maxY]]];
    
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithRootElement:svg];
    NSXMLElement *g = [NSXMLElement elementWithName:@"g"];
    //if (flipY)
    //    [g addAttribute:[NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"scale(1 -1) translate(0 -100%%)"]]];
    [svg addChild:g];
    
    cl_uint edgeCount = [dataSource edgeCount];
	cl_uint meshCount = [dataSource meshCount];
	float2 *edgeMeshes = [dataSource edgeMeshes];
	cl_float *edgeMeshGroupWeights = [dataSource edgeMeshGroupWeights];
	
	cl_float maxGroupCount = [dataSource edgeMeshGroupMaxCount];
	
	cl_float edgeMaxWidth = [dataSource edgeMaxWidth];
    cl_float edgeMinWidth = [dataSource edgeMinWidth];
	cl_float bundleWidthPower = [dataSource bundleWidthPower];
    
    NSXMLElement *defs = [NSXMLElement elementWithName:@"defs"];
    [svg addChild:defs];
    
    // If we have B-R gradients, set up the gradients we'll use in each edge.
    if (edgeColorType == 1) {
        for (cl_uint edgeIndex = 1; edgeIndex < meshCount; edgeIndex++) {
            NSXMLElement *linearGradient = [NSXMLElement elementWithName:@"linearGradient"];
            [linearGradient addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"br-%i", edgeIndex]]];
            [linearGradient addAttribute:[NSXMLNode attributeWithName:@"x1" stringValue:@"0%"]];
            [linearGradient addAttribute:[NSXMLNode attributeWithName:@"x2" stringValue:@"100%"]];
            [linearGradient addAttribute:[NSXMLNode attributeWithName:@"y1" stringValue:@"0%"]];
            [linearGradient addAttribute:[NSXMLNode attributeWithName:@"y2" stringValue:@"0%"]];
            NSXMLElement *stop = [NSXMLElement elementWithName:@"stop"];
            [stop addAttribute:[NSXMLNode attributeWithName:@"offset" stringValue:@"0%"]];
            CGFloat lastPct = (CGFloat)(edgeIndex - 1) / (CGFloat)(meshCount - 1);
			//GLfloat lastColor[4] = {lastPct, 0.5 - lastPct / 2.0, 1.0 - lastPct, edgeAlpha};
			CGFloat pct = (CGFloat)edgeIndex / (CGFloat)(meshCount - 1);
			//GLfloat color[4] = {pct, 0.5 - pct / 2.0, 1.0 - pct, edgeAlpha};
            [stop addAttribute:[NSXMLNode attributeWithName:@"stop-color" stringValue:[NSString stringWithFormat:@"rgb(%i,%i,%i)", (NSInteger)(lastPct * 255.0), (NSInteger)((0.5 - lastPct / 2.0) * 255.0), (NSInteger)((1.0 - lastPct) * 255.0)]]];
            [stop addAttribute:[NSXMLNode attributeWithName:@"stop-opacity" stringValue:[NSString stringWithFormat:@"%.2f", edgeAlpha]]];
            [linearGradient addChild:stop];
            stop = [NSXMLElement elementWithName:@"stop"];
            [stop addAttribute:[NSXMLNode attributeWithName:@"offset" stringValue:@"100%"]];
            [stop addAttribute:[NSXMLNode attributeWithName:@"stop-color" stringValue:[NSString stringWithFormat:@"rgb(%i,%i,%i)", (NSInteger)(pct * 255.0), (NSInteger)((0.5 - pct / 2.0) * 255.0), (NSInteger)((1.0 - pct) * 255.0)]]];
            [stop addAttribute:[NSXMLNode attributeWithName:@"stop-opacity" stringValue:[NSString stringWithFormat:@"%.2f", edgeAlpha]]];
            [linearGradient addChild:stop];
            [defs addChild:linearGradient];
        }
    }
    
    // Draw unselected edges on bottom, so first.
    if (selectedEdges)
        for (cl_uint i = 1; i < edgeCount * meshCount; i++) {
            cl_uint edgeIndex = i % meshCount;	// Index WITHIN this edge.
            cl_uint e = i / meshCount;	// Index of edge that this mesh point belongs to.
            
            float2 point = edgeMeshes[i];
            float2 lastPoint = edgeMeshes[i - 1];
            
            point.y = maxY - (point.y - minY * 2.0);
            lastPoint.y = maxY - (lastPoint.y - minY * 2.0);
            
            cl_float groupCount = edgeMeshGroupWeights[i];
            cl_float lastGroupCount = edgeMeshGroupWeights[i - 1];
            
            if (edgeIndex == 0)
                continue;
            
            // If we've selected edges and this edge isn't one of them. Draw it in grey.
            if (selectedEdges[e])
                continue;
            
            // Mysterious SVG-only factor of 2 for only deselected edges.
            GLfloat lastWidth = powf(lastGroupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth / 2.0;
            GLfloat width = powf(groupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth / 2.0;
            
            if (lastWidth < edgeMinWidth)
                lastWidth = edgeMinWidth;
            if (width < edgeMinWidth)
                width = edgeMinWidth;
            
            NSXMLElement *poly = svgRectLine2vf((GLfloat *)&lastPoint,
                                                (GLfloat *)&point,
                                                lastWidth,
                                                width);
            [poly addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:@"fill:rgb(128,128,128)"]];
            [poly addAttribute:[NSXMLNode attributeWithName:@"opacity" stringValue:[NSString stringWithFormat:@"%.2f", edgeDeselectAlpha]]];
            
            [g addChild:poly];
        }
    
	for (cl_uint i = 1; i < edgeCount * meshCount; i++) {
		cl_uint edgeIndex = i % meshCount;	// Index WITHIN this edge.
		cl_uint e = i / meshCount;	// Index of edge that this mesh point belongs to.
		
        float2 point = edgeMeshes[i];
        float2 lastPoint = edgeMeshes[i - 1];
        
        point.y = maxY - (point.y - minY * 2.0);
        lastPoint.y = maxY - (lastPoint.y - minY * 2.0);
		
		cl_float groupCount = edgeMeshGroupWeights[i];
		cl_float lastGroupCount = edgeMeshGroupWeights[i - 1];
        
        // Since the edges are drawn as many line segments connecting the last mesh point to the current one, skip everything if we're drawing the first mesh point in an edge. It'll get drawn when it is connected to the second mesh point in the next cycle.
        if (edgeIndex == 0)
			continue;
		
        // Draw mesh points if necessary. Don't draw them if they'll overlap with a node (be the first or last mesh point).
		if (showMesh && edgeIndex > 0 && edgeIndex < meshCount - 1) {
			NSXMLElement *circ = [NSXMLElement elementWithName:@"circle"];
            [circ addAttribute:[NSXMLNode attributeWithName:@"cx" stringValue:[NSString stringWithFormat:@"%.2f", point.x]]];
            [circ addAttribute:[NSXMLNode attributeWithName:@"cy" stringValue:[NSString stringWithFormat:@"%.2f", point.y]]];
            [circ addAttribute:[NSXMLNode attributeWithName:@"r" stringValue:[NSString stringWithFormat:@"%.2f", nodeSize / 2.0]]];
            
            [g addChild:circ];
		}
 
        GLfloat lastWidth = powf(lastGroupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
        GLfloat width = powf(groupCount / maxGroupCount, bundleWidthPower) * edgeMaxWidth;
        
        if (lastWidth < edgeMinWidth)
            lastWidth = edgeMinWidth;
        if (width < edgeMinWidth)
            width = edgeMinWidth;
		
        NSXMLElement *poly = svgRectLine2vf((GLfloat *)&lastPoint,
                                            (GLfloat *)&point,
                                            lastWidth,
                                            width);
        // If we've selected edges and this edge isn't one of them, we drew it above so skip it now.
        if (selectedEdges && !selectedEdges[e])
            continue;
        // If we chose angle hue based coloring.
		else if (edgeColorType == 0) {
			float2 *eMesh = &edgeMeshes[e * meshCount];
			NSPoint head = Float2ToNSPoint(eMesh[0]);
			NSPoint tail = Float2ToNSPoint(eMesh[meshCount - 1]);
			CGFloat plusDotHue = (NSPointDotProduct(NSPointNormalizedVectorTowards(head, tail),
                                                    NSMakePoint(1.0, 0.0)) + 1.0) / 4.0 * 6.0;
            
			// Hue for direction. Doesn't really work on its own, as you know two edges are going in different directions, but not specifics.
			// See http://en.wikipedia.org/wiki/HSV_color_space#From_HSV for definition.
			CGFloat hue[4] = {0.0, 0.0, 0.0, edgeAlpha};
			CGFloat x = (1.0 - fabs(fmod(plusDotHue, 2.0) - 1.0));
			switch ((int)plusDotHue) {
				case 0:
					hue[0] = 1.0;
					hue[1] = x;
					hue[2] = 0.0;
					break;
				case 1:
					hue[0] = x;
					hue[1] = 1.0;
					hue[2] = 0.0;
					break;
				case 2:
					hue[0] = 0.0;
					hue[1] = 1.0;
					hue[2] = x;
					break;
				case 3:
					hue[0] = 0.0;
					hue[1] = x;
					hue[2] = 1.0;
					break;
				case 4:
					hue[0] = x;
					hue[1] = 0.0;
					hue[2] = 1.0;
					break;
				case 5:
					hue[0] = 1.0;
					hue[1] = 0.0;
					hue[2] = x;
					break;
			}
			[poly addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:[NSString stringWithFormat:@"fill:rgb(%i,%i,%i)", (NSInteger)(hue[0] * 255.0), (NSInteger)(hue[1] * 255.0), (NSInteger)(hue[2] * 255.0)]]];
		}
        else if (edgeColorType == 1)
            [poly addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:[NSString stringWithFormat:@"fill:url(#br-%i)", edgeIndex]]];
		// If we chose solid red coloring, draw in red.
		else if (edgeColorType == 2) 
			[poly addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:@"fill:rgb(255,0,0)"]];
        
        [g addChild:poly];
	}

    
    cl_uint nodeCount = [dataSource nodeCount];
    float2 *nodes = [dataSource nodes];
    
    for (cl_uint n = 0; n < nodeCount; n++) {
        float2 point = nodes[n];
        
        point.y = maxY - (point.y - minY * 2.0);
        
        NSXMLElement *circ = [NSXMLElement elementWithName:@"circle"];
        [circ addAttribute:[NSXMLNode attributeWithName:@"cx" stringValue:[NSString stringWithFormat:@"%.2f", point.x]]];
        [circ addAttribute:[NSXMLNode attributeWithName:@"cy" stringValue:[NSString stringWithFormat:@"%.2f", point.y]]];
        [circ addAttribute:[NSXMLNode attributeWithName:@"r" stringValue:[NSString stringWithFormat:@"%.2f", nodeSize]]];
        
        [g addChild:circ];
    }
    
    return [doc autorelease];
}

- (GLfloat)scale {
    return scale;
}

- (void)setScale:(GLfloat)newScale {
    // Make sure the scale never gets to 0, since then we'd be dividing by zero in the drawing routines.
    if (newScale <= 0.00001)
        scale = 0.00001;
    else
        scale = newScale;
}

- (IBAction)zoomIn:(id)sender {
	self.scale *= 1.75f;
}

- (IBAction)zoomOut:(id)sender {
	self.scale /= 1.75f;
}

- (IBAction)resetView:(id)sender {
	pan.x = 0.0f;
	pan.y = 0.0f;
	self.scale = 0.9f;
    
    if (selectedEdges) {
        free(selectedEdges);
        selectedEdges = nil;
    }
    
    self.selectedNodeIndex = -1;
    self.selectedMeshIndex = -1;
}

@end
