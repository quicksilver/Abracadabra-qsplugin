//
//  QSGestureTriggerManager.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on Sun Jun 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACGestureEditView;
@class ACGesture;

@interface QSGestureTriggerManager : QSTriggerManager {
	IBOutlet ACGestureEditView *gestureView;
	NSMutableDictionary *enabledTriggers;
	NSTask *abraTask;
}

+ (id)sharedInstance;
- (void)gestureView:(ACGestureEditView *)view drewGesture:(ACGesture *)gesture;
@end
