//
//  ACGesture.m
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 12/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ACGesture.h"


@implementation ACGesture
+ (ACGesture *)gestureWithDictionary:(NSDictionary *)dictionary{
	return [[[ACGesture alloc]initWithDictionary:dictionary]autorelease];
}

- (NSPointPointer)points{
	return points;	
}
- (id) initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];
	if (self != nil) {
		NSUInteger i;
		NSArray *pointArray=[dictionary objectForKey:@"points"];
		// step through gesture
		for(i = 0; i < (NSUInteger)GESTURE_LENGTH && i<[pointArray count]; i++) {
			points[i]=NSPointFromString([pointArray objectAtIndex:i]);
		}
		size=NSSizeFromString([dictionary objectForKey:@"size"]);
		center=NSPointFromString([dictionary objectForKey:@"center"]);
	}
	return self;
}
- (ACGesture *)initWithEventArray:(NSArray *)events{
	self = [super init];
	if (self != nil) {
		[self getNormalizedPointsFromEvents:events];
	}
	return self;
}

- (id) initWithOldPointArray:(NSArray *)array {
	self = [super init];
	if (self != nil) {
    NSUInteger i = 0;
    for(NSDictionary *pointDict in array){
		points[i].x = [[pointDict valueForKey:@"x"] floatValue];
        points[i].y = [[pointDict valueForKey:@"y"] floatValue];
        i++;
		}
	}
	return self;
}
- (NSArray *)dictionaryRepresentation{
	NSMutableArray *array=[NSMutableArray arrayWithCapacity:GESTURE_LENGTH];
	int i;
	
	// step through gesture
	for(i = 0; i < (int)GESTURE_LENGTH; i++) {
		[array addObject:NSStringFromPoint(points[i])];
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		array,@"points",
		NSStringFromSize(size),@"size",
		NSStringFromPoint(center),@"center",nil];
}

float ACLengthOfPath(NSPointPointer points,int count){
	int i;	
	float length=0;
	// step through gesture
	for(i = 0; i < count - 1; i++) {
		//	NSLog( @"len %f %f %f %f %f",length,points[i].x,points[i+1].x,points[i].y,points[i+1].y);
		length += hypotf(points[i].x-points[i+1].x,points[i].y-points[i+1].y);
	}
	
	return length;
	
}
void ACReducePointsInPath(NSPointPointer points,int oldCount, int newCount){
	//	NSLog(@"reduce %d to %d",oldCount, newCount);
	// strip down to 32 points
	// to create normalized gesture
	
	// add first point - this will always be the same	
	NSPoint last=points[0];
	
	float	width, height, scale, gestureLength, segLength,
		distanceCoveredSinceLastPoint, totalDistanceCovered, ratio, distanceBetweenPoints;
	int		i, numPoints;
	float	x, y, x2, y2;
	
	
	gestureLength=ACLengthOfPath(points,oldCount);
	segLength = gestureLength / newCount;
	
	distanceCoveredSinceLastPoint = 0;
	totalDistanceCovered = 0;
	i = 1;
	numPoints = 1;
	NSPoint normPoints[newCount];
	normPoints[0]=points[0];
	//NSLog(@"point  0, %f, %f",normPoints[numPoints].x,normPoints[numPoints].y);
	
	//NSLog(@"seg %f %f",gestureLength,segLength);
	while ( (i < oldCount) && (totalDistanceCovered <= gestureLength) &&(numPoints<newCount)) {
		
		// Get the distance between the current point and the next point in the queue
		distanceBetweenPoints = hypotf(points[i].x-last.x,points[i].y-last.y);
		
		// If the distance covered since the last recorded point plus the distance between
		//  the current point and the next candidate point is greater than the segment length,
		//  then we have overshot our next recorded point.  This point will be between the current point
		//  (x,y) and the last recorded point (lastx, lasty)
		
		if (distanceBetweenPoints <= segLength){
			distanceCoveredSinceLastPoint += distanceBetweenPoints;
			//last=points[i]; // ??
			i++;
			//NSLog(@"nextPoint %d of %d - %f",i,oldCount,distanceCoveredSinceLastPoint);
		}else{
			ratio = segLength / distanceBetweenPoints;
			NSPoint newPoint;
			newPoint.x = last.x + ( ratio * (points[i].x - last.x));
			newPoint.y = last.y + ( ratio * (points[i].y - last.y));
			
			normPoints[numPoints]=newPoint;
			//NSLog(@"point  %i, %f, %f",numPoints,normPoints[numPoints].x,normPoints[numPoints].y);
			
			numPoints++;
			
			distanceCoveredSinceLastPoint = 0.0 ;
			totalDistanceCovered += hypotf((newPoint.x-last.x),(newPoint.y - last.y));
			last=newPoint;
		}
	}
	
	// add final point if necessary
	if (numPoints <= newCount)
	{
		normPoints[newCount-1]=points[oldCount-1];	
		//NSLog(@"point  32, %f, %f",normPoints[numPoints].x,normPoints[numPoints].y);
		
	}
	
	
	for (i=0;i<newCount;i++){
		points[i]=normPoints[i];	
	}
}

