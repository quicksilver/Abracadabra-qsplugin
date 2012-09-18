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

#define QSTriggerCenter NSClassFromString(@"QSTriggerCenter")
#define NSAllModifierKeysMask (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask|NSFunctionKeyMask)
@interface QSGestureTableCell : NSTextFieldCell
@end
@implementation QSGestureTableCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
//	NSLog(@"[self representedObject] %@",[self representedObject]);
	//cellFrame=;
	//	[[NSColor redColor]set];
	
	//	NSRectFill(cellFrame);	
	
	cellFrame=alignRectInRect(fitRectInRect(NSMakeRect(0,0,1000,1000),cellFrame,NO),
							  cellFrame,1);
	NSBezierPath *background=[NSBezierPath bezierPath];
	
	[background appendBezierPathWithRoundedRectangle:cellFrame withRadius:2];
	
	
	NSColor *color=[self isHighlighted]?[NSColor textBackgroundColor]:[NSColor textColor];
	
	[[color colorWithAlphaComponent:0.2] set];
	[background fill];
	cellFrame=NSInsetRect(cellFrame,2,2);
	
	
	
	ACGesture *gesture=[ACGesture gestureWithDictionary:[[self representedObject] objectForKey:@"gesture"]];
	
	NSBezierPath *path = [[[NSBezierPath alloc] init]autorelease];
	
	[color set];
	if (gesture){
		NSPoint *points=[gesture points];
		//	NSPoint center=[self convertPoint:[gesture center] fromView:nil];
		NSSize size=[gesture size];
		
		int i;
		
		
		for(i = 0; i < 32; i++) {
			NSPoint p=points[i];
			p.y=-p.y;
			p=ACCenteredUnitPointInFrame(p,cellFrame);
			//		if (drawToScale){				
			//				p=ACUnitPointWithCenterAndScale(points[i],center,scale);
			//			}
			if (i==0){
				[path moveToPoint: p];
				ACDrawDotAtPoint(p,1.5);
			}else{
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
-(NSString *)name{
	return @"Gesture";
}
-(NSImage *)image{
	return [[NSBundle bundleForClass:[self class]] imageNamed:@"Gesture"];
}
- (void)initializeTrigger:(NSMutableDictionary *)trigger{
}

+ (id)sharedInstance{
    static QSGestureTriggerManager *_sharedInstance = nil;
    if (!_sharedInstance){
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    }
    return _sharedInstance;
}

- (id) init{
    if (self=[super init]){
		//      		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:)
		//                                                   name:NSApplicationDidChangeScreenParametersNotification object:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrigger"
				  options:0
				  context:nil];
		enabledTriggers=[[NSMutableDictionary alloc]init];
		
		
		[[NSDistributedNotificationCenter defaultCenter]addObserver:self
														   selector:@selector(gestureRecognized:)
															   name:@"com.blacktree.Abracadabra.GestureRecognized"
															 object:nil];
		
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(appTerminating:)
													name:NSApplicationWillTerminateNotification
												  object:nil];
		
    }
    return self;
}

- (NSCell *)descriptionCellForTrigger:(QSTrigger *)trigger{
	return	[[[QSGestureTableCell alloc]init]autorelease];
}

- (void)appTerminating:(NSNotification *)notif{
	[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"com.blacktree.Abracadabra.ShouldQuit" object:nil userInfo:nil deliverImmediately:YES];	
}
- (void)gestureRecognized:(NSNotification *)notif{
	NSString *identifier=[notif object];
	
	//NSLog(@"recognized: %@",identifier);
	QSTrigger *trigger=[[QSTriggerCenter sharedInstance]triggerWithID:identifier];
	BOOL showStatus=[[[trigger info]objectForKey:@"showWindow"]boolValue];
	NSWindow *window=nil;
	if (showStatus){
		window=[self triggerDisplayWindowWithTrigger:trigger];
		//window=[QSWindow windowWithImage:[[trigger command]icon]];
		NSDictionary *info=[notif userInfo];
		NSPoint center=NSPointFromString([info objectForKey:@"center"]);
		
		[window setFrame:NSOffsetRect([window frame],center.x-NSMidX([window frame]),center.y-NSMidY([window frame])) display:NO];
		[window setAlphaValue:0];
		[(QSWindow *)window reallyOrderFront:self];	
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125",@"duration",@"QSGrowEffect",@"transformFn",@"show",@"type",nil]];
		//[(QSWindow *)window reallyOrderOut:self];	
	}
	
	[trigger execute];
	[window flare:self];
	
	[window reallyOrderOut:nil];
	[window close];
	///	[[QSTriggerCenter sharedInstance]executeTriggerID:identifier];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self populateInfoFields];
}

-(BOOL)enableTrigger:(QSTrigger *)entry{
	[enabledTriggers setObject:entry forKey:[entry identifier]];
	[self writeGestureTriggers];
	[self launchAbra];
    return YES;
}

-(BOOL)disableTrigger:(QSTrigger *)entry{
	[enabledTriggers removeObjectForKey:[entry identifier]];
	[self writeGestureTriggers];
    return YES;
}
- (void)abraTerminated:(NSNotification *)notif{
	//NSLog(@"abraterm");	
	[abraTask release];
	abraTask=nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self launchAbra];
}
- (void)launchAbra{
	
	//[[NSDistributedLock lockWithPath:[@"~/.abralock",NO)];
	NSBundle *bundle=[NSBundle bundleForClass:[self class]];
	NSString *path=[bundle pathForResource:@"Abracadabra" ofType:@"app"];
	NDProcess *proc=[NDProcess processForApplicationPath:path];
	
	
	
	if (!proc){
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
-(void)writeGestureTriggers{
	NSArray *keys=[enabledTriggers allKeys];
	NSArray *values=[enabledTriggers objectsForKeys:keys notFoundMarker:[NSNull null]];
	
	values=[values valueForKey:@"gesture"];
	NSMutableDictionary *gestureDictionary=[NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
	[gestureDictionary removeObjectsForKeys:[gestureDictionary allKeysForObject:[NSNull null]]];
	//NSLog(@"writing %@",gestureDictionary );
	[gestureDictionary writeToFile:[@"~/Library/Application Support/Abracadabra.plist" stringByStandardizingPath] atomically:NO];
	
	[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"com.blacktree.Abracadabra.GestureFileChanged" object:nil userInfo:nil deliverImmediately:NO];
}


//	
//	foreach(match,matchedTriggers){
//		//	NSLog(@"matched %@",match);
//		[[QSTriggerCenter sharedInstance] executeTrigger:match]; 

//- (NSString *)descriptionForTrigger:(NSDictionary *)dict{return [[self class]descriptionForTrigger:dict];}
- (NSString *)descriptionForTrigger:(NSDictionary *)dict{
	return @"Gesture";
}

- (void)gestureView:(ACGestureEditView *)view drewGesture:(ACGesture *)gesture{
	
	//	NSLog(@"setGesture %@",gesture);
	[[[self currentTrigger]info]setObject:[gesture dictionaryRepresentation] forKey:@"gesture"];
	
	[[NSClassFromString(@"QSTriggerCenter") sharedInstance] triggerChanged:[self currentTrigger]];
	[self writeGestureTriggers];
}
- (NSView *) settingsView{
    if (!settingsView){
        [NSBundle loadNibNamed:@"QSGestureTrigger" owner:self];	
		//[self bind:@"gesture" toObject:gestureView withKeyPath:@"gesture" options:nil];
		[gestureView setDelegate:self];
	}
    return [[settingsView retain] autorelease];
}

- (void)populateInfoFields{
	NSDictionary *thisTrigger=currentTrigger;
	//NSLog(@"trigger %@",currentTrigger);
	if([[thisTrigger objectForKey:@"type"]isEqualToString:@"QSGestureTrigger"]){
		[gestureView setGesture:[ACGesture gestureWithDictionary:[thisTrigger objectForKey:@"gesture"]]];
	}	
}


@end
