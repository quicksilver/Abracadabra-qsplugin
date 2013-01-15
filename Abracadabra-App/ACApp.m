//
//  KRApp.m
//  KeystrokeRecorder
//
//  Created by Nicholas Jitkoff on 8/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//
#import <Carbon/Carbon.h>

#import "ACLaserKey.h"
#import "ACApp.h"
#import "ACGesture.h"
#import "DDGLView.h"
#import "ACGestureDisplayView.h"
#import "ACNotifications.h"

#define UCSTR(u) [NSString stringWithFormat:@"%C",u]
#define EVENT_COUNT 32

OSStatus mouseMoved(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ACApp *appDelegate = (ACApp *)userData;
    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    [appDelegate sendEvent:event];
	return CallNextEventHandler(nextHandler, theEvent);
}

OSStatus modChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ACApp *appDelegate = (ACApp *)userData;
    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    [appDelegate sendEvent:event];
	return CallNextEventHandler(nextHandler, theEvent);
}

OSStatus mouseActivated(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ACApp *appDelegate = (ACApp *)userData;
    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    [appDelegate sendEvent:event];

	return CallNextEventHandler(nextHandler, theEvent);
}

@implementation ACApp

+ (void)registerEventHandlers {
	//	if (VERBOSE) NSLog(@"Registering for Global Mouse Events");
	
}

- (void)setMonitorMouseMovements:(BOOL)flag {
	static EventHandlerRef mouseMoveRef = NULL;
	if (flag && !mouseMoveRef) {
		EventTypeSpec eventTypes[4] = {
            {kEventClassMouse, kEventMouseMoved},
            {kEventClassMouse, kEventMouseDragged},
            {kEventClassMouse, kEventMouseUp},
            {kEventClassMouse, kEventMouseDown},
        };

		EventHandlerUPP handlerFunction = NewEventHandlerUPP(mouseMoved);
		OSStatus err = InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 3, eventTypes, self, &mouseMoveRef);
        if (err != noErr) {
            NSLog(@"Failed to install mouse event handler");
        }
    } else {
        if (mouseMoveRef)
            RemoveEventHandler(mouseMoveRef);
        mouseMoveRef = NULL;
    }
}

- (void)setMonitorModKeys:(BOOL)flag {
    static EventHandlerRef modifierKeysRef = NULL;
    if (flag) {
        EventTypeSpec    eventTypes[1];
        eventTypes[0].eventClass = kEventClassKeyboard;
        eventTypes[0].eventKind  = kEventRawKeyModifiersChanged;

        EventHandlerUPP handlerFunction = NewEventHandlerUPP(modChanged);
        OSStatus err = InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, eventTypes, self, &modifierKeysRef);
        if (err != noErr) {
            NSLog(@"Failed to install modifier event handler");
        }
    } else {
        if (modifierKeysRef)
            RemoveEventHandler(modifierKeysRef);
        modifierKeysRef = NULL;
    }
}

- (id)init {
	if (self = [super init]) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ACAbracadabraShouldQuitNotification
                                                                       object:nil
                                                                     userInfo:nil
                                                           deliverImmediately:YES];

		events = [[NSMutableArray arrayWithCapacity:EVENT_COUNT] retain];
		gestureDictionary = [[NSMutableDictionary alloc] init];

		[self setMonitorModKeys:YES];
		[self setMonitorMouseMovements:YES];

		[self setDelegate:self];

		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(reloadGestureFile:)
															   name:ACAbracadabraGesturesChangedNotification
                                                             object:nil];
		
		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(reloadPreferences:)
															   name:ACAbracadabraPreferencesChangedNotification
                                                             object:nil];

		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(terminate:)
															   name:ACAbracadabraShouldQuitNotification
                                                             object:nil];

		modKeyActivation = 23; 
		mouseActivation = 0;
		[self setRecognizedColor:[NSColor greenColor]];
		[self setGestureColor:[NSColor cyanColor]];
		[self setFailureColor:[NSColor redColor]];
		[self reloadGestureFile:nil];
    }
	return self;
}

