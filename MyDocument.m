//
//  MyDocument.m
//  Subler
//
//  Created by Damiano Galassi on 29/01/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "MP4Utilities.h"
#import "MovieViewController.h"
#import "EmptyViewController.h"
#import "ChapterViewController.h"
#import "SubUtilities.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    languages = [[NSArray arrayWithObjects:  @"Unknown", @"English", @"French", @"German" , @"Italian", @"Dutch", @"Swedish" , @"Spanish" , @"Danish" , @"Portuguese", @"Norwegian", @"Hebrew", @"Japanese", @"Arabic", @"Finnish", @"Greek", @"Icelandic", @"Maltese", @"Turkish", @"Croatian", @"Chinese", @"Urdu", @"Hindi", @"Thai", @"Korean", @"Lithuanian", @"Polish", @"Hungarian", @"Estonian", @"Latvian", @"Northern Sami", @"Faroese", @"Persian", @"Russian", @"Irish", @"Albanian", nil] retain];

    [langSelection addItemsWithTitles:languages];
    [langSelection selectItemWithTitle:@"English"];
    
    MovieViewController *controller = [[MovieViewController alloc] initWithNibName:@"MovieView" bundle:nil];
    [controller setFile:mp4File];
    if (controller !=nil){
        propertyView = controller;
        [[propertyView view] setAutoresizingMask:( NSViewWidthSizable | NSViewHeightSizable )];
        [[propertyView view] setFrame:[targetView bounds]];
        [targetView addSubview: [propertyView view]];
    }
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
{
    [mp4File writeToFile];

    [self updateChangeCount:NSChangeCleared];
    [self reloadTable:self];

    if (outError != NULL) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithUnsignedInt:'M4V '], NSFileHFSTypeCode,
                                    [NSNumber numberWithUnsignedInt:0], NSFileHFSCreatorCode,
                                    nil];

    [[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:[absoluteURL path]];
    [self setFileURL:absoluteURL];
    [self setFileModificationDate:[[[NSFileManager defaultManager]  
                                    fileAttributesAtPath:[absoluteURL path] traverseLink:YES]  
                                   fileModificationDate]];

	return YES;
}

-(void) saveAndOptimize: (id)sender
{
    if ([self isDocumentEdited])
        [self saveDocument:sender];
    
    [NSApp beginSheet:savingWindow modalForWindow:documentWindow
        modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    [optBar startAnimation:sender];

    [mp4File optimize];
}

- (void) optimizeDidComplete
{
    [self reloadTable:self];
    
    [self setFileURL: [self fileURL]];
    [self setFileModificationDate:[[[NSFileManager defaultManager]  
                                    fileAttributesAtPath:[[self fileURL] path] traverseLink:YES]  
                                   fileModificationDate]];
    
    [NSApp endSheet: savingWindow];
    [savingWindow orderOut:self];

    [optBar stopAnimation:nil];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    filePath = [absoluteURL path];

    mp4File = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath andDelegate:self];

    if ( outError != NULL && !mp4File ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    [mp4File release];
    mp4File = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath andDelegate:self];

    [fileTracksTable reloadData];
    [self tableViewSelectionDidChange:nil];
    [self updateChangeCount:NSChangeCleared];

    if ( outError != NULL && !mp4File ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    SEL action = [anItem action];
    
    if (action == @selector(saveDocument:))
        if ([self isDocumentEdited])
            return YES;

    if (action == @selector(revertDocumentToSaved:))
        if ([self isDocumentEdited])
            return YES;
    
    if (action == @selector(saveAndOptimize:))
            return YES;
    
    if (action == @selector(showSubititleWindow:))
            return YES;
    
    if (action == @selector(selectChapterFile:))
        return YES;

    if (action == @selector(deleteTrack:))
        return YES;
    
    
    return NO;
}

- (BOOL)validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    if (toolbarItem == addTrackToolBar)
            return YES;

    else if (toolbarItem == deleteTrack) {
        if ([fileTracksTable selectedRow] != -1 && [NSApp isActive])
            if ([[[mp4File.tracksArray objectAtIndex:[fileTracksTable selectedRow]] format]
                    isEqualToString:@"3GPP Text"])
            {
                //[[toolbarItem view] setEnabled:NO];
                return YES;
            }
    }
    return NO;
}

