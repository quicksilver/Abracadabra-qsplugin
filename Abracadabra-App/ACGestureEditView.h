//
//  ACGestureEditView.h
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACGestureDisplayView.h"

@interface ACGestureEditView : ACGestureDisplayView {
	NSMutableArray *points;
	id delegate;
}
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end
