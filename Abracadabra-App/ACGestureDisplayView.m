#import "ACGestureDisplayView.h"

NSPoint ACUnitPointInFrame(NSPoint p, NSRect r) {
	p.x *= r.size.width;
	p.y *= r.size.height;
	p.x += r.origin.x;
	p.y += r.origin.y;
	return p;
}

NSPoint ACCenteredUnitPointInFrame(NSPoint p, NSRect r) {
	p.x *= r.size.width;
	p.y *= r.size.height;
	p.x += NSMidX(r);
	p.y += NSMidY(r);
	return p;
}

NSPoint ACUnitPointWithCenterAndScale(NSPoint p, NSPoint c, CGFloat scale) {
	p.x *= scale;
	p.y *= scale;
	p.x += c.x;
	p.y += c.y;
	return p;
}

void ACDrawDotAtPoint(NSPoint p,CGFloat r) {
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p.x - r, p.y - r, r * 2, r * 2)] fill];
}

@implementation ACGestureDisplayView

- (void)drawBackgroundInRect:(NSRect)rect {
	[[NSColor darkGrayColor] set];
	[NSBezierPath fillRect:rect];
	[[NSColor blackColor] set];
	NSFrameRect(rect);
}

// draws the panel
- (void)drawRect:(NSRect)rect {
	// vars
	int i;
	NSBezierPath *path;

	// Draw background recangle
	NSRect bounds = [self bounds];
	[self drawBackgroundInRect:bounds];
	CGFloat width = MAX(1.0, NSWidth(bounds) / 256);

	// walk through point array, adding line segments between points to the path
	path = [[[NSBezierPath alloc] init] autorelease];
	
	bounds = NSInsetRect(bounds, 8, 8);

	if (gesture) {
		NSPoint *points = [gesture points];
		NSPoint center = [self convertPoint:[gesture center] fromView:nil];
		NSSize size = [gesture size];
		CGFloat scale = MAX(size.width, size.height);

		[[NSColor whiteColor]set];

		// walk through points drawing red dots
		for (i = 0; i < 32; i++) {
			NSPoint p = ACCenteredUnitPointInFrame(points[i], bounds);
			if (drawToScale) {
                p = ACUnitPointWithCenterAndScale(points[i], center, scale);
			}
			if (i == 0)
                [path moveToPoint: p];
			else
                [path lineToPoint: p];
			
			ACDrawDotAtPoint(p, (i == 0 ? width * 4 : width * 2));
		}
	}
	
	// draw overall path in white
	[[NSColor whiteColor] set];
	
	[path setLineWidth:width];
	[path stroke];
}

- (ACGesture *)gesture { return [[gesture retain] autorelease]; }
- (void)setGesture:(ACGesture *)newGesture {
    if (gesture != newGesture) {
        [gesture release];
        gesture = [newGesture retain];
		[self setNeedsDisplay:YES];
    }
}

@end
