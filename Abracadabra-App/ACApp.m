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

#define UCSTR(u) [NSString stringWithFormat:@"%C",u]
#define EVENT_COUNT 32
#define GESTURE_PLIST_PATH @"~/Library/Application Support/Abracadabra.plist"

static BOOL mouseWasMoved=NO;
OSStatus mouseMoved(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	//NSLog(@"Event received!\n");
	//mouseWasMoved=YES;
	return CallNextEventHandler(nextHandler, theEvent);
}
OSStatus modChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	//NSLog(@"Eventx received!\n");
	return CallNextEventHandler(nextHandler, theEvent);
}

OSStatus mouseActivated(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	EventMouseButton button;
    GetEventParameter(theEvent, kEventParamMouseButton,typeMouseButton,0,
					  sizeof(button),0,&button);
	
	//	NSLog(@"------------------event %d",button);
	//[userData mouseClicked:button];
	return CallNextEventHandler(nextHandler, theEvent); 
	return eventNotHandledErr;
}

@implementation ACApp

+(void)registerEventHandlers{
	//	if (VERBOSE) NSLog(@"Registering for Global Mouse Events");
	
}

- (void)setMonitorMouseMovements:(BOOL)flag{
	//return;
	static EventHandlerRef mouseMoveRef=NULL;
	if (flag && !mouseMoveRef){
		EventTypeSpec    eventTypes[3];
		eventTypes[0].eventClass = kEventClassMouse;
		eventTypes[0].eventKind  = kEventMouseMoved;
		eventTypes[1].eventClass = kEventClassMouse;
		eventTypes[1].eventKind  = kEventMouseDragged;
		eventTypes[2].eventClass = kEventClassMouse;
		eventTypes[2].eventKind  = kEventMouseDown;
		
		
		EventHandlerUPP handlerFunction = NewEventHandlerUPP(mouseMoved);
		OSStatus err=InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 3, eventTypes, NULL, &mouseMoveRef);	
		
		static EventHandlerRef trackMouse;
		EventTypeSpec eventType[2]={{kEventClassMouse, kEventMouseUp}, {kEventClassMouse, kEventMouseDown}};
		handlerFunction = NewEventHandlerUPP(mouseActivated);
		InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 2, eventType, self, &trackMouse);
		
		//NSLog(@"installing handler %p %d",mouseMoveRef,err);
		
		
				}
	//else{
	//					//		NSLog(@"removing handler %p",mouseMoveRef);
	//					RemoveEventHandler(mouseMoveRef);
	//					mouseMoveRef=NULL;
	//				}
}
- (void)setMonitorModKeys:(BOOL)flag{
	EventTypeSpec    eventTypes[1];
	eventTypes[0].eventClass = kEventClassKeyboard;
	eventTypes[0].eventKind  = kEventRawKeyModifiersChanged;
	
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(modChanged);
	OSStatus err=InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, eventTypes, NULL, NULL);	
}

- (id)init {
	if (self=[super init]){
		[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"com.blacktree.Abracadabra.ShouldQuit" object:nil userInfo:nil deliverImmediately:YES];	
		
		
		events=[[NSMutableArray arrayWithCapacity:EVENT_COUNT]retain];
		gestureDictionary=[[NSMutableDictionary alloc]init];
		
		
		[self setMonitorModKeys:YES];
		[self setMonitorMouseMovements:YES];
		
		//	cursorWindow=[[NSWindow windowWithImage:[[NSCursor arrowCursor]image]]retain];
		//		[cursorWindow setLevel: kCGCursorWindowLevel];
		//		[cursorWindow orderFront:self];
		//		[cursorWindow setAlphaValue:0.75];
		//
		//	hotSpot=[[NSCursor arrowCursor]hotSpot];
		[self setDelegate:self];
		
		magicAmount=0.5;
		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(reloadGestureFile:)
															   name:@"com.blacktree.Abracadabra.GestureFileChanged" object:nil];
		
		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(reloadPreferences:)
															   name:@"com.blacktree.Abracadabra.PreferencesChanged" object:nil];
		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(terminate:)
															   name:@"com.blacktree.Abracadabra.ShouldQuit" object:nil];
		
		modKeyActivation=23; 
		mouseActivation=0;
		[self setRecognizedColor:[NSColor greenColor]];
		[self setGestureColor:[NSColor cyanColor]];
		[self setFailureColor:[NSColor redColor]];
		[self reloadGestureFile:nil];
		
	   }
	return self;
}

