//
//  ACGesture.h
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 12/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GESTURE_LENGTH 32
@interface ACGesture : NSObject {
	NSPoint points[GESTURE_LENGTH];
	NSPoint center;
	NSSize size;
	float dotProductWithSelf;
}
+ (ACGesture *)gestureWithDictionary:(NSDictionary *)dictionary;
- (ACGesture *)initWithEventArray:(NSArray *)array;
- (CGFloat)compareGesture:(ACGesture *)gesture;
- (CGFloat)dotProductWithGesture:(ACGesture *)gesture;
- (NSBezierPath *)path;
- (CGFloat)length;
- (NSPointPointer)points;
- (NSPoint)center;
- (void)setCenter:(NSPoint)newCenter;
- (NSSize)size;
- (void)setSize:(NSSize)newSize;

- (NSDictionary *)dictionaryRepresentation;
@end
