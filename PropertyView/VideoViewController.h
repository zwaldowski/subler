//
//  PropertyViewController.h
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MP42File;
@class MP42VideoTrack;
@class MP42SubtitleTrack;

@interface VideoViewController : NSViewController {
    MP42VideoTrack *track;
    MP42File       *mp4file;

    IBOutlet NSTextField *sampleWidth;
    IBOutlet NSTextField *sampleHeight;

    IBOutlet NSTextField *trackWidth;
    IBOutlet NSTextField *trackHeight;

    IBOutlet NSTextField *hSpacing;
    IBOutlet NSTextField *vSpacing;

    IBOutlet NSTextField *offsetX;
    IBOutlet NSTextField *offsetY;

    IBOutlet NSPopUpButton *alternateGroup;

    IBOutlet NSPopUpButton *videoProfile;
    IBOutlet NSTextField *videoProfileLabel;
    IBOutlet NSTextField *videoProfileDescription;

    IBOutlet NSPopUpButton *forcedSubs;
    IBOutlet NSTextField *forcedSubsLabel;

    IBOutlet NSPopUpButton *forced;
    IBOutlet NSTextField *forcedLabel;

    IBOutlet NSButton *preserveAspectRatio;
    
    IBOutlet NSMenuItem *profileLevelUnchanged;
}

- (void) setTrack:(MP42VideoTrack *) videoTrack;
- (void) setFile:(MP42File *) mp4;

- (IBAction) setSize: (id) sender;
- (IBAction) setPixelAspect: (id) sender;
- (IBAction) setAltenateGroup: (id) sender;

- (IBAction) setProfileLevel: (id) sender;

- (IBAction) setForcedSubtitles: (id) sender;
- (IBAction) setForcedTrack: (id) sender;

@end
