//
//  FileImport.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MP42FileImporter.h"

@class MP42Metadata;
@class FileImport;

@protocol FileImportDelegate <NSObject, MP42FileImporterDelegate>

- (void)fileImport:(NSWindowController *)import didCompleteWithTracks:(NSArray *)tracksToBeImported metadata:(MP42Metadata*)metadata;

@end

@interface FileImport : NSWindowController <NSTableViewDelegate> {

	NSURL               * fileURL;
    NSMutableArray		* importCheckArray;
    NSMutableArray      * actionArray;
    id <MP42FileImporter> fileImporter;

	id <FileImportDelegate> delegate;
	IBOutlet NSTableView * tableView;
	IBOutlet NSButton    * addTracksButton;
    IBOutlet NSButton    * importMetadata;
    IBOutlet NSProgressIndicator *loadProgressBar;
    NSTimer *loadTimer;
}

- (id)initWithDelegate:(id <FileImportDelegate>)del andFile: (NSURL *)file error:(NSError **)outError;
- (IBAction) closeWindow: (id) sender;
- (IBAction) addTracks: (id) sender;

@end