- (void)reloadPreferences:(id)sender{
	CFPreferencesSynchronize((CFStringRef)@"com.blacktree.Quicksilver", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	NSArray *array=[NSArray arrayWithObjects:
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
	NSDictionary *dict=CFPreferencesCopyMultiple(array, (CFStringRef)@"com.blacktree.Quicksilver", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
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
	
	// NSLog(@"loaded preferences %@",dict);
	//	 magicAmount=[dict objectForKey:@"QSACMagicAmount"]?[[dict objectForKey:@"QSACMagicAmount"]floatValue]:0.5;
	
	if([[dict objectForKey:@"QSACEnableLaserKey"]boolValue]){
		[self setLaserKey:[[[ACLaserKey alloc]init]autorelease]];
	}else{
		[self setLaserKey:nil];
	}
	
	//[NSNS
	[dict release];
}

- (void)reloadGestureFile:(id)sender{
	// configure the path to the Gesture plist file
    NSString *gestureFilePath = [GESTURE_PLIST_PATH stringByExpandingTildeInPath];
	
	// If we find a file in the default spot, load it
	if ([[NSFileManager defaultManager] fileExistsAtPath:gestureFilePath])
	{
		[self loadGestureDictFromFile:gestureFilePath];
	}
}
#define mOptionKeyIsDown (GetCurrentKeyModifiers()&optionKey)

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	//NSDistributedLock *lock=[NSDistributedLock lockWithPath:[@"~/Library/Application Support/.AbracadabraLock" stringByStandardizingPath]];
	
	//BOOL success=[lock tryLock];
	//	NSLog(@"abralock %d %@",success,[lock lockDate]);
	//if (!(GetCurrentKeyModifiers() & (optionKey | rightOptionKey))){
	controller=[[ACSparkleWindowController alloc]init];
	[controller loadWindow];
	[controller showWindow:self];
	//	[cursorWindow close];
	cursorWindow=nil;
	//}
	
	[self reloadPreferences:nil];
}


// load gesture dictionary from plist file
-(bool)loadGestureDictFromFile:(NSString *) filePath 
{
	NSMutableDictionary *plistGestureDict, *pointDict;
	NSEnumerator *gestureEnumerator, *pointEnumerator;
	NSMutableArray *nestedGesture, *gesture;
	id key;
	
	// walk through plist dictionary to regenerate gesture dictionary
	plistGestureDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
	if(nil != plistGestureDict)
	{	
		[gestureDictionary removeAllObjects];
		//NSLog(@"gestur %@",[plistGestureDict allKeys]);
		gestureEnumerator = [plistGestureDict keyEnumerator];
		while ((key = [gestureEnumerator nextObject]))
		{
			gesture = [ACGesture gestureWithDictionary:[plistGestureDict valueForKey:key]];
			[gestureDictionary setValue:gesture forKey:key];
			//NSLog(@"loaded %@ %@",key, gesture);
		}
		return YES;
	}
	else
		return NO;
	
}

// return the string id of the closest match to gesture
-(NSString *)recognizeGesture:(ACGesture *) gesture
{
	int i;
	float score, maxScore;
	NSArray * keys;
	NSString * topGestureName;
	NSString * gestureName;
	ACGesture * libraryGesture;
	
	// get all gesture ideas
	keys = [gestureDictionary allKeys];
	
	maxScore = 0.0f;
	score = 0.0f;
	
	// walk through the list of gestures
	for (i=0; i < [keys count]; i++)
	{
		gestureName = [keys objectAtIndex:i];
		libraryGesture = [gestureDictionary objectForKey:gestureName];
		
		// generate a score for the gesture
		score = [libraryGesture compareGesture:gesture];
		//NSLog(@"%@: score %f",gestureName,score);
		// add the score to the last match dictionary so we can examine the results later
		//	[lastMatchDictionary setValue:[NSNumber numberWithFloat:score] forKey:gestureName];
		
		
		if (score > maxScore)
		{
			maxScore = score;
			topGestureName = [keys objectAtIndex:i];
		}
		
	}
	if (maxScore > 0.9) 
	{
		return topGestureName;
	}
	else
		return nil;
}


- (void)showGesture:(ACGesture *)gesture{
	NSWindow* result = [[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,512,512) styleMask: NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[result setBackgroundColor: [NSColor whiteColor]];
    [result setOpaque:NO];
    [result setAlphaValue:0.999f];
    [result setShowsResizeIndicator:YES];
    [result setIgnoresMouseEvents:YES];
    [result setMovableByWindowBackground:NO];
    [result setLevel:kCGMaximumWindowLevel];
    [result setHasShadow:NO];
	NSView *contentView=[[[ACGestureDisplayView alloc]init]autorelease];
    [result setContentView:contentView];
	[contentView setGesture:gesture];
	[result setCanHide:NO];
	[result makeKeyAndOrderFront:nil];
	[result setReleasedWhenClosed:YES];
	
	
	[result performSelector:@selector(close) withObject:nil afterDelay:2.0];
}
- (void)processGesture:(NSMutableArray *)theEvents{
	//lastPoint=NSZeroPoint
	//NSLog(@"recognizing");
	[self setWatchMouse:NO];
	ACGesture *gesture=[[[ACGesture alloc]initWithEventArray:theEvents]autorelease];
	NSSize s=[gesture size];
	NSString *recognizedGesture=nil;
	if (MAX(s.width,s.height)>64){
		recognizedGesture=[self recognizeGesture:gesture];
	}
	//[self showGesture:gesture];
	if (recognizedGesture){
		NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
			NSStringFromSize([gesture size]),@"size",
			NSStringFromPoint([gesture center]),@"center",nil];
		
		//		CGPostKeyboardEvent(0,57,TRUE);
		//		CGPostKeyboardEvent(0,57,FALSE);
		
		[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"com.blacktree.Abracadabra.GestureRecognized"
																	  object:recognizedGesture
																	userInfo:dict
														  deliverImmediately:YES];
		
		NSString *sound=[preferences objectForKey:@"QSACRecognizedSound"];
		//[[[[NSSound alloc]initWithContentsOfFile:@"/System/Library/Sounds/Blow.aiff" byReference:YES]autorelease]play];
		
		if (sound && ![sound isEqualToString:@"No Sound"])
			[[NSSound soundNamed:sound]play];
		ACGesture *matchGesture=[gestureDictionary objectForKey:recognizedGesture];
		
		NSEnumerator *em=[theEvents objectEnumerator];
		NSEvent *event;
		while(event=[em nextObject]){
			//NSLog(@"event %@",event);
			//[self animateForPoint:[event locationInWindow]];	
			
		}
		NSPoint *points=[matchGesture points];
		NSColor *color=[self recognizedColor];
		if (!color)color=[NSColor whiteColor];
		int i;
		for (i=0;i<32;i++){
			NSSize size=[gesture size];
			float scale=MAX(size.width,size.height);
			NSPoint p=ACUnitPointWithCenterAndScale(points[i],[gesture center],scale);
			//	p.x*=100;
			//			p.y*=100;
			//			p.x+=100;
			//			p.y+=100;
			DDParticle *particle=[[[DDParticle alloc]init]autorelease];
			[particle setPoint:p];
			particle->xv=30.0f*(-0.5f + RAND1);
			particle->yv=5.0f*(-0.5f + RAND1);
			particle->life=((float)i/32)*3.0f + RAND1;
			[particle setColor:color];
			[[[controller window]contentView] addParticle:particle];
			
		}
		
		//[[[[NSAppleScript alloc]initWithSource:[NSString stringWithFormat:@"say \"%@\"",recognizedGesture]]autorelease]executeAndReturnError:nil];
		//NSLog(@"recognized %@ %@",recognizedGesture,matchGesture);
		
	}else{
		
		NSString *sound=[preferences objectForKey:@"QSACFailureSound"];
		//NSLog(@"sound %@",sound);
		if (sound && ![sound isEqualToString:@"No Sound"])
			[[NSSound soundNamed:sound]play];
		
		NSPoint *points=[gesture points];
		NSColor *color=[self failureColor];
		if (!color)color=[NSColor whiteColor];
		int i;
		for (i=0;i<32;i++){
			NSSize size=[gesture size];
			float scale=MAX(size.width,size.height);
			NSPoint p=ACUnitPointWithCenterAndScale(points[i],[gesture center],scale);
			//	p.x*=100;
			//			p.y*=100;
			//			p.x+=100;
			//			p.y+=100;
			DDParticle *particle=[[[DDParticle alloc]init]autorelease];
			[particle setPoint:p];
			particle->xv=300.0f*(-0.5f + RAND1);
			particle->yv=300.0f*(-0.5f + RAND1);
			particle->life=((float)i/32)*1.0f + RAND1;
			[particle setColor:color];
			[[[controller window]contentView]addParticle:particle];
			
		}
		
	}
	
	[theEvents removeAllObjects];
}

#define FILLPOINTDISTANCE (32.0f*(RAND1+0.5))


- (void)sendEvent:(NSEvent *)event{
	
		//NSLog(@"event %@",event);
	
	if ([event type]==NSMouseMoved  || [event type]==NSOtherMouseDragged){
		//if ([events count]==EVENT_COUNT)[events removeObjectAtIndex:0];
		if (watchMouse){
			[events addObject:event];
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(processGesture:) withObject:events afterDelay:0.3];
			NSPoint thisPoint=[event locationInWindow];
			float dx=thisPoint.x-lastPoint.x;
			float dy=thisPoint.y-lastPoint.y;
			float dp=hypotf(dx,dy);
			
			if (!NSEqualPoints(lastPoint,NSZeroPoint)){
				float f;
				NSPoint midPoint=lastPoint;
				
				for (f=FILLPOINTDISTANCE;f<dp;f+=FILLPOINTDISTANCE){
					
					midPoint.x=lastPoint.x + f/dp * dx;
					midPoint.y=lastPoint.y + f/dp * dy;
					[self animateForPoint:midPoint];
				}
			}
			[self animateForPoint:thisPoint];
			lastPoint=thisPoint;
		}
		
	}else if ([event type]==NSOtherMouseDown){
		if (mouseActivation && [event buttonNumber]==(mouseActivation-1))
			[self setWatchMouse:YES];
		
	}else if ([event type]==NSOtherMouseUp){
		if (mouseActivation && [event buttonNumber]==(mouseActivation-1))
			[self setWatchMouse:NO];
		
	}else if ([event type]==NSFlagsChanged){
		//NSLog(@"Event: %@",event);
		//NSLog(@"%x %x",[event modifierFlags],modKeyActivation);
		if (modKeyActivation)
			[self setWatchMouse:([event modifierFlags] & (1 << modKeyActivation)) > 0];
	}
	[super sendEvent:event];
	
}
- (void)animateForEvent:(NSEvent *)event{
	[self animateForPoint:[event locationInWindow]];	
}
- (void)animateForPoint:(NSPoint)location{
	//NSLog(@"%f %f",location.x, location.y);
	//	[cursorWindow setFrameTopLeftPoint:NSMakePoint(location.x-hotSpot.x,location.y+hotSpot.y)];
				DDParticle *particle=[[[DDParticle alloc]init]autorelease];
	[particle setPoint:location];
	NSColor *color=[self gestureColor];
	if (!color)color=[NSColor colorWithCalibratedRed:0.0f green:0.7f blue:1.0f alpha:1.0f];
	[particle setColor:color];
	[[[controller window]contentView]addParticle:particle];
	
	//[[[controller window]contentView]addParticleAtPoint:location];
	//[animator createWindowAtPoint:location];
	//	[animator animateWindows];
	//	lastPoint=location;
	
}

- (void) spawn{
	[self animateForPoint:lastPoint];	
}


#import <math.h>
//- (void)handleMovementOfX:(float)x andY:(float)y at:(float)t{
//	
//	NSTimeInterval diff=t-lastEventTime;
//	
//	currentEventNumber=(currentEventNumber+1)%EVENT_COUNT;
//	
//	
//	//NSLog(@"%f %f %d",x,y,currentEventNumber);
//	
//	
//	int i;
//	float dx=x,dy=y;
//	for (i=(currentEventNumber-1)%EVENT_COUNT; i!=currentEventNumber;i=(i+EVENT_COUNT-1)%EVENT_COUNT){
//		dx+=events[i][0];		
//		dy+=events[i][1];
//		if (t-events[i][2]>1.0)break;
//		//NSLog(@"i %d",i);
//	}
//	events[currentEventNumber][0]=x;
//	events[currentEventNumber][1]=y;
//	events[currentEventNumber][2]=t;
//	
//	float distance=sqrt(pow(dy,2)+pow(dx,2));
//	int newDirection=fmod(round(4+8*atan2(dy,dx)/M_PI/2),8);
//	
//	if (distance>100 && newDirection!=direction){
//		direction=newDirection;
//		
//		//		NSLog(@"Dragged in direction:%d persist:%d distance:%d",direction,persist,(int)distance);
//		
//		persist=0;
//		
//	}else{
//		persist++;	
//	}
//	
//	
//}
//

- (BOOL)watchMouse {
    return watchMouse;
}

- (void)setWatchMouse:(BOOL)flag {
	lastPoint=NSZeroPoint;
	//NSLog(@"watch %d",flag);
    watchMouse = flag;
}


- (NSColor *)gestureColor { return [[gestureColor retain] autorelease]; }
- (void)setGestureColor:(NSColor *)newGestureColor
{
    if (gestureColor != newGestureColor) {
        [gestureColor release];
        gestureColor = [newGestureColor retain];
    }
}


- (NSColor *)recognizedColor { return [[recognizedColor retain] autorelease]; }
- (void)setRecognizedColor:(NSColor *)newRecognizedColor
{
    if (recognizedColor != newRecognizedColor) {
        [recognizedColor release];
        recognizedColor = [newRecognizedColor retain];
    }
}

- (NSColor *)failureColor { return [[failureColor retain] autorelease]; }
- (void)setFailureColor:(NSColor *)newFailureColor
{
    if (failureColor != newFailureColor) {
        [failureColor release];
        failureColor = [newFailureColor retain];
    }
}


- (NSDictionary *)preferences { return [[preferences retain] autorelease]; }
- (void)setPreferences:(NSDictionary *)newPreferences
{
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



//	NSLog(@"MOVED %04d %04d %f",(int)[event deltaX],(int)[event deltaY], [event timestamp])	;
//[self handleMovementOfX:[event deltaX] andY:[event deltaY] at:[event timestamp]];	

//		if ((GetCurrentKeyModifiers() & controlKey)){
//			
//			NSPoint loc=[NSEvent mouseLocation];
//			loc.y=NSHeight([[NSScreen mainScreen]frame])-loc.y;
//			
//	
//			int x=-[event deltaX]*3;
//			int y=-[event deltaY]*10;
//			
//			int eventcount=MAX(1+abs(x) / 10,1+abs(y) /10);
//			
//			//NSLog(@"MOVE %04d %04d %d %f",x,y, eventcount,[event timestamp])	;
//			int i;
//			while (eventcount>0){
//				int dx=x/eventcount;
//				int dy=y/eventcount;
//				eventcount--;
//				x-=dx;
//				y-=dy;
//				//NSLog(@">>>> %04d %04d %f",dx,dy, [event timestamp])	;
//				CGPostScrollWheelEvent(2,dy,dx);
//			}
//			//
//			
//			CGWarpMouseCursorPosition(CGPointMake(loc.x-[event deltaX],loc.y-[event deltaY] ));	
//			
//		//	CGPostScrollWheelEvent(1,[event deltaX]);
////			GetGlobalMouse(Point * globalMouse)                           
//			}
//		
//