//
//  QSGestureTriggerManager.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on Sun Jun 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "QSGestureTriggerManager.h"
#import "Abracadabra-App/ACGesture.h"
#import "Abracadabra-App/ACGestureDisplayView.h"
#import "Abracadabra-App/ACNotifications.h"

#define QSTriggerCenter NSClassFromString(@"QSTriggerCenter")
#define NSAllModifierKeysMask (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask|NSFunctionKeyMask)
@interface QSGestureTableCell : NSTextFieldCell
@end

@implementation QSGestureTableCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = alignRectInRect(fitRectInRect(NSMakeRect(0, 0, 1000, 1000), cellFrame, NO),
                                cellFrame, 1);
	NSBezierPath *background = [NSBezierPath bezierPath];

	[background appendBezierPathWithRoundedRectangle:cellFrame withRadius:2];

	NSColor *color = [self isHighlighted] ? [NSColor textBackgroundColor] : [NSColor textColor];
	
	[[color colorWithAlphaComponent:0.2] set];
	[background fill];
	cellFrame = NSInsetRect(cellFrame, 2, 2);

	ACGesture *gesture = [ACGesture gestureWithDictionary:[[self representedObject] objectForKey:@"gesture"]];

	NSBezierPath *path = [[[NSBezierPath alloc] init]autorelease];

	[color set];
	if (gesture) {
		NSPoint *points = [gesture points];

		int i;
		for (i = 0; i < 32; i++) {
			NSPoint p = points[i];
			p.y = -p.y;
			p = ACCenteredUnitPointInFrame(p, cellFrame);
			if (i == 0) {
				[path moveToPoint: p];
				ACDrawDotAtPoint(p, 1.5);
			} else {
				[path lineToPoint: p];
			}
		}
	}
	
	// draw overall path in white
	[path setLineWidth:1.1];
	[path stroke];
}
@end

@implementation QSGestureTriggerManager
- (NSString *)name {
	return @"Gesture";
}
- (NSImage *)image {
	return [[NSBundle bundleForClass:[self class]] imageNamed:@"Gesture"];
}

- (void)initializeTrigger:(NSMutableDictionary *)trigger {}

+ (id)sharedInstance {
    static QSGestureTriggerManager *_sharedInstance = nil;
    if (!_sharedInstance){
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    }
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
		[self addObserver:self
			   forKeyPath:@"currentTrigger"
				  options:0
				  context:nil];

		enabledTriggers = [[NSMutableDictionary alloc] init];

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(gestureRecognized:)
                                                                name:ACAbracadabraGestureRecognizedNotification
                                                              object:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appTerminating:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (NSCell *)descriptionCellForTrigger:(QSTrigger *)trigger {
	return	[[[QSGestureTableCell alloc] init] autorelease];
}

- (void)appTerminating:(NSNotification *)notif {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ACAbracadabraShouldQuitNotification
                                                                   object:nil
                                                                 userInfo:nil
                                                       deliverImmediately:YES];
}

- (void)gestureRecognized:(NSNotification *)notif {
	NSString *identifier = [notif object];
	
	//NSLog(@"recognized: %@",identifier);
	QSTrigger *trigger = [[QSTriggerCenter sharedInstance] triggerWithID:identifier];
	BOOL showStatus = [[[trigger info] objectForKey:@"showWindow"] boolValue];
	QSWindow *window = nil;
	if (showStatus) {
		window = (QSWindow *)[self triggerDisplayWindowWithTrigger:trigger];
		NSDictionary *info = [notif userInfo];
		NSPoint center = NSPointFromString([info objectForKey:@"center"]);
		
		[window setFrame:NSOffsetRect([window frame], center.x - NSMidX([window frame]), center.y - NSMidY([window frame]))
                 display:NO];
		[window setAlphaValue:0];
		[window reallyOrderFront:self];
		[window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:
                               @"0.125", @"duration",
                               @"QSGrowEffect", @"transformFn",
                               @"show", @"type",
                               nil]];
	}

	[trigger execute];
	[window flare:self];

	[window reallyOrderOut:nil];
	[window close];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self populateInfoFields];
}

- (BOOL)enableTrigger:(QSTrigger *)entry {
	[enabledTriggers setObject:entry forKey:[entry identifier]];
	[self writeGestureTriggers];
	[self launchAbra];
    return YES;
}

- (BOOL)disableTrigger:(QSTrigger *)entry {
	[enabledTriggers removeObjectForKey:[entry identifier]];
	[self writeGestureTriggers];
    return YES;
}

#warning: tiennou this doesn't look used
- (void)abraTerminated:(NSNotification *)notif {
	[abraTask release];
	abraTask = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self launchAbra];
}

- (void)launchAbra {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"Abracadabra" ofType:@"app"];
	NDProcess *proc = [NDProcess processForApplicationPath:path];

	if (!proc) {
		if (VERBOSE) NSLog(@"Launch Abracadabra");
		FSRef ref;
		[path getFSRef:&ref];
		
		LSApplicationParameters param;
		param.version=0;
		param.application=&ref;
		param.flags=kLSLaunchDontSwitch;
		param.asyncLaunchRefCon=NULL;
		param.environment=NULL;
		param.argv=NULL;
		param.initialEvent=NULL;
		LSOpenApplication(&param,NULL);
	}
}

- (void)writeGestureTriggers {
	NSArray *keys = [enabledTriggers allKeys];
	NSArray *values = [enabledTriggers objectsForKeys:keys notFoundMarker:[NSNull null]];
	
	values = [values valueForKey:@"gesture"];
	NSMutableDictionary *gestureDictionary = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
	[gestureDictionary removeObjectsForKeys:[gestureDictionary allKeysForObject:[NSNull null]]];

	[gestureDictionary writeToFile:[ACGestureFilePath stringByStandardizingPath] atomically:NO];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ACAbracadabraGesturesChangedNotification
                                                                   object:nil
                                                                 userInfo:nil
                                                       deliverImmediately:YES];
}

- (NSString *)descriptionForTrigger:(NSDictionary *)dict {
	return @"Gesture";
}

- (void)gestureView:(ACGestureEditView *)view drewGesture:(ACGesture *)gesture {
	[[[self currentTrigger] info] setObject:[gesture dictionaryRepresentation] forKey:@"gesture"];
	
	[[QSTriggerCenter sharedInstance] triggerChanged:[self currentTrigger]];
	[self writeGestureTriggers];
}

- (NSView *)settingsView {
    if (!settingsView){
        [NSBundle loadNibNamed:@"QSGestureTrigger" owner:self];
		[gestureView setDelegate:self];
	}
    return [[settingsView retain] autorelease];
}

- (void)populateInfoFields {
	QSTrigger *thisTrigger = currentTrigger;
	if ([[thisTrigger objectForKey:@"type"] isEqualToString:@"QSGestureTrigger"]) {
		[gestureView setGesture:[ACGesture gestureWithDictionary:[thisTrigger objectForKey:@"gesture"]]];
	}
}

@end
