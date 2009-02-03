//
//  MyDocument.m
//  Subler
//
//  Created by Damiano Galassi on 29/01/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "SubMuxer.h"
#import "MP4Utilities.h"
#import "lang.h"

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
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    languages = [[NSArray arrayWithObjects:  @"Unknown", @"English", @"French", @"German" , @"Italian", @"Dutch", @"Swedish" , @"Spanish" , @"Danish" , @"Portuguese", @"Norwegian", @"Hebrew", @"Japanese", @"Arabic", @"Finnish", @"Greek", @"Icelandic", @"Maltese", @"Turkish", @"Croatian", @"Traditional Chinese", @"Urdu", @"Hindi", @"Thai", @"Korean", @"Lithuanian", @"Polish", @"Hungarian", @"Estonian", @"Latvian", @"Lappish", @"Faeroese", @"Farsi", @"Russian", @"Simplified Chinese", @"Flemish", @"Irish", @"Albanian", nil] retain];

    [langSelection addItemsWithTitles:languages];
    [langSelection selectItemWithTitle:@"English"];
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
{
    MP4SubtitleTrackWrapper *track;

    for (track in mp4File.tracksToBeDeleted)
            [self deleteSubtitleTrack: track];

    for (track in mp4File.tracksArray)
    {
        if ([track.format isEqualToString:@"3GPP Text"])
            if (track.hasChanged && !track.muxed) {
                [self muxSubtitleTrack:track];
            }
        if (track.hasChanged) {
            [self updateTrackLanguage:track];
            [self updateTrackName:track];
        }
    }

    [self updateChangeCount:NSChangeCleared];
    [self reloadTable:self];
    

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
    [self setFileURL:absoluteURL];
    [self setFileModificationDate:[[[NSFileManager defaultManager]  
                                    fileAttributesAtPath:[absoluteURL path] traverseLink:YES]  
                                   fileModificationDate]];
	return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    filePath = [absoluteURL path];

    mp4File = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath];
    
    if ( outError != NULL || !mp4File ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    [mp4File release];
    mp4File = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath];
    
    [fileTracksTable reloadData];
    [self updateChangeCount:NSChangeCleared];

    if ( outError != NULL || !mp4File ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}


- (BOOL)validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    if (toolbarItem == addTrackToolBar)
            return YES;

    else if (toolbarItem == deleteTrack) {
        if ([fileTracksTable selectedRow] != -1 && [NSApp isActive])
            if ([[[mp4File.tracksArray objectAtIndex:[fileTracksTable selectedRow]] format]
                    isEqualToString:@"3GPP Text"])
                return YES;
    }
    return NO;
}

/***********************************************************************
 * Tableview datasource methods
 **********************************************************************/
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

    if(!track)
        return nil;
    
    if( [tableColumn.identifier isEqualToString:@"trackId"] )
       return [NSString stringWithFormat:@"%d", track.Id];

    if( [tableColumn.identifier isEqualToString:@"trackName"] )
    {
        return track.name;
    }

    if( [tableColumn.identifier isEqualToString:@"trackInfo"] )
        return track.format;

    if( [tableColumn.identifier isEqualToString:@"trackDuration"] )
        return [NSString stringWithFormat:@"%d:%d:%ds", (int) track.duration / 3600,
                                                        ((int)track.duration  % 3600 ) / 60,
                                                        (int) track.duration % 60];

    if( [tableColumn.identifier isEqualToString:@"trackLanguage"] )
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

/* Track methods */

- (IBAction) closeSheet: (id) sender
{
    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];
}

- (BOOL) muxSubtitleTrack: (MP4SubtitleTrackWrapper*) track
{
    MP4FileHandle fileHandle;
    iso639_lang_t *lang = lang_for_english([track.language UTF8String]);

    fileHandle = MP4Modify( [filePath UTF8String], MP4_DETAILS_ERROR, 0 );
    if (fileHandle == MP4_INVALID_FILE_HANDLE) {
        printf("Error\n");
        return NO;
    }
    
    muxSubtitleTrack(fileHandle,
                     track.sourcePath,
                     lang->iso639_2,
                     track.height,
                     track.delay
    );
    
    MP4Close(fileHandle);
    
    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];
    
    [self updateChangeCount:NSChangeDone];
    
    return YES;
}

- (BOOL) deleteSubtitleTrack: (MP4TrackWrapper *)track
{
    MP4FileHandle fileHandle;

    fileHandle = MP4Modify( [filePath UTF8String], MP4_DETAILS_ERROR, 0 );
    MP4TrackId trackId = track.Id;
    MP4DeleteTrack( fileHandle, trackId);

    updateTracksCount(fileHandle);
    enableFirstSubtitleTrack(fileHandle);

    MP4Close(fileHandle);
    
    return YES;
}

- (BOOL) updateTrackLanguage: (MP4TrackWrapper*) track
{
    MP4FileHandle fileHandle;
    iso639_lang_t *lang = lang_for_english([track.language UTF8String]);
    
    fileHandle = MP4Modify( [filePath UTF8String], MP4_DETAILS_ERROR, 0 );
    if (fileHandle == MP4_INVALID_FILE_HANDLE) {
        printf("Error\n");
        return NO;
    }
    
    MP4SetTrackLanguage(fileHandle, track.Id, lang->iso639_2);
    
    MP4Close(fileHandle);
    
    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];
    
    [self updateChangeCount:NSChangeDone];
    
    return YES;
}

- (BOOL) updateTrackName: (MP4TrackWrapper*) track
{
    MP4FileHandle fileHandle;
    
    fileHandle = MP4Modify( [filePath UTF8String], MP4_DETAILS_ERROR, 0 );
    if (fileHandle == MP4_INVALID_FILE_HANDLE) {
        printf("Error\n");
        return NO;
    }
    
    if (![track.name isEqualToString:@"Video Track"] &&
        ![track.name isEqualToString:@"Audio Track"] &&
        ![track.name isEqualToString:@"Subtitle Track"] &&
        ![track.name isEqualToString:@"Text Track"] &&
        track.name != nil) {
        if (MP4HaveTrackAtom(fileHandle, track.Id, "udta.name"))
            MP4SetTrackBytesProperty(fileHandle, track.Id,
                                     "udta.name.value",
                                     (const uint8_t*) [track.name UTF8String], strlen([track.name UTF8String]));
    }
    
    MP4Close(fileHandle);

    [NSApp endSheet: addSubtitleWindow];
    [addSubtitleWindow orderOut:self];

    [self updateChangeCount:NSChangeDone];

    return YES;
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
    [mp4File release];
    mp4File = [[MP4FileWrapper alloc] initWithExistingMP4File:filePath];
    [fileTracksTable reloadData];
}

- (IBAction) deleteTrack: (id) sender
{
    MP4TrackWrapper *track = [[mp4File tracksArray] objectAtIndex:[fileTracksTable selectedRow]];
    if (track.muxed)
        [[mp4File tracksToBeDeleted] addObject: track];
    [[mp4File tracksArray] removeObjectAtIndex:[fileTracksTable selectedRow]];
    [fileTracksTable reloadData];
}

@end
