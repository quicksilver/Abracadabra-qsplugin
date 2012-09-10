
#import "DDGLView.h"
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>


static GLfloat colors[ 12 ][ 3 ] =   // Rainbow of colors
{
{  1.0f, 0.5f, 0.5f }, { 1.0f, 0.75f, 0.5f }, { 1.0f, 1.0f,  0.5f },
{ 0.75f, 1.0f, 0.5f }, { 0.5f,  1.0f, 0.5f }, { 0.5f, 1.0f, 0.75f },
{  0.5f, 1.0f, 1.0f }, { 0.5f, 0.75f, 1.0f }, { 0.5f, 0.5f,  1.0f },
{ 0.75f, 0.5f, 1.0f }, { 1.0f,  0.5f, 1.0f }, { 1.0f, 0.5f, 0.75f }
};


@implementation DDParticle
- (id) init {
	self = [super init];
	if (self != nil) {
		life=0.5f+RAND1;
		r=0.5f;
		g=0.5f;
		b=0.5f;
		
		zr=360.0f*RAND1;
		zrv=180.0f*(-0.5+RAND1);
		xv=20.0f*(-0.5+RAND1);
		//xv=20.0f*(-0.5+RAND1);
		//yv=100.0f*(-0.5+RAND1);
		birth=[NSDate timeIntervalSinceReferenceDate];
	}
	return self;
}
- (void)setPoint:(NSPoint)p{
	x=p.x;
	y=p.y;	
}
- (void)randomizeColor{
	r=RAND1;
	g=RAND1;
	b=RAND1;
}
- (void)setColor:(NSColor *)color{
	color=[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	r=[color redComponent];
	g=[color greenComponent];
	b=[color blueComponent];
	
}
@end
@implementation DDGLView



- (id)initWithFrame:(NSRect)theFrame{
	
	NSOpenGLPixelFormatAttribute attribsNice[] = 
    {NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFANoRecovery,
        kCGLPFASampleBuffers, 1, kCGLPFASamples, 2,
        0};
    
    NSOpenGLPixelFormatAttribute attribsJaggy[] = 
    {NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFANoRecovery,
		NSOpenGLPFAMPSafe,
        0};
    
    NSOpenGLPixelFormat *fmt;
    
    /* Choose a pixel format */
    fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribsJaggy];
    
    /* Create a GL context */
    self = [super initWithFrame:theFrame pixelFormat:fmt];
    
    /* Destroy the pixel format */
    [fmt release];
	
	if(self) {   
		
		array=[[NSMutableArray alloc]init];
		[self initGL];
	}
	return self;
}

- (void) timerUpdate
{
	
	
	[[self openGLContext] makeCurrentContext];
	[self drawGLScene];
	[NSOpenGLContext clearCurrentContext];
	
}

- (void)initGL{
	
	
	int opaque=0;
	[[self openGLContext] setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];	
	//long order=-1;
	//[[self openGLContext] setValues:&opaque forParameter:NSOpenGLCPSurfaceOrder];	
	
	
	[self setImage:	[NSImage imageNamed:@"Sparkle"]];
	
}
- (BOOL)isOpaque
{
	return NO;   
}

- (void)addParticle:(DDParticle *)particle{
	if (![array count]){
		[delegate sparkleStarted];	
	}
	
	[array addObject:particle];
	
	if (![timer isValid]){
		[timer release];	
		      timer=[[NSTimer scheduledTimerWithTimeInterval:1.0f/15.0f target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES] retain];
	}
	[self setNeedsDisplay:YES];
	
}

- (void)addParticleAtPoint:(NSPoint)point{
	DDParticle *particle=[[[DDParticle alloc]init]autorelease];	
	[particle setPoint:point];
	[self addParticle:particle];
}

- (void)clearContent
{
	[[NSColor colorWithCalibratedRed: 0.00 green: 0.00 blue: 0.0 alpha:0.0] set];
	NSRectFill([self bounds]);
}

- (void)drawRect:(NSRect)theRect{
	NSRect bounds = [self bounds];
    [[NSColor clearColor] set];
    NSRectFill(bounds);
	[self drawGLScene];
}

