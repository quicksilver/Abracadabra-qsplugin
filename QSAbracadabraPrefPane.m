#import "QSAbracadabraPrefPane.h"

@implementation QSAbracadabraPrefPane
#define SERIALPORT @"/dev/cu.CL800BT-SerialPort-1"

- (BOOL)laserKeyAvailable{
	NSFileManager *fm=[NSFileManager defaultManager];
	return [fm fileExistsAtPath:SERIALPORT];
}
- (void)setLaserKeyAvailable:(BOOL)flag{}

- (NSString *) mainNibName{
	return @"QSAbracadabraPrefPane";
}
//- (void) mainViewDidLoad{
//
//}
- (NSArray *)sounds{
	NSFileManager *fm=[NSFileManager defaultManager];
	
	NSMutableArray *sounds=[NSMutableArray array];
	[sounds addObjectsFromArray:[fm contentsOfDirectoryAtPath:@"/System/Library/Sounds" error:nil]];
	[sounds addObjectsFromArray:[fm contentsOfDirectoryAtPath:@"/Library/Sounds" error:nil]];
	[sounds addObjectsFromArray:[fm contentsOfDirectoryAtPath:[@"~/Library/Sounds" stringByStandardizingPath] error:nil]];
    NSMutableArray *validSounds = [NSMutableArray array];
	for(NSString *uti in [NSSound soundUnfilteredTypes]) {
        NSString *soundExtensions = [(NSString *)UTTypeCopyPreferredTagWithClass((CFStringRef)uti,kUTTagClassFilenameExtension) autorelease];
        if (soundExtensions) {
        [validSounds addObjectsFromArray:[sounds pathsMatchingExtensions:[NSArray arrayWithObject:soundExtensions]]];
        }
    }
	validSounds=[[[validSounds valueForKey:@"stringByDeletingPathExtension"] mutableCopy]autorelease];

	[validSounds insertObject:@"No Sound" atIndex:0];
	
	//	NSLog(@"load %@",sounds);
//	foreach(sound,sounds){
//		[rejectedSoundPopUp	addItemWithTitle:sound];
//		[recognizedSoundPopUp addItemWithTitle:sound];
//	}
	return validSounds;
}
- (IBAction)reloadACPreferences:(id)sender{
	//NSLog(@"reload",sender);
	if (sender==rejectedSoundPopUp || sender==recognizedSoundPopUp){
		[[NSSound soundNamed:[sender title]]play];	
	}
	
	[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"com.blacktree.Abracadabra.PreferencesChanged" object:nil userInfo:nil deliverImmediately:YES];
	[[NSUserDefaults standardUserDefaults]synchronize];
}

@end