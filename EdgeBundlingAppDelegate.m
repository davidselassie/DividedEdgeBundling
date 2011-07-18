//
//  EdgeBundlingAppDelegate.m
//  EdgeBundling
//
//  Created by David Selassie on 11/22/10.
/*  Copyright (c) 2010-2011 David Selassie. All rights reserved.
 
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "EdgeBundlingAppDelegate.h"

#import "NSDataExtensions.h"
#import <string.h>

@interface URLLastPathComponentTransformer: NSValueTransformer {}
@end

@implementation URLLastPathComponentTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    return (value == nil) ? nil : [[value path] lastPathComponent];
}

@end

@implementation EdgeBundlingAppDelegate

- (void)awakeFromNib {
	self.timerStep = 0.005;
	
	self.runningEdgeForcing = FALSE;
	self.runningNodeForcing = FALSE;
    
    self.lastURL = nil;
    
    self.lastMagicDuration = -1.0;
    self.lastCompatibilityDuration = -1.0;
    
    FPSIndex = 0;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"]]];
    
    NSUserDefaultsController *SUDC = [[NSUserDefaultsController sharedUserDefaultsController] retain];
    [graphView bind:@"nodeSize" toObject:SUDC withKeyPath:@"values.nodeSize" options:nil];
    [graphView bind:@"edgeAlpha" toObject:SUDC withKeyPath:@"values.edgeAlpha" options:nil];
    [graphView bind:@"edgeDeselectAlpha" toObject:SUDC withKeyPath:@"values.edgeDeselectAlpha" options:nil];
    [graphView bind:@"edgeColorType" toObject:SUDC withKeyPath:@"values.edgeColorType" options:nil];
    [graphView bind:@"showMesh" toObject:SUDC withKeyPath:@"values.showMesh" options:nil];
    [graphView bind:@"showNodes" toObject:SUDC withKeyPath:@"values.showNodes" options:nil];
    
    [graph bind:@"velocityDamping" toObject:SUDC withKeyPath:@"values.velocityDamping" options:nil];
    [graph bind:@"nodeSpringRestLength" toObject:SUDC withKeyPath:@"values.nodeSpringRestLength" options:nil];
    [graph bind:@"nodeSpringConstant" toObject:SUDC withKeyPath:@"values.nodeSpringConstant" options:nil];
    [graph bind:@"edgeSpringConstant" toObject:SUDC withKeyPath:@"values.edgeSpringConstant" options:nil];
    [graph bind:@"edgeCoulombConstant" toObject:SUDC withKeyPath:@"values.edgeCoulombConstant" options:nil];
    [graph bind:@"edgeLaneWidth" toObject:SUDC withKeyPath:@"values.edgeLaneWidth" options:nil];
    [graph bind:@"edgeMaxWidth" toObject:SUDC withKeyPath:@"values.edgeMaxWidth" options:nil];
    [graph bind:@"edgeMinWidth" toObject:SUDC withKeyPath:@"values.edgeMinWidth" options:nil];
    [graph bind:@"bundleWidthPower" toObject:SUDC withKeyPath:@"values.bundleWidthPower" options:nil];
    [graph bind:@"edgeCoulombDecay" toObject:SUDC withKeyPath:@"values.edgeCoulombDecay" options:nil];
    //[graph bind:@"useCompat" toObject:SUDC withKeyPath:@"values.useCompat" options:nil];
    //[graph bind:@"useConnectCompat" toObject:SUDC withKeyPath:@"values.useConnectCompat" options:nil];
    //[graph bind:@"useGPUDevice" toObject:SUDC withKeyPath:@"values.useGPUDevice" options:nil];
    [SUDC addObserver:self forKeyPath:@"values.useCompat" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    [SUDC addObserver:self forKeyPath:@"values.useConnectCompat" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    [SUDC addObserver:self forKeyPath:@"values.useGPUDevice" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    [SUDC addObserver:self forKeyPath:@"values.useNewForce" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [SUDC release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSUserDefaultsController *SUDC = [[NSUserDefaultsController sharedUserDefaultsController] retain];
    
    if ([keyPath isEqualTo:@"values.useCompat"])
        graph.useCompat = [[SUDC valueForKeyPath:@"values.useCompat"] boolValue];
    if ([keyPath isEqualTo:@"values.useConnectCompat"])
        graph.useConnectCompat = [[SUDC valueForKeyPath:@"values.useConnectCompat"] boolValue];
    if ([keyPath isEqualTo:@"values.useGPUDevice"])
        graph.useGPUDevice = [[SUDC valueForKeyPath:@"values.useGPUDevice"] boolValue];
    if ([keyPath isEqualTo:@"values.useNewForce"])
        graph.useNewForce = [[SUDC valueForKeyPath:@"values.useNewForce"] boolValue];
    
    [SUDC release];
}

- (IBAction)resetPreferences:(id)sender {
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValuesForKeysWithDictionary:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"]]];
}

- (IBAction)runEdgeForcing:(id)sender {
	self.runningEdgeForcing = TRUE;
}

- (IBAction)runNodeForcing:(id)sender {
	self.runningNodeForcing = TRUE;
}

- (IBAction)stopForcing:(id)sender {
	self.runningEdgeForcing = FALSE;
	self.runningNodeForcing = FALSE;
}

- (IBAction)openViaPanel:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"graphml", @"gexf", nil]];
	[panel setAllowsOtherFileTypes:TRUE];
	
	[panel beginSheetModalForWindow:window
				  completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			self.lastURL = panel.URL;
			[self resetGraph:panel];
			
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:panel.URL];
		}
	}];
}

@synthesize lastURL;

@synthesize window;
@synthesize graph;
@synthesize graphView;

@synthesize timerStep;
@synthesize simulationStep;
@synthesize cycleIterations;

@synthesize lastMagicDuration;
@synthesize lastCompatibilityDuration;

- (NSString *)FPSString {
    CGFloat avg = 0.0;
    for (NSInteger i = 0; i < FPS_AVG_OVER; i++)
        avg += FPSArray[i];
    
    avg /= FPS_AVG_OVER;
    
    return [NSString stringWithFormat:@"%.1f", avg];
}

- (void)setRunningEdgeForcing:(BOOL)newVal {
	runningEdgeForcing = newVal;
	if (runningEdgeForcing && !animationTimer) {
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:self.timerStep
														  target:self
														selector:@selector(simulateStepFromTimer:)
														userInfo:nil
														 repeats:TRUE] retain];
	}
	else if (!runningEdgeForcing && !runningNodeForcing) {
		if (animationTimer) {
			[animationTimer invalidate];
			[animationTimer release];
		}
		animationTimer = nil;
	}
}

- (BOOL)runningEdgeForcing {
    return runningEdgeForcing;
}

- (void)setRunningNodeForcing:(BOOL)newVal {
	runningNodeForcing = newVal;
	if (runningNodeForcing && !animationTimer) {
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:self.timerStep
															  target:self
															selector:@selector(simulateStepFromTimer:)
															userInfo:nil
															 repeats:TRUE] retain];
	}
	else if (!runningNodeForcing && !runningEdgeForcing) {
		if (animationTimer) {
			[animationTimer invalidate];
			[animationTimer release];
		}
		animationTimer = nil;
	}
}

- (BOOL)runningNodeForcing {
    return runningNodeForcing;
}

- (IBAction)doEdgeCycle:(id)sender {
    NSDate *begin = [NSDate date];
    
	self.simulationStep = (CGFloat)(simulationStep * 0.5);
	//self.cycleIterations = (NSUInteger)(cycleIterations * 2.0 / 3.0);
	[graph doubleEdgeMeshResolution];
	
	for (NSUInteger i = 0; i < cycleIterations; i++)
		[graph simulateEdgeStep:self.simulationStep backCopy:(BOOL)(i >= cycleIterations - 1)];
    
    NSLog(@"One cycle took %f seconds.", -[begin timeIntervalSinceNow]);
	
	if (sender != self)
		[graphView setNeedsDisplay:TRUE];
}

- (IBAction)doubleEdgeMeshResolution:(id)sender {
	[graph doubleEdgeMeshResolution];
	[graphView setNeedsDisplay:TRUE];
}

- (IBAction)smoothEdgeMeshPoints:(id)sender {
	[graph smoothEdgeMeshPoints];
	[graphView setNeedsDisplay:TRUE];
}

- (IBAction)doMagicIteration:(id)sender {
    NSDate *begin = [NSDate date];
	for (NSUInteger i = 0; i < 5; i++)
		[self doEdgeCycle:self];
	
    self.lastMagicDuration = -[begin timeIntervalSinceNow];
    NSLog(@"Magic iteration took %f seconds.", lastMagicDuration);
    
	[graphView setNeedsDisplay:TRUE];
}

- (IBAction)scaleView:(id)sender {
	[graph scaleNodes];
	[graphView setNeedsDisplay:TRUE];
}

- (IBAction)resetGraph:(id)sender {
	self.simulationStep = 40.0;
	//self.cycleIterations = 50.0 * 3.0/2.0;
    self.cycleIterations = 30;
	
	self.runningEdgeForcing = FALSE;
	self.runningNodeForcing = FALSE;
	
	if (lastURL)
		[graph loadGraphFromURL:lastURL];
	else
		[graph loadDefaultGraph];
    
    [graphView resetView:sender];
	[graphView setNeedsDisplay:TRUE];
}

- (void)simulateStepFromTimer:(NSTimer *)timer {
    NSDate *start = [NSDate date];
    
	if (runningEdgeForcing)
		[graph simulateEdgeStep:3.0];
	if (runningNodeForcing)
		[graph simulateNodeStep:3.0];
    
    [self willChangeValueForKey:@"FPSString"];
    FPSIndex = (FPSIndex + 1) % FPS_AVG_OVER;
    FPSArray[FPSIndex] = -1.0 / [start timeIntervalSinceNow];
    [self didChangeValueForKey:@"FPSString"];

	[graphView setNeedsDisplay:TRUE];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
    if ([args stringForKey:@"inFile"])
        self.lastURL = [NSURL fileURLWithPath:[args stringForKey:@"inFile"]];
    if ([args stringForKey:@"bundleWidthPower"])
        graph.bundleWidthPower = [args floatForKey:@"bundleWidthPower"];
    if ([args stringForKey:@"edgeMaxWidth"])
        graph.edgeMaxWidth = [args floatForKey:@"edgeMaxWidth"];
    if ([args stringForKey:@"edgeLaneWidth"])
        graph.edgeLaneWidth = [args floatForKey:@"edgeLaneWidth"];
    
    if (([args floatForKey:@"imageW"] || [args floatForKey:@"imageH"]) && [args stringForKey:@"outImage"]) {
        //[graphView setFrame:NSMakeRect(0.0, 0.0, [args floatForKey:@"imageW"], [args floatForKey:@"imageH"])];
        [graphView setBounds:NSMakeRect(0.0, 0.0, [args floatForKey:@"imageW"], [args floatForKey:@"imageH"])];
        //[graphView setHidden:TRUE];
    }
    
	[self resetGraph:self];
    
    if ([args stringForKey:@"outImage"]) {
        [self doMagicIteration:args];
        [graphView displayIfNeeded];
        
        [self saveGraphViewToPNGURL:[NSURL fileURLWithPath:[args stringForKey:@"outImage"]]];
        
        [NSApp terminate:nil];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return TRUE;
}

- (IBAction)saveGraphViewToPDFViaPanel:(id)sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"pdf", nil]];
	[panel setAllowsOtherFileTypes:TRUE];
	[panel setNameFieldStringValue:[NSString stringWithFormat:@"bundled_%@.pdf", [lastURL.lastPathComponent stringByDeletingPathExtension]]];
	[panel setCanSelectHiddenExtension:TRUE];

	[panel beginSheetModalForWindow:window
				  completionHandler:^(NSInteger result) {
					  if (result == NSFileHandlingPanelOKButton) {			
						  // Apparently dataWithPDFInsideRect has never worked with scaled bounds.
						  [[graphView dataWithPDFInsideRect:[graphView bounds]] writeToURL:panel.URL
																		atomically:FALSE];
					  }
				  }];
}
         
- (IBAction)saveGraphViewToPNGURL:(NSURL *)outURL {
    NSBitmapImageRep *bits = [graphView bitmapImageFromRect:[graphView bounds]];
    
    [[bits representationUsingType:NSPNGFileType properties:nil] writeToURL:outURL atomically:FALSE];
}

- (IBAction)saveGraphViewToPNGViaPanel:(id)sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", nil]];
	[panel setAllowsOtherFileTypes:TRUE];
	[panel setNameFieldStringValue:[NSString stringWithFormat:@"bundled_%@.png", [lastURL.lastPathComponent stringByDeletingPathExtension]]];
	[panel setCanSelectHiddenExtension:TRUE];
	
	[panel beginSheetModalForWindow:window
				  completionHandler:^(NSInteger result) {
					  if (result == NSFileHandlingPanelOKButton) {
						  [self saveGraphViewToPNGURL:panel.URL];
					  }
				  }];
}

- (IBAction)saveGraphViewToSVGURL:(NSURL *)outURL {
    [[[[graphView SVGDocument] XMLString] dataUsingEncoding:NSUTF8StringEncoding] writeToURL:outURL atomically:TRUE];
}

- (IBAction)saveGraphViewToSVGViaPanel:(id)sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"svg", nil]];
	[panel setAllowsOtherFileTypes:TRUE];
	[panel setNameFieldStringValue:[NSString stringWithFormat:@"bundled_%@.svg", [lastURL.lastPathComponent stringByDeletingPathExtension]]];
	[panel setCanSelectHiddenExtension:TRUE];
	
	[panel beginSheetModalForWindow:window
				  completionHandler:^(NSInteger result) {
					  if (result == NSFileHandlingPanelOKButton) {
						  [self saveGraphViewToSVGURL:panel.URL];
					  }
				  }];
}

- (IBAction)recalcEdgeCompatabilities:(id)sender {
	[graph calcEdgeCompatibilities];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSURL *newURL = [NSURL fileURLWithPath:filename];
	self.lastURL = newURL;
	
	[self resetGraph:self];
    
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:newURL];
	
	return TRUE;
}

- (IBAction)updateMeshGroups:(id)sender {
    [graph simulateEdgeStep:0.0];
}

@end
