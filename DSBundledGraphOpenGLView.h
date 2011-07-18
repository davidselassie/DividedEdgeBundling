//
//  DSBundledGraphOpenGLView.h
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

#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#import "DSGraphProvider.h"

@interface DSBundledGraphOpenGLView : NSOpenGLView {
	NSUInteger edgeColorType;
	
	CGFloat nodeSize;
	CGFloat edgeAlpha;
    CGFloat edgeDeselectAlpha;
	BOOL showMesh;
	BOOL showNodes;
	
	float viewAspect;
	
	GLfloat scale;
	NSPoint pan;
	NSPoint mouseDown;
	
    NSPoint center; // Readonly, in a sense.
    NSPoint viewSize; // readonly
    
    NSRect selectionRect;
    NSRect currentViewRect;
	
	id<DSGraphProvider> dataSource;
	ptrdiff_t selectedMeshIndex;
    ptrdiff_t selectedNodeIndex;
    bool *selectedEdges;
    
    GLUquadric *disk;
}

+ (NSOpenGLPixelFormat *) defaultPixelFormat;

@property (readwrite, assign) CGFloat nodeSize;
@property (readwrite, assign) CGFloat edgeAlpha;
@property (readwrite, assign) CGFloat edgeDeselectAlpha;
@property (readwrite, assign) NSUInteger edgeColorType;
@property (readwrite, assign) BOOL showMesh;
@property (readwrite, assign) BOOL showNodes;

@property (readwrite, assign) GLfloat scale;

@property (readwrite, retain) IBOutlet id dataSource;

@property (readonly) NSString *selectedNodeLabel;
@property (readonly) cl_float selectedMeshGroupWeight;

- (NSBitmapImageRep *)bitmapImageFromRect:(NSRect)rect;
// TODO: write out a bundled version of the graph, perhaps with ghost mesh nodes.
- (void)saveBundledGEXFToFile:(NSURL *)outURL;
- (NSXMLDocument *)SVGDocument;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)resetView:(id)sender;

@property(readwrite) ptrdiff_t selectedNodeIndex;
@property(readwrite) ptrdiff_t selectedMeshIndex;

@end
