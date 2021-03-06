//
//  PropertyViewController.m
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "SoundViewController.h"
#import "MP42File.h"

@implementation SoundViewController

- (void) awakeFromNib
{
    [alternateGroup selectItemAtIndex:track.alternate_group];

    if ([[track format] isEqualToString:@"AC-3"]) {
        for (id fileTrack in [mp4file tracks]) {
            if ([fileTrack isMemberOfClass:[MP42AudioTrack class]] && [[fileTrack format] isEqualToString:@"AAC"]) {
                NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Track %d", [fileTrack Id]]
                                                                  action:@selector(setFallbackTrack:)
                                                           keyEquivalent:@""];
                [newItem setTarget:self];
                [newItem setTag: [fileTrack Id]];
                [[fallback menu] addItem:newItem];
            }
        }

        [fallback selectItemWithTag:track.fallbackTrackId];
    }
    else {
        [fallback setEnabled:NO];
    }
    
    for (id fileTrack in [mp4file tracks]) {
        if ([fileTrack isMemberOfClass:[MP42SubtitleTrack class]]) {
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Track %d", [fileTrack Id]]
                                                              action:@selector(setFollowsTrack:)
                                                       keyEquivalent:@""];
            [newItem setTarget:self];
            [newItem setTag: [fileTrack Id]];
            [[follows menu] addItem:newItem];
        }
    }

    [follows selectItemWithTag:track.followsTrackId];

    [volume setFloatValue:track.volume * 100];
}

- (void) setFile:(MP42File *) mp4
{
    mp4file = mp4;
}

- (void) setTrack:(MP42AudioTrack *) soundTrack
{
    track = soundTrack;
}

- (IBAction) setTrackVolume: (id) sender
{
    float value = [sender doubleValue] / 100;
    if (track.volume != value) {
        track.volume = value;
        [[[[[self view]window] windowController] document] updateChangeCount:NSChangeDone];
    }
}

- (IBAction) setFallbackTrack: (id) sender
{
    uint8_t tagName = [sender tag];

    if (track.fallbackTrackId != tagName) {
        track.fallbackTrackId = tagName;
        [[[[[self view]window] windowController] document] updateChangeCount:NSChangeDone];
    }    
}

- (IBAction) setFollowsTrack: (id) sender
{
    uint8_t tagName = [sender tag];
    
    if (track.followsTrackId != tagName) {
        track.followsTrackId = tagName;
        [[[[[self view]window] windowController] document] updateChangeCount:NSChangeDone];
    }
}

- (IBAction) setAltenateGroup: (id) sender
{
    uint8_t tagName = [[sender selectedItem] tag];
    
    if (track.alternate_group != tagName) {
        track.alternate_group = tagName;
        [[[[[self view]window] windowController] document] updateChangeCount:NSChangeDone];
    }
}

@end
