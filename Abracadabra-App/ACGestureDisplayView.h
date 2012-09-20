/* 
	GestureDisplayView 
	
	Written by Jason Cornwell
	
	Static display of a normalized gesture

*/

#import <Cocoa/Cocoa.h>
#import "ACGesture.h"

NSPoint ACUnitPointInFrame(NSPoint p, NSRect r);
NSPoint ACCenteredUnitPointInFrame(NSPoint p, NSRect r);
NSPoint ACUnitPointWithCenterAndScale(NSPoint p, NSPoint c, CGFloat scale);
void ACDrawDotAtPoint(NSPoint p, CGFloat r);
	
@interface ACGestureDisplayView : NSView {
	ACGesture *gesture;
	NSArray *events;
	BOOL drawToScale;
}
- (ACGesture *)gesture;
- (void)setGesture:(ACGesture *)newGesture;
@end
