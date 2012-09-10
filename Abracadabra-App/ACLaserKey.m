//
//  ACLaserKey.m
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ACLaserKey.h"


#import <Carbon/Carbon.h>

@implementation NSData (RangeExtensions)
// This function is a modification of OmniFoundation's  - (BOOL)containsData:(NSData *)data; to return an offset
- (unsigned)offsetOfData:(NSData *)data
{
    unsigned const char *selfPtr, *selfEnd, *selfRestart, *ptr, *ptrRestart, *end;
    unsigned myLength, otherLength;
	
	unsigned offset=0;
    ptrRestart = [data bytes];
    otherLength = [data length];
    if (otherLength == 0)
        return 0;
    end = ptrRestart + otherLength;
    selfRestart = [self bytes];
    myLength = [self length];
    if (myLength < otherLength) // This test is a nice shortcut, but it's also necessary to avoid crashing: zero-length CFDatas will sometimes(?) return NULL for their bytes pointer, and the resulting pointer arithmetic can underflow.
        return NSNotFound;
    selfEnd = selfRestart + (myLength - otherLength);
	
    /* A note on the goto in the following code, for the structure-obsessed among us: it could be replaced with a flag and a 'break', yes, but since that code path is the most common one (and gcc3 doesn't optimize out control-flow flags) it seems worth the potential disapprobation from the use of reviled goto. */
    
    while(selfRestart <= selfEnd) {
        selfPtr = selfRestart;
        ptr = ptrRestart;
        while(ptr < end) {
            if (*ptr++ != *selfPtr++)
                goto notThisOffset;
        }
        return offset;
		
notThisOffset:
			
			selfRestart++;
		offset++;
    }
    return NSNotFound;
}
@end

#define MAXLENGTH 29
@implementation ACLaserKey

//- (void)handleMovementXchar dx, char dy){
//	x+=dx;
//	y+=dy;
//	
//	CGPoint pos=CGPointMake(x,y);
//	
//	CGSetLocalEventsSuppressionInterval(0);
//	CGWarpMouseCursorPosition(pos);
//}
//void setPoint(char dx,unsigned char dy){
//	x=512*(1+(float)dx/256);
//	y=384*((float)dy/256);
//	//NSLog(@"set %d %d (%f, %f)",dx,dy,x,y);
//	CGPoint pos=CGPointMake(x,y);
//	
//	CGSetLocalEventsSuppressionInterval(0);
//	CGWarpMouseCursorPosition(pos);
//}
- (id) init {
	self = [super init];
	if (self != nil) {
		events=[[NSMutableArray alloc]init];
		pipeData=[[NSMutableData alloc]init];
		char delim[6];
		delim[0]=165;
		delim[1]=165;
		delim[2]=1;
		delim[3]=0;
		delim[4]=0;
		delim[5]=0;
		
		delimiter=[[NSData dataWithBytes:delim length:6]retain];
		
		[self watchSerialPort];
	}
	return self;
}



- (void) processData:(NSData *)data{
//	return;
	if ([data length]>=23){
		const char *bytes=[data bytes];
		// 01000000 06ff0111 0001ffff ff00TTXX xxYYyy1d db020000 000063

		// 01000000 02ff0112 0001ffff ff0002e5 ff8c005f 01060000 0100467c

		if (delegate){
			[delegate sendLaserKeyEvent:data];
			return;	
		}

		char t=bytes[TYPE_INDEX];
		char dx=bytes[DX_INDEX];
		char dy=bytes[DY_INDEX];
		char key=bytes[KEY_INDEX];
		p.x+=dx;
		p.y-=dy;
		//NSLog(@"Event [%d] (%d,%d) '%c' (%d)",t,dx,dy,key,(unsigned char)key);
		switch (t){
			case ACLKMoved:
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				[NSApp animateForPoint:p];
				[events addObject:[NSEvent mouseEventWithType:NSMouseMoved 
													 location:p
												modifierFlags:0
													timestamp:[[NSDate date]timeIntervalSinceReferenceDate]
												 windowNumber:0 context:0 eventNumber:0 clickCount:0 pressure:0]];
				[self performSelector:@selector(processGesture:)
						   withObject:events afterDelay:0.3];
	
				break;
			case ACLKEnter:
				//[[NSSound soundNamed:@"Purr"]play];
				//[NSApp performSelectorOnMainThread:@selector(processGesture:) withObject:events waitUntilDone:NO];
				p=NSMakePoint(512,384);
				//setPoint(x,y);
				break;
			case ACLKKeyRepeat:
				break;
			case ACLKKeyDown:
						[[NSSound soundNamed:@"Tink"]play];
///				CGPostKeyboardEvent(0,57,FALSE);
			case ACLKKeyRelease:
	//			CGPostKeyboardEvent(0,57,TRUE);
				
				break;
	
			default:
			break;
		}
	}else if ([data length]){
		NSLog(@"shortData %@",data);
	}
}
- (void)processGesture:(NSArray *)theEvents{
	[NSApp processGesture:theEvents];
}


- (void)dataRecieved:(NSNotification *)notif{
	NSData *data=[[notif userInfo]objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]){
		[pipeData appendData:data];
		[self pullEventsFromData:pipeData];
		[handle readInBackgroundAndNotify];
	}else{
		NSLog(@"LaserKey: No Data Recieved");
		[handle release];
		handle=nil;
			[[NSSound soundNamed:@"Basso"]play];
		[self performSelector:@selector(watchSerialPort)
				   withObject:nil afterDelay:10.0];	
	}
}
- (void) dealloc {
	[self setDelegate:nil];

NSLog(@"laser dealloc");
[[NSNotificationCenter defaultCenter]removeObserver:self];
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
[handle release];
	[super dealloc];
}


- (void)pullEventsFromData:(NSMutableData *)data{

	int offset;
	while ((offset=[pipeData offsetOfData:delimiter])!=NSNotFound){
		//NSLog(@"data %@ %d",data,offset);
		NSData *subdata=[pipeData subdataWithRange:NSMakeRange(0,offset)];
		if (offset>0)
			[self processData:subdata];
		[pipeData replaceBytesInRange:NSMakeRange(0,offset+[delimiter length]) withBytes:NULL length:0];

		//NSLog(@"xata %@ %@ %d",subdata,data,offset);
	}	
}
#define SERIALPORT @"/dev/cu.CL800BT-SerialPort-1"
- (void)watchSerialPort{
	//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fm=[NSFileManager defaultManager];
	if ([fm fileExistsAtPath:SERIALPORT]){

		handle=[[NSFileHandle fileHandleForReadingAtPath:SERIALPORT]retain];
			NSLog(@"Connecting to laserkey %@",handle);

}
	if (handle){
		
		//[[NSSound soundNamed:@"Submarine"]play];
		
	[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(dataRecieved:)
													name:NSFileHandleReadCompletionNotification
											  object:handle];
	
	[handle readInBackgroundAndNotify];
	}else{
		//[self performSelector:@selector(watchSerialPort)
		//		   withObject:nil afterDelay:10.0];	
	}
}




- (id)delegate { return [[delegate retain] autorelease]; }
- (void)setDelegate:(id)newDelegate
{
    if (delegate != newDelegate) {
        [delegate release];
        delegate = [newDelegate retain];
    }
}




@end
