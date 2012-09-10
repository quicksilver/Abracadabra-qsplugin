//
//  ACCursorTrailAnimator.h
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ACCursorTrailAnimator : NSObject {
	NSMutableArray *windows;
	NSTimer *animationTimer;
	NSImage *image;
}


@end
