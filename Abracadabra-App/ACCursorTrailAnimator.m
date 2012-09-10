//
//  ACCursorTrailAnimator.m
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ACCursorTrailAnimator.h"


@implementation ACCursorTrailAnimator
- (id)init{
	if (self=[super init]){
		windows=[[NSMutableArray alloc]init];
		animationTimer=[[NSTimer scheduledTimerWithTimeInterval:0.0333 target:self selector:@selector(animateWindows)
													   userInfo:nil repeats:YES]retain];
		
		image=[NSImage imageNamed:@"Sparkle"];
	}
	return self;
	
}
- (void)createWindowAtPoint:(NSPoint)point{
	NSWindow *cursorWindow=[NSWindow windowWithImage:image];
	[cursorWindow setLevel: kCGCursorWindowLevel];
	
	NSPoint hotSpot=NSMakePoint(9,9);//;[[NSCursor arrowCursor]hotSpot];
	float offset=(float)rand()/INT_MAX*4.0; 
	[cursorWindow setFrameTopLeftPoint:NSMakePoint(offset+point.x-hotSpot.x,point.y+hotSpot.y-3)];
	[cursorWindow setAlphaValue:1.0f];
	[cursorWindow orderFront:self];
	
	[windows addObject:cursorWindow];
}

-(void)animateWindows{
	NSEnumerator *e=[windows objectEnumerator];
	NSWindow *window;
	NSDisableScreenUpdates();
	while(window=[e nextObject]){
		float alpha=[window alphaValue];
		if (alpha<=0){
			[window close];
			[windows removeObject:window];
			
		}else{
	[window setFrame:NSOffsetRect([window frame],0,(int)(-1-2*(1-alpha))) display:NO];
			[window setAlphaValue:alpha-0.05];
			
		}
		//NSLog(@"%f",[window alphaValue]);
		
	}
	NSEnableScreenUpdates();

}

@end
