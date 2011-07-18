//
//  EdgeBundlingAppDelegate.h
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

#import "DSBundledGraph.h"
#import "DSBundledGraphViewer.h"

#define FPS_AVG_OVER 5

@interface EdgeBundlingAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	
	DSBundledGraph *graph;
	NSView<DSBundledGraphViewer> *graphView;
	
	CGFloat timerStep;
	CGFloat simulationStep;
	NSUInteger cycleIterations;
	NSTimer *animationTimer;
	
	BOOL runningEdgeForcing;
	BOOL runningNodeForcing;
    
    CGFloat FPSArray[FPS_AVG_OVER];
    NSUInteger FPSIndex;
    
    CGFloat lastMagicDuration;
    CGFloat lastCompatibilityDuration;
	
	NSURL *lastURL;
}

@property (readwrite, retain) IBOutlet NSWindow *window;
@property (readwrite, retain) IBOutlet DSBundledGraph *graph;
@property (readwrite, retain) IBOutlet NSView *graphView;

@property (readwrite, retain) NSURL *lastURL;

@property (readwrite, assign) CGFloat timerStep;
@property (readwrite, assign) CGFloat simulationStep;
@property (readwrite, assign) NSUInteger cycleIterations;
@property (readwrite, assign) BOOL runningEdgeForcing;
@property (readwrite, assign) BOOL runningNodeForcing;

@property (readwrite, assign) CGFloat lastMagicDuration;
@property (readwrite, assign) CGFloat lastCompatibilityDuration;

@property (readonly) NSString *FPSString;

- (IBAction)openViaPanel:(id)sender;
- (IBAction)runEdgeForcing:(id)sender;
- (IBAction)updateMeshGroups:(id)sender;
- (IBAction)runNodeForcing:(id)sender;
- (IBAction)stopForcing:(id)sender;
- (IBAction)doEdgeCycle:(id)sender;
- (IBAction)doMagicIteration:(id)sender;
- (IBAction)doubleEdgeMeshResolution:(id)sender;
- (IBAction)smoothEdgeMeshPoints:(id)sender;
- (IBAction)resetGraph:(id)sender;
- (IBAction)resetPreferences:(id)sender;
- (IBAction)saveGraphViewToPDFViaPanel:(id)sender;
- (IBAction)saveGraphViewToPNGURL:(NSURL *)outURL;
- (IBAction)saveGraphViewToPNGViaPanel:(id)sender;
- (IBAction)scaleView:(id)sender;
- (IBAction)recalcEdgeCompatabilities:(id)sender;

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;

@end
