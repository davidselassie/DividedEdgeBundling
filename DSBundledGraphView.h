//
//  DSBundledGraphView.h
//  EdgeBundling
//
//  Created by David Selassie on 12/16/10.
//  Copyright 2010 David Selassie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DSGraphProvider.h"

@interface DSBundledGraphView : NSView {
	NSUInteger edgeColorType;
	
	CGFloat edgeWidth;
	CGFloat edgeAlpha;
	BOOL showMeshPoints;
	
	id<DSGraphProvider> dataSource;
}

@property(readwrite,assign) CGFloat edgeWidth;
@property(readwrite,assign) CGFloat edgeAlpha;
@property(readwrite,assign) NSUInteger edgeColorType;
@property(readwrite,assign) BOOL showMeshPoints;

@property(readwrite,retain) IBOutlet id dataSource;

@end
