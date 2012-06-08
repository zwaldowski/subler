//
//  VideoFramerate.h
//  Subler
//
//  Created by Damiano Galassi on 01/04/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileImport.h"
#import "MP42FileImporter.h"

@class MP42Metadata;

@interface VideoFramerate : NSWindowController {
    NSURL    *fileURL;
    id <MP42FileImporter> fileImporter;
    IBOutlet NSPopUpButton  *framerateSelection;

    id <FileImportDelegate> delegate;
}

- (id)initWithDelegate:(id <FileImportDelegate>)del andFile:(NSURL *)URL;
- (IBAction) closeWindow: (id) sender;
- (IBAction) addTracks: (id) sender;

@end