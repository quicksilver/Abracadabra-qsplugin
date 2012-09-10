/* QSActionsPrefPane */

#import <Cocoa/Cocoa.h>
@interface QSAbracadabraPrefPane : QSPreferencePane{
	IBOutlet NSPopUpButton *recognizedSoundPopUp;
	IBOutlet NSPopUpButton *rejectedSoundPopUp;
}
- (IBAction)reloadACPreferences:(id)sender;
@end
