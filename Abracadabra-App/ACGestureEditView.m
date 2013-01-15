//
//  ACGestureEditView.m
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ACGestureEditView.h"


@implementation ACGestureEditView

- (void)mouseDown:(NSEvent *)theEvent {
	NSMutableArray *eventsArray=[NSMutableArray array];
	drawToScale = YES;
	do {
		[eventsArray addObject:theEvent];
        [self setGesture:[[[ACGesture alloc]initWithEventArray:eventsArray]autorelease]];
		if ([theEvent type] == NSLeftMouseUp)
            break;
	} while (theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask
                                           untilDate:[NSDate distantFuture]
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES]);

	[self setGesture:[[[ACGesture alloc] initWithEventArray:eventsArray] autorelease]];

	eventsArray = nil;
	drawToScale = NO;
	if ([[self delegate] respondsToSelector:@selector(gestureView:drewGesture:)])
		[[self delegate] gestureView:self drewGesture:[self gesture]];
}

- (id)delegate {
    return [[delegate retain] autorelease]; 
}

- (void)setDelegate:(id)newDelegate {
	if (delegate!=newDelegate){
        [delegate release];
        delegate = [newDelegate retain];
	}
}

@end