- (void)reloadPreferences:(NSNotification *)notification {
    NSDictionary *dict = [[notification userInfo] copy];
    if (!dict) {
        // There's no notification => we're launching, read from defaults.
        CFPreferencesSynchronize((CFStringRef)@"com.blacktree.Quicksilver", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

        NSArray *array = [NSArray arrayWithObjects:
                          @"QSACModifierActivation",
                          @"QSACMouseActivation",
                          @"QSACGestureColor",
                          @"QSACRecognizedColor",
                          @"QSACFailureColor",
                          @"QSACEnableLaserKey",
                          @"QSACMagicAmount",
                          @"QSACFailureSound",
                          @"QSACRecognizedSound",
                          nil];
        dict = (NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)array, (CFStringRef)@"com.blacktree.Quicksilver", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    }

//    NSLog(@"Abracadabra pref: %@", dict);

	[self setPreferences:dict];
	if ([dict objectForKey:@"QSACGestureColor"])
		[self setGestureColor:[NSUnarchiver unarchiveObjectWithData:[dict objectForKey:@"QSACGestureColor"]]];
	if ([dict objectForKey:@"QSACRecognizedColor"])
		[self setRecognizedColor:[NSUnarchiver unarchiveObjectWithData:[dict objectForKey:@"QSACRecognizedColor"]]];
	if ([dict objectForKey:@"QSACFailureColor"])
		[self setFailureColor:[NSUnarchiver unarchiveObjectWithData:[dict objectForKey:@"QSACFailureColor"]]];
	if ([dict objectForKey:@"QSACModifierActivation"])
		modKeyActivation=[[dict objectForKey:@"QSACModifierActivation"] unsignedIntegerValue];
	
	if ([dict objectForKey:@"QSACMouseActivation"])
		mouseActivation=[[dict objectForKey:@"QSACMouseActivation"] unsignedIntegerValue];

	if ([[dict objectForKey:@"QSACEnableLaserKey"] boolValue]) {
		[self setLaserKey:[[[ACLaserKey alloc] init] autorelease]];
	} else {
		[self setLaserKey:nil];
	}
	[dict release];
}

- (void)reloadGestureFile:(id)sender {
	// configure the path to the Gesture plist file
    NSString *gestureFilePath = [ACGestureFilePath stringByExpandingTildeInPath];
	
	// If we find a file in the default spot, load it
	if ([[NSFileManager defaultManager] fileExistsAtPath:gestureFilePath])
	{
		[self loadGestureDictFromFile:gestureFilePath];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	controller = [[ACSparkleWindowController alloc] init];
	[controller loadWindow];
	[controller showWindow:self];
	cursorWindow = nil;
	
	[self reloadPreferences:nil];
}


// load gesture dictionary from plist file
- (BOOL)loadGestureDictFromFile:(NSString *)filePath {
	NSMutableDictionary *plistGestureDict;
    ACGesture *gesture;

	// walk through plist dictionary to regenerate gesture dictionary
	plistGestureDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
	if (!plistGestureDict)
        return NO;

    [gestureDictionary removeAllObjects];
    for (NSString *key in plistGestureDict) {
        gesture = [ACGesture gestureWithDictionary:[plistGestureDict valueForKey:key]];
        [gestureDictionary setValue:gesture forKey:key];
    }
    return YES;
}

// return the string id of the closest match to gesture
- (NSString *)recognizeGesture:(ACGesture *)gesture {
	float score, maxScore;
	NSString * topGestureName;

	maxScore = 0.0f;
	score = 0.0f;
	// walk through the list of gestures
    for (NSString *gestureName in gestureDictionary) {
        ACGesture *libraryGesture = [gestureDictionary objectForKey:gestureName];
		
		// generate a score for the gesture
		score = [libraryGesture compareGesture:gesture];

        // if that gesture's score is higher than the current max, store its name for later
		if (score > maxScore) {
			maxScore = score;
			topGestureName = gestureName;
		}
	}
    return (maxScore > 0.9 ? topGestureName : nil);
}


- (void)showGesture:(ACGesture *)gesture {
	NSWindow *result = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 512, 512)
                                                   styleMask:NSBorderlessWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
	[result setBackgroundColor:[NSColor whiteColor]];
    [result setOpaque:NO];
    [result setAlphaValue:0.999f];
    [result setShowsResizeIndicator:YES];
    [result setIgnoresMouseEvents:YES];
    [result setMovableByWindowBackground:NO];
    [result setLevel:kCGMaximumWindowLevel];
    [result setHasShadow:NO];
	ACGestureDisplayView *contentView = [[[ACGestureDisplayView alloc] init] autorelease];
    [result setContentView:contentView];
	[contentView setGesture:gesture];
	[result setCanHide:NO];
	[result makeKeyAndOrderFront:nil];
	[result setReleasedWhenClosed:YES];

	[result performSelector:@selector(close) withObject:nil afterDelay:2.0];
}

- (void)processGesture:(NSMutableArray *)theEvents {
	[self setWatchMouse:NO];
	ACGesture *gesture = [[[ACGesture alloc] initWithEventArray:theEvents] autorelease];
	NSSize s = [gesture size];
	NSString *recognizedGesture = nil;
	if (MAX(s.width, s.height) > 64){
		recognizedGesture = [self recognizeGesture:gesture];
	}

	if (recognizedGesture) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              NSStringFromSize([gesture size]), @"size",
                              NSStringFromPoint([gesture center]), @"center",
                              nil];

		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ACAbracadabraGestureRecognizedNotification
                                                                       object:recognizedGesture
                                                                     userInfo:dict
                                                           deliverImmediately:YES];
		
		NSString *sound = [preferences objectForKey:@"QSACRecognizedSound"];

