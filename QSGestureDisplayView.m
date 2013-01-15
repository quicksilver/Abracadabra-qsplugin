//
//  QSGestureDisplayView.m
//  QSGestureTriggers
//
//  Created by Nicholas Jitkoff on 5/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSGestureDisplayView.h"


@implementation QSGestureDisplayView

- (void)drawBackgroundInRect:(NSRect)rect {
	NSBezierPath *path = [[[NSBezierPath alloc] init] autorelease];
	[path appendBezierPathWithRoundedRectangle:rect withRadius:4];
	[path setClip];
	QSFillRectWithGradientFromEdge(rect, [NSColor darkGrayColor], [NSColor grayColor], NSMaxYEdge);
	
	[[NSColor darkGrayColor] set];
	[path stroke];
}
@end