void ACReducePointsInPath2(NSPointPointer oldPoints,int oldCount, NSPointPointer newPoints,int newCount){
	NSPoint normPoints[newCount];
	//Clear the new stroke
	//newStroke.erase(newStroke.begin(), newStroke.end());
	float newSegmentLen = ACLengthOfPath(oldPoints,oldCount);
	if ( oldCount <= 1 || newSegmentLen <= 0.0f ) return;
	newSegmentLen /= (GESTURE_LENGTH-1);
	
	int j=0;
	int i=0;
	//CStroke::const_iterator i = oldStroke.begin();
	//Add the first point to the new stroke
	newPoints[0]=oldPoints[0];
	NSPoint startPt = oldPoints[0];  //Ends of the current segment
	NSPoint endPt = oldPoints[0];    //(begin with the empty segment)
	++i;
	
	//Distance along old stroke at the end of the current segment
	float endOldDist     = 0.0f;
	//Distance along the old stroke at the beginning of the current segment
	float startOldDist   = 0.0f;
	//Distance along new stroke
	float newDist        = 0.0f;
	//Length of the current segment (on the old stroke)
	float currSegmentLen = 0.0f;
	
	for(;;)
	{
		float excess = endOldDist - newDist;
		//we have accumulated enough length, add a point
		if ( excess >= newSegmentLen )
		{
			newDist+=newSegmentLen;
			float ratio = (newDist - startOldDist)/currSegmentLen;
			NSPoint newPt;
			newPt.x = ( endPt.x - startPt.x ) * ratio + startPt.x;
			newPt.y = ( endPt.y - startPt.y ) * ratio + startPt.y;
			//newStroke.push_back(newPt);
			newPoints[++j]=newPt;
		} else {
			if ( i >= oldCount) break; //No more data
			
			//Store the start of the current segment
			startPt = endPt;
			endPt = oldPoints[i]; //Get next point
			++i;
			float dx = endPt.x - startPt.x;
			float dy = endPt.y - startPt.y;
			
			//Start accumulated distance (along the old stroke)
			//at the beginning of the segment
			startOldDist = endOldDist;
			//Add the length of the current segment to the
			//total accumulated length
			currSegmentLen = sqrtf(dx*dx+dy*dy);
			endOldDist+=currSegmentLen;
		}
	}
	//Due to floating point errors we may miss the last
	//point of the stroke
	if ( j < GESTURE_LENGTH )
	{
		newPoints[newCount-1]=oldPoints[oldCount-1];
	}
	
}


- (NSString *)description{
	return [NSString stringWithFormat:@"%p %f,%f-%f,%f",self,points[0].x,points[0].y,points[GESTURE_LENGTH-1].x,points[GESTURE_LENGTH-1].y];	
	
}