#warning tiennou: That will fail if the interface gets localized
		if (sound && ![sound isEqualToString:@"No Sound"])
			[[NSSound soundNamed:sound] play];
		ACGesture *matchGesture = [gestureDictionary objectForKey:recognizedGesture];

		/* tiennou: Hmm, that ought to do something... */
#if 0
		NSEnumerator *em = [theEvents objectEnumerator];
		NSEvent *event;
		while(event=[em nextObject]){
			//NSLog(@"event %@",event);
			//[self animateForPoint:[event locationInWindow]];	
			
		}
#endif

		NSPoint *points = [matchGesture points];
		NSColor *color = [self recognizedColor];
		if (!color)
            color = [NSColor whiteColor];
		int i;
		for (i = 0; i < 32; i++) {
			NSSize size = [gesture size];
			CGFloat scale = MAX(size.width, size.height);
			NSPoint p = ACUnitPointWithCenterAndScale(points[i], [gesture center], scale);
            
			DDParticle *particle = [[[DDParticle alloc] init] autorelease];
			[particle setPoint:p];
			particle->xv = 30.0f * (-0.5f + RAND1);
			particle->yv = 5.0f * (-0.5f + RAND1);
			particle->life = ((float)i / 32) * 3.0f + RAND1;
			[particle setColor:color];
			[(DDGLView *)[[controller window] contentView] addParticle:particle];
			
		}
	} else {
		NSString *sound = [preferences objectForKey:@"QSACFailureSound"];
#warning tiennou: That will fail if the interface gets localized
		if (sound && ![sound isEqualToString:@"No Sound"])
			[[NSSound soundNamed:sound] play];
		
		NSPoint *points = [gesture points];
		NSColor *color = [self failureColor];
		if (!color)
            color = [NSColor whiteColor];
		int i;
		for (i = 0; i < 32; i++) {
			NSSize size=[gesture size];
			CGFloat scale = MAX(size.width, size.height);
			NSPoint p = ACUnitPointWithCenterAndScale(points[i], [gesture center], scale);
			DDParticle *particle = [[[DDParticle alloc] init] autorelease];
			[particle setPoint:p];
			particle->xv = 300.0f * (-0.5f + RAND1);
			particle->yv = 300.0f * (-0.5f + RAND1);
			particle->life = ((float)i / 32) * 1.0f + RAND1;
			[particle setColor:color];
			[(DDGLView *)[[controller window] contentView] addParticle:particle];
		}
	}
	[theEvents removeAllObjects];
}

