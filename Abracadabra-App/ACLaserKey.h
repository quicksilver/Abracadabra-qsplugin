//
//  ACLaserKey.h
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _ACLaserEventType {		/* various types of events */
    ACLKKeyRelease = 0,
    ACLKKeyDown    = 1,
    ACLKKeyRepeat  = 2,
    ACLKEnter      = 3,
    ACLKExit       = 4,
    ACLKUnknown2   = 5,
    ACLKMoved      = 6,
    ACLKUnknown3   = 7
} ACLaserEventType;

#define TYPE_INDEX 10
#define DX_INDEX 11
#define DY_INDEX 13
#define KEY_INDEX 22

@interface ACLaserKey : NSObject {
	NSPoint p;
	NSMutableArray *events;
	NSFileHandle *handle;
	NSMutableData *pipeData;
	NSData *delimiter;
	id delegate;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end