// Tableview datasource methods
- (NSInteger) numberOfRowsInTableView: (NSTableView *) t
{
    if( !mp4File )
        return 0;
    
    return [mp4File tracksCount];
}

- (id) tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
             row:(NSInteger)rowIndex
{
    MP4TrackWrapper *track = [mp4File.tracksArray objectAtIndex:rowIndex];

    if (!track)
        return nil;
    
    if ([tableColumn.identifier isEqualToString:@"trackId"]) {
        if (track.Id == 0)
            return @"na";
        else
            return [NSString stringWithFormat:@"%d", track.Id];
    }

    if ([tableColumn.identifier isEqualToString:@"trackName"])
        return track.name;

    if ([tableColumn.identifier isEqualToString:@"trackInfo"])
        return track.format;

    if ([tableColumn.identifier isEqualToString:@"trackDuration"])
        return SMPTEStringFromTime(track.duration, 1000);

    if ([tableColumn.identifier isEqualToString:@"trackLanguage"])
        return track.language;

    return nil;
}

- (void) tableView: (NSTableView *) tableView 
    setObjectValue: (id) anObject 
    forTableColumn: (NSTableColumn *) tableColumn 
               row: (NSInteger) rowIndex
{
    MP4TrackWrapper *track = [mp4File.tracksArray objectAtIndex:rowIndex];
    
    if ([tableColumn.identifier isEqualToString:@"trackLanguage"]) {
        if (![track.language isEqualToString:anObject]) {
            track.language = anObject;
            track.hasChanged = YES;
            [self updateChangeCount:NSChangeDone];
        }
    }
    if ([tableColumn.identifier isEqualToString:@"trackName"]) {
        if (![track.name isEqualToString:anObject]) {
            track.name = anObject;
            track.hasChanged = YES;
            [self updateChangeCount:NSChangeDone];
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if ([propertyView view] != nil)
		[[propertyView view] removeFromSuperview];	// remove the current view
    
	if (propertyView != nil)
		[propertyView release];		// remove the current view controller

    NSInteger row = [fileTracksTable selectedRow];
    if (row == -1 )
    {
        MovieViewController *controller = [[MovieViewController alloc] initWithNibName:@"MovieView" bundle:nil];
        [controller setFile:mp4File];
        if (controller !=nil)
            propertyView = controller;
    }
    else if (row != -1 && [[[[mp4File tracksArray] objectAtIndex:row] name] isEqualToString:@"Chapter Track"])
    {
        ChapterViewController *controller = [[ChapterViewController alloc] initWithNibName:@"ChapterView" bundle:nil];
        [controller setFile:mp4File andTrack:[[mp4File tracksArray] objectAtIndex:row]];
        if (controller !=nil)
            propertyView = controller;
    }
    else
    {
        EmptyViewController *controller = [[EmptyViewController alloc] initWithNibName:@"EmptyView" bundle:nil];
        if (controller !=nil)
                propertyView = controller;
    }
    
    // embed the current view to our host view
	[targetView addSubview: [propertyView view]];
	
	// make sure we automatically resize the controller's view to the current window size
	[[propertyView view] setFrame: [targetView bounds]];
    [[propertyView view] setAutoresizingMask:( NSViewWidthSizable | NSViewHeightSizable )];
}

/* NSComboBoxCell dataSource */

- (NSInteger)numberOfItemsInComboBoxCell:(NSComboBoxCell *)comboBoxCell
{
    return [languages count];
}

- (id)comboBoxCell:(NSComboBoxCell *)comboBoxCell objectValueForItemAtIndex:(NSInteger)index {
    return [languages objectAtIndex:index];
}

- (NSUInteger)comboBoxCell:(NSComboBoxCell *)comboBoxCell indexOfItemWithStringValue:(NSString *)string {
    return [languages indexOfObject: string];
}

- (IBAction) showSubititleWindow: (id) sender;
{
    [NSApp beginSheet:addSubtitleWindow modalForWindow:documentWindow
        modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

/* Open file window */

- (IBAction) openBrowse: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    
    [panel beginSheetForDirectory: nil file: nil types: [NSArray arrayWithObject:@"srt"]
                   modalForWindow: addSubtitleWindow modalDelegate: self
                   didEndSelector: @selector( openBrowseDidEnd:returnCode:contextInfo: )
                      contextInfo: nil];                                                      
}

- (void) openBrowseDidEnd: (NSOpenPanel *) sheet returnCode: (NSInteger)
    returnCode contextInfo: (void *) contextInfo
{
    if( returnCode != NSOKButton ) {
        if ([subtitleFilePath stringValue] == nil)
            [addTrack setEnabled:NO];
        return;
    }

    [subtitleFilePath setStringValue: [sheet.filenames objectAtIndex: 0]];
    [addTrack setEnabled:YES];
}

/* Select chapter file */

- (void) addChapterTrack: (NSString *) path
{
    for (MP4TrackWrapper* previousTrack in mp4File.tracksArray)
        if([previousTrack.name isEqualToString:@"Chapter Track"])
            [mp4File.tracksArray removeObject:previousTrack];

    MP4ChapterTrackWrapper *track = [[MP4ChapterTrackWrapper alloc] init];
    track.sourcePath = path;
    track.language = [[langSelection selectedItem] title];
    track.format = @"Text";
    track.name = @"Chapter Track";
    track.hasChanged = YES;
    track.hasDataChanged = YES;
    track.muxed = NO;

    NSMutableArray * chapters = [[NSMutableArray alloc] init];
    LoadChaptersFromPath(path, chapters);
    track.chapters = chapters;
    [mp4File.tracksArray addObject:track];
    [track release];

    [fileTracksTable reloadData];

    [self updateChangeCount:NSChangeDone];
}

- (IBAction) selectChapterFile: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;

    [panel beginSheetForDirectory: nil file: nil types: [NSArray arrayWithObject:@"txt"]
                   modalForWindow: documentWindow modalDelegate: self
                   didEndSelector: @selector( selectChapterFileDidEnd:returnCode:contextInfo: )
                      contextInfo: nil];                                                      
}

- (void) selectChapterFileDidEnd: (NSOpenPanel *) sheet returnCode: (NSInteger)
returnCode contextInfo: (void *) contextInfo
{
    if (returnCode != NSOKButton)
        return;
    
    [self addChapterTrack:[sheet.filenames objectAtIndex: 0]];
}

/* Tracks methods */

- (IBAction) closeSheet: (id) sender
{
    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];
}

- (IBAction) addSubtitleTrack: (id) sender
{
    MP4SubtitleTrackWrapper *track = [[MP4SubtitleTrackWrapper alloc] init];
    track.sourcePath = [subtitleFilePath stringValue];
    track.language = [[langSelection selectedItem] title];
    track.format = @"3GPP Text";
    track.name = @"Subtitle Track";
    track.delay = [[delay stringValue] integerValue];
    track.height = [[trackHeight stringValue] integerValue];
    track.hasChanged = YES;
    track.muxed = NO;

    
    [mp4File.tracksArray addObject:track];
    [track release];

    [fileTracksTable reloadData];

    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];

    [self updateChangeCount:NSChangeDone];
}


- (void) reloadTable: (id) sender
{
    MP4FileWrapper * newFile = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath andDelegate:self];
    [mp4File autorelease];
    mp4File = newFile;
    [fileTracksTable reloadData];
    [self tableViewSelectionDidChange:nil];
}

- (IBAction) deleteTrack: (id) sender
{
    if ([fileTracksTable selectedRow] == -1)
        return;

    MP4TrackWrapper *track = [[mp4File tracksArray] objectAtIndex:[fileTracksTable selectedRow]];
    if (track.muxed)
        [[mp4File tracksToBeDeleted] addObject: track];
    [[mp4File tracksArray] removeObjectAtIndex:[fileTracksTable selectedRow]];
    [fileTracksTable reloadData];
    
    [self updateChangeCount:NSChangeDone];
}

-(void) dealloc
{
    [super dealloc];
    [propertyView release];
    [mp4File release];
    [languages release];
}

@end