#define FILLPOINTDISTANCE (32.0f * (RAND1 + 0.5))


- (void)sendEvent:(NSEvent *)event {
    switch ([event type]) {
            case NSMouseMoved:
            case NSOtherMouseDragged: {
                if (watchMouse) {
                    [events addObject:event];
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                    [self performSelector:@selector(processGesture:) withObject:events afterDelay:0.3];
                    NSPoint thisPoint = [event locationInWindow];
                    CGFloat dx = thisPoint.x - lastPoint.x;
                    CGFloat dy = thisPoint.y - lastPoint.y;
                    CGFloat dp = hypot(dx, dy);
                    
                    if (!NSEqualPoints(lastPoint, NSZeroPoint)) {
                        CGFloat f;
                        NSPoint midPoint = lastPoint;
                        
                        for (f = FILLPOINTDISTANCE; f < dp; f += FILLPOINTDISTANCE) {
                            midPoint.x = lastPoint.x + f/dp * dx;
                            midPoint.y = lastPoint.y + f/dp * dy;
                            [self animateForPoint:midPoint];
                        }
                    }
                    [self animateForPoint:thisPoint];
                    lastPoint = thisPoint;
                }
                break;
            }
        case NSOtherMouseDown:
		case NSOtherMouseUp:
            if (mouseActivation && [event buttonNumber] == (mouseActivation-1))
                [self setWatchMouse:[event type] == NSOtherMouseDown];
            break;

        case NSFlagsChanged:
            if (modKeyActivation)
                [self setWatchMouse:([event modifierFlags] & (1 << modKeyActivation)) > 0];
            break;
	}
	[super sendEvent:event];
}

- (void)animateForEvent:(NSEvent *)event {
	[self animateForPoint:[event locationInWindow]];	
}

- (void)animateForPoint:(NSPoint)location {
    DDParticle *particle=[[[DDParticle alloc] init] autorelease];
	[particle setPoint:location];
	NSColor *color = [self gestureColor];
	if (!color)
        color = [NSColor colorWithCalibratedRed:0.0f green:0.7f blue:1.0f alpha:1.0f];
	[particle setColor:color];
	[(DDGLView *)[[controller window] contentView] addParticle:particle];
}

- (void) spawn {
	[self animateForPoint:lastPoint];	
}

- (BOOL)watchMouse {
    return watchMouse;
}

- (void)setWatchMouse:(BOOL)flag {
	lastPoint = NSZeroPoint;
    watchMouse = flag;
}


- (NSColor *)gestureColor { return [[gestureColor retain] autorelease]; }
- (void)setGestureColor:(NSColor *)newGestureColor {
    if (gestureColor != newGestureColor) {
        [gestureColor release];
        gestureColor = [newGestureColor retain];
    }
}

- (NSColor *)recognizedColor { return [[recognizedColor retain] autorelease]; }
- (void)setRecognizedColor:(NSColor *)newRecognizedColor {
    if (recognizedColor != newRecognizedColor) {
        [recognizedColor release];
        recognizedColor = [newRecognizedColor retain];
    }
}

- (NSColor *)failureColor { return [[failureColor retain] autorelease]; }
- (void)setFailureColor:(NSColor *)newFailureColor {
    if (failureColor != newFailureColor) {
        [failureColor release];
        failureColor = [newFailureColor retain];
    }
}

- (NSDictionary *)preferences { return [[preferences retain] autorelease]; }
- (void)setPreferences:(NSDictionary *)newPreferences {
    if (preferences != newPreferences) {
        [preferences release];
        preferences = [newPreferences retain];
    }
}

- (id)laserKey {
    return [[laserKey retain] autorelease]; 
}

- (void)setLaserKey:(id)newLaserKey {
	[laserKey release];
	laserKey = [newLaserKey retain];
}

@end
