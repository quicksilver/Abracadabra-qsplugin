//
//  ACSparkleWindowController.m
//  Abracadabra
//
//  Created by Nicholas Jitkoff on 1/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ACSparkleWindowController.h"

#import "DDGLView.h"
#import <Carbon/Carbon.h>
#import <OpenGL/OpenGL.h>
#import <AGL/agl.h>

typedef int CGSConnection;
typedef int CGSWindow;
extern CGSConnection _CGSDefaultConnection(void);

OSStatus CGSGetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);
OSStatus CGSSetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);

@implementation NSWindow (Fade)
- (void)setSticky:(BOOL)flag {
    CGSConnection cid;
    
    CGSWindow wid;
    
    wid = [self windowNumber ];
    cid = _CGSDefaultConnection();
    int tags[2];
    tags[0] = tags[1] = 0;
    OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
    if(!retVal) {
        if (flag)
            tags[0] = tags[0] | 0x00000800;
        else
            tags[0] = tags[0] & 0x00000800;
        retVal = CGSSetWindowTags(cid, wid, tags, 32);
    }
}
@end

@implementation ACSparkleWindowController

- (void)loadWindow {

	//	if (1){
	//	WindowRef window;
	//	AGLContext glContext;
	//		Rect windowSize;
	//		
	//		OSStatus err;
	//		
	//		windowSize.left=0;
	//		windowSize.right=800; // Or whatever...
	//		windowSize.top=0;
	//		windowSize.bottom=600;
	//		AGLPixelFormat aglPixFmt;
	//	CGDirectDisplayID mainDisp =  CGMainDisplayID();
	//	//resolution.h  = CGDisplayPixelsWide(mainDisp) ;
	//	//resolution.v  = CGDisplayPixelsHigh(mainDisp) ;
	//	
	//	err = CreateNewWindow(
	//							 kOverlayWindowClass,
	//							 kWindowIgnoreClicksAttribute |
	//							 kWindowStandardHandlerAttribute,
	//							 &windowSize, //desktop rect
	//							 &window); 
	//
	//	GLint attrib[] = { AGL_RGBA, AGL_ACCELERATED, AGL_DOUBLEBUFFER,AGL_NO_RECOVERY,AGL_MP_SAFE,
	//		AGL_PIXEL_SIZE,32,AGL_DEPTH_SIZE, 16, AGL_NONE };
	//
	//	
	//	aglPixFmt  = aglChoosePixelFormat(NULL, 1, attrib);
	//	glContext = aglCreateContext (aglPixFmt, NULL);
	//	aglSetCurrentContext (glContext);
	//	aglSetDrawable (glContext, drawPort);
	//	aglDestroyPixelFormat(aglPixFmt);
	//	
	//	//zero
	//	GLint Opacity = 0;
	//	aglSetInteger(glContext, AGL_SURFACE_OPACITY, &Opacity); 
	//	//If I remember well also the alpha component
	//	//of the clear color must be cleaned to 0, like:
	//	glClearColor(0,0,0,0.5); 
	//
	//	
	//	NSWindow *cocoaWindow;
	//
	//
	//	cocoaWindow=[[NSWindow alloc] initWithWindowRef:&window];
	//
	//	[self setWindow:cocoaWindow];
	//	
	//	return;
	//	
	//}
#warning tiennou: This embeds the current screen resolution, right ?
	NSWindow* result = [[NSWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame]
                                                   styleMask:NSBorderlessWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
	[result setBackgroundColor: [NSColor clearColor]];
    [result setOpaque:NO];
    [result setAlphaValue:0.999f];
    [result setShowsResizeIndicator:YES];
    [result setIgnoresMouseEvents:YES];
    [result setMovableByWindowBackground:NO];
    [result setLevel:kCGMaximumWindowLevel];
    [result setHasShadow:NO];
	[result setSticky:YES];
	DDGLView *contentView = [[[DDGLView alloc] init] autorelease];
    [result setContentView:contentView];
	[contentView setDelegate:self];
	[result setCanHide:NO];
    [self setWindow:result];
}

- (void)sparkleStarted {
	[[self window] orderFront:self];
}

- (void)sparkleStopped {
	[[self window] orderOut:self];
}
@end