-(void)getNormalizedPointsFromEvents:(NSArray *) events
{
	
	int i;
	
	int oldCount=[events count];
	NSPoint normPoints[MAX(oldCount,GESTURE_LENGTH)];
	
	float	minX = MAXFLOAT;
	float	minY = MAXFLOAT;
	float	maxX = -MAXFLOAT;
	float	maxY = -MAXFLOAT;
	
	for(i=0; i < oldCount;i++){
		
		normPoints[i]=[[events objectAtIndex:i]locationInWindow];
		
		// find max/min extent of the gesture
		if (normPoints[i].x > maxX) maxX = normPoints[i].x;
		if (normPoints[i].x < minX) minX = normPoints[i].x;
		if (normPoints[i].y > maxY) maxY = normPoints[i].y;
		if (normPoints[i].y < minY) minY = normPoints[i].y;
	}
	
	
	ACReducePointsInPath2(normPoints,oldCount,points,GESTURE_LENGTH);
	
	
	
	
	
	float	width, height, scale, gestureLength, segLength,
		distanceCoveredSinceLastPoint, totalDistanceCovered, ratio, distanceBetweenPoints;
	//float	x, y, x2, y2, lastx, lasty;
	
	NSMutableArray *newGesture, *normGesture;
	NSPoint p;
	
	
	// Find the amount to scale the gesture by
	size.width = maxX - minX;
	size.height = maxY - minY;
	
	center.x=(maxX+minX)/2.0;
	center.y=(maxY+minY)/2.0;
	
	
	scale = 1.0/MAX(size.width,size.height);
	// Do the scaling
	for(i = 0; i < GESTURE_LENGTH; i++) {			
		
		
		points[i].x -= center.x;
		points[i].x *= scale;
		points[i].y -= center.y;
		points[i].y *= scale;
		
		
	}
	
}

// Returns the numerator of the gesture dot product - this still has to be normalized!

-(float) dotProductWithGesture:(ACGesture *)gesture
{	
	float dotProduct = 0.0f;
	int i;
	
	//if ( [gesture1 count] != [gesture2 count] )
	//	return -1;
	
	for( i=0; i < GESTURE_LENGTH; i++)
	{
		dotProduct += (points[i].x * gesture->points[i].x) 
		+ (points[i].y * gesture->points[i].y) ;
	}
	return dotProduct;
}

- (float)dotProductWithSelf{
	if (dotProductWithSelf==0){
		dotProductWithSelf=[self dotProductWithGesture:self];
	}
	return dotProductWithSelf;
}


// generates a score that describes how close two gestures are.  1.0 is a perfect match
- (float)compareGesture:(ACGesture *)gesture
{
	float score = [self dotProductWithGesture:gesture];
	if ( score <= 0.0f ) return 0.0f;
	
	// normalize score such that 1.0 is a perfect score
	score /= sqrtf([self dotProductWithSelf] * [gesture dotProductWithSelf]);
	
	return score;
}




- (NSBezierPath *)path{
	NSBezierPath *path=[NSBezierPath bezierPath];
	[path moveToPoint:points[1]];
	int i;
	for(i=1;i<GESTURE_LENGTH;i++){
		[path lineToPoint:points[i]];
	}
	return path;
}
- (float)length{
	int i;
	float length, dx, dy;
	
	length = 0.0;
	
	// step through gesture
	for(i = 0; i < (int)GESTURE_LENGTH - 1; i++) {
		dx = points[i].x - points[i+1].x;
		dy = points[i].y - points[i+1].y;
		length += sqrtf( (dx * dx) + (dy * dy));
	}
	
	return length;
	
}

- (NSPoint)center { return center; }
- (void)setCenter:(NSPoint)newCenter
{
    center = newCenter;
}


- (NSSize)size { return size; }
- (void)setSize:(NSSize)newSize
{
    size = newSize;
}


@end
