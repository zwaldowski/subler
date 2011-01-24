//
//  SBDocument.h
//  Subler
//
//  Created by Damiano Galassi on 29/01/09.
//  Copyright Damiano Galassi 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MP42File;

@interface SBDocument : NSDocument
{
    MP42File  *mp4File;
    IBOutlet NSWindow       *documentWindow;

    IBOutlet NSTableView    *fileTracksTable;
    IBOutlet NSSplitView    *splitView;

    IBOutlet NSWindow       *savingWindow;
    IBOutlet NSTextField    *saveOperationName;

    NSSavePanel                     *_currentSavePanel;
    IBOutlet NSView                 *saveView;
    IBOutlet NSPopUpButton          *fileFormat;
    IBOutlet NSProgressIndicator    *optBar;

    IBOutlet NSToolbarItem  *addTracks;
    IBOutlet NSToolbarItem  *deleteTrack;
    IBOutlet NSToolbarItem  *searchMetadata;

    NSMutableArray          *languages;

    NSViewController        *propertyView;
    IBOutlet NSView         *targetView;
    id                      importWindow;

    IBOutlet NSWindow       *offsetWindow;
    IBOutlet NSTextField    *offset;

    IBOutlet NSButton *cancelSave;
    IBOutlet NSButton *_64bit_data;
    IBOutlet NSButton *_64bit_time;
    BOOL _optimize;
}

- (IBAction) selectFile: (id) sender;
- (IBAction) deleteTrack: (id) sender;
- (IBAction) searchMetadata: (id) sender;

- (IBAction) showTrackOffsetSheet: (id) sender;
- (IBAction) setTrackOffset: (id) sender;
- (IBAction) closeOffsetSheet: (id) sender;

- (IBAction) setSaveFormat: (id) sender;
- (IBAction) cancelSaveOperation: (id) sender;
- (IBAction) sendToExternalApp: (id) sender;

- (IBAction) saveAndOptimize: (id)sender;

- (IBAction) selectMetadataFile: (id) sender;
- (IBAction) addChaptersEvery: (id) sender;

- (IBAction) export: (id) sender;

- (void) showImportSheet: (NSString *) filePath;

- (MP42File *) mp4File;

@end