- (void)drawGLScene{
	if (![array count]){
		[timer invalidate];
		[delegate sparkleStopped];
	}
	
	[[self openGLContext] makeCurrentContext];
	
    NSRect visibleRect;
    // Get visible bounds...
    visibleRect = [self bounds];
	glClearColor(0.0f,0.0f,0.0f,0.00f);
	
    // Set proper viewport
    glViewport(visibleRect.origin.x, visibleRect.origin.y, visibleRect.size.width, visibleRect.size.height);
    
    // Clear background to transparent black.
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    /* Our screen coordinates */
    gluOrtho2D(0,NSWidth([self frame]),NSHeight([self frame]),0);
    
    // Back off from object position
    glTranslatef(0.0f,0.0f,-1.0f);
	
	// Flip to match screen coords
	glTranslatef(0,NSHeight([self frame]),0);
	glScalef(1.0f,-1.0f,1.0f);
    
    glEnable(GL_BLEND);
	glDepthMask(GL_FALSE );
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	
	
	
	
	
	glBindTexture(GL_TEXTURE_2D, (int)1);
	
	int i;
	// NSEnumerator *e=[array objectEnumerator];
	DDParticle *p;
	// while(value=[e nextObject]){
	NSTimeInterval t=[NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval dt=t-lastTime;
	NSSize size=[[self image]size];//[drawImage size]
		for (i=[array count]-1;i>=0;i--)  {
			p=[array objectAtIndex:i];
			float age=t - p->birth;
			int seed=(int)p;
		//	NSLog(@"%f %f %f",p->x,p->y,age);
		
			if (age > p->life){
				[array removeObjectAtIndex:i];
			continue;
			}
			float offset=(float)rand()/INT_MAX/6; 
			
			glPushMatrix();
			p->yv-=64.0*dt;
			p->x+=p->xv*dt;
			p->y+=p->yv*dt;
			
			//p->zv+=1.0*dt;
			p->z+=p->zv*dt;
			p->zr+=p->zrv*dt;
			glTranslatef(p->x,p->y,0);
			
//			glTranslatef(3*sin(seed+age*2),-pow(age,4.0)*40*(7+(seed%6))/7,0);
			glTranslatef(5.0*sin(seed+age*M_PI),0,0.3);
			glTranslatef(2,-8,0);
	
			glRotatef(p->zr,0.0f,0.0,-1.0f);
			float scale=0.5f+(float)(seed%6)/16.0;
			scale-=0.25*(age/p->life);
			//scale+=p->z;
			//NSLog(@"scal %f",scale);
			glScalef(scale,scale,scale);
			
			float r=1.0-0.2*sin(age*M_PI);
			float g=1.0-0.2*sin(age*M_PI);
			float b=1.0-0.2*sin(age*M_PI);
			float a=1-age+0.1*sin(seed+age*20);
			float l=0.3f*sin(seed+age*M_PI*3)-0.05;
			r=p->r+l;
			g=p->g+l;
			b=p->b+l;
			a=1.0 - age/p->life;
			glColor4f(r,g,b,a);
			//glColor4f( 0.0f,0.0f,1.0f,0.5f );
			
			glBegin(GL_QUADS);
			glNormal3f(0.0f,0.0f,1.0f);
			glTexCoord2f(1.0f,0.0f);
			glVertex3f(size.width/2,-size.height/2,0);
			glTexCoord2f(1.0f,1.0f);
			glVertex3f(size.width/2,size.height/2,0);
			glTexCoord2f(0.0f,1.0f);
			glVertex3f(-size.width/2,size.height/2,0);
			glTexCoord2f(0.0f,0.0f);
			glVertex3f(-size.width/2,-size.height/2,0);
			glEnd();
			
			glPopMatrix();
		}
		
		lastTime=t;
		
		
		glDepthMask(GL_TRUE); 
		// glDisable(GL_BLEND); 
		
		[[self openGLContext] flushBuffer];
		
		
		
		
	}


- (NSImage *)image { return [[image retain] autorelease]; }
- (void)setImage:(NSImage *)newImage{
	
	glBindTexture(GL_TEXTURE_2D, (int)1);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,  GL_MODULATE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	
	gluBuild2DMipmaps(GL_TEXTURE_2D, 4, [newImage size].width, [newImage size].height, GL_RGBA, GL_UNSIGNED_BYTE, [[newImage bestRepresentationForDevice:nil] bitmapData]);
	
	
    [image autorelease];
    image = [newImage retain];
	
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
