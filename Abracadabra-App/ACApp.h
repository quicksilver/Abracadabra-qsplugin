//
//  KRApp.h
//  KeystrokeRecorder
//
//  Created by Nicholas Jitkoff on 8/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACCursorTrailAnimator.h"
#import "ACSparkleWindowController.h"

@interface ACApp : NSApplication <NSApplicationDelegate> {
	NSTimeInterval lastEventTime;
	//float events[EVENT_COUNT][3];
	//int currentEventNumber;
	int direction;
	
	int persist;
	ACCursorTrailAnimator *animator;
	NSWindow *cursorWindow;
	NSPoint hotSpot;
	ACSparkleWindowController *controller;
	NSPoint lastPoint;
	NSMutableArray *events;
	NSMutableDictionary *gestureDictionary;
	BOOL watchMouse;
//	NSPoint lastPoint;
	
//	NSMonitorModKe
	NSUInteger modKeyActivation;
	NSInteger mouseActivation;
	NSColor *gestureColor;
	NSColor *recognizedColor;
	NSColor *failureColor;
	NSDictionary *preferences;
	id laserKey;
}
- (BOOL)watchMouse;
- (void)setWatchMouse:(BOOL)flag;


- (NSColor *)gestureColor;
- (void)setGestureColor:(NSColor *)newGestureColor;
- (NSColor *)recognizedColor;
- (void)setRecognizedColor:(NSColor *)newRecognizedColor;
- (NSColor *)failureColor;
- (void)setFailureColor:(NSColor *)newFailureColor;
- (NSDictionary *)preferences;
- (void)setPreferences:(NSDictionary *)newPreferences;

- (id)laserKey;
- (void)setLaserKey:(id)newLaserKey;

@end
