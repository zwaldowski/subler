//
//  SBQueueController.m
//  Subler
//
//  Created by Damiano Galassi on 12/08/11.
//  Copyright 2011 Damiano Galassi. All rights reserved.
//

#import "SBQueueController.h"
#import "SBQueueItem.h"
#import "MP42File.h"
#import "MP42FileImporter.h"
#import "MetadataSearchController.h"

#define SublerBatchTableViewDataType @"SublerBatchTableViewDataType"

static SBQueueController *sharedController = nil;

@implementation SBQueueController

@synthesize status;

+ (SBQueueController*)sharedController
{
    if (sharedController == nil) {
        sharedController = [[super allocWithZone:NULL] init];
    }
    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedController] retain];
}

- (id)init
{
    self = [super initWithWindowNibName:@"Batch"];
    if (self) {
        filesArray = [[NSMutableArray alloc] init];
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (void)awakeFromNib
{
    [spinningIndicator setHidden:YES];
    [countLabel setStringValue:@"Empty"];
    
    NSRect frame = [[self window] frame];
    frame.size.height -= 54;
    frame.origin.y += 54;
    
    [tableScrollView setAutoresizingMask:NSViewNotSizable | NSViewMinYMargin];
    [optionsBox setAutoresizingMask:NSViewNotSizable | NSViewMinYMargin];
    
    [[self window] setFrame:frame display:YES animate:NO];
    
    [tableScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [optionsBox setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [tableView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, SublerBatchTableViewDataType, nil]];
}

- (void)updateDockTile
{
    NSInteger count = 0;
    for (SBQueueItem *item in filesArray)
        if ([item status] != SBQueueItemStatusCompleted)
            count++;

    if (count)
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", count]];
    else
        [[NSApp dockTile] setBadgeLabel:nil];
}

- (void)updateUI
{
    [tableView reloadData];
    if (status != SBBatchStatusWorking) {
        [countLabel setStringValue:[NSString stringWithFormat:@"%ld files in queue.", [filesArray count]]];
        [self updateDockTile];
    }
}

- (void)addItem:(SBQueueItem*)item
{
    [filesArray addObject:item];

    [self updateUI];

    if ([AutoStartOption state])
        [self start:self];
}

- (NSArray*)loadSubtitles:(NSURL*)url
{
    NSError *outError;
    NSMutableArray *tracksArray = [[NSMutableArray alloc] init];
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[url URLByDeletingLastPathComponent] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants error:nil];

    for (NSURL *dirUrl in directory) {
        if ([[dirUrl pathExtension] isEqualToString:@"srt"]) {
            NSComparisonResult result;
            NSString *movieFilename = [[url URLByDeletingPathExtension] lastPathComponent];
            NSString *subtitleFilename = [[dirUrl URLByDeletingPathExtension] lastPathComponent];
            NSRange range = { 0, [movieFilename length] };

            result = [subtitleFilename compare:movieFilename options:kCFCompareCaseInsensitive range:range];

            if (result == NSOrderedSame) {
                MP42FileImporter *fileImporter = [[MP42FileImporter alloc] initWithDelegate:nil
                                                                                    andFile:dirUrl
                                                                                      error:&outError];

                for (MP42Track *track in [fileImporter tracksArray]) {
                    [track setTrackImporterHelper:fileImporter];
                    [tracksArray addObject:track];                    
                }
                [fileImporter release];
            }
        }
    }

    return [tracksArray autorelease];
}

- (NSImage*)loadArtwork:(NSURL*)url
{
    NSData *artworkData = [NSData dataWithContentsOfURL:url];
    if (artworkData && [artworkData length]) {
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:artworkData];
        if (imageRep != nil) {
            NSImage *artwork = [[NSImage alloc] initWithSize:[imageRep size]];
            [artwork addRepresentation:imageRep];
            return [artwork autorelease];
        }
    }

    return nil;
}

- (MP42Metadata *)searchMetadataForFile:(NSURL*) url
{
    id  currentSearcher = nil;
    MP42Metadata *metadata = nil;
    // Parse FileName and search for metadata
    NSDictionary *parsed = [MetadataSearchController parseFilename:[url lastPathComponent]];
    if ([@"movie" isEqualToString:(NSString *) [parsed valueForKey:@"type"]]) {
        currentSearcher = [[TheMovieDB alloc] init];
        NSArray *results = [((TheMovieDB *) currentSearcher) searchForResults:[parsed valueForKey:@"title"]
                                            mMovieLanguage:[MetadataSearchController langCodeFor:@"English"]];
        if ([results count])
            metadata = [((TheMovieDB *) currentSearcher) loadAdditionalMetadata:[results objectAtIndex:0] mMovieLanguage:@"English"];

    } else if ([@"tv" isEqualToString:(NSString *) [parsed valueForKey:@"type"]]) {
        currentSearcher = [[TheTVDB alloc] init];
        NSArray *results = [((TheTVDB *) currentSearcher) searchForResults:[parsed valueForKey:@"seriesName"]
                                         seriesLanguage:[MetadataSearchController langCodeFor:@"English"] 
                                              seasonNum:[parsed valueForKey:@"seasonNum"]
                                             episodeNum:[parsed valueForKey:@"episodeNum"]];
        if ([results count])
            metadata = [results objectAtIndex:0];
    }

    if (metadata.artworkThumbURLs && [metadata.artworkThumbURLs count]) {
        [metadata setArtwork:[self loadArtwork:[metadata.artworkFullsizeURLs lastObject]]];
    }

    [currentSearcher release];
    return metadata;
}

- (MP42File*)prepareQueueItem:(NSURL*)url error:(NSError**)outError {
    NSString *type;
    MP42File *mp4File = nil;

    [url getResourceValue:&type forKey:NSURLTypeIdentifierKey error:outError];

    if ([type isEqualToString:@"com.apple.m4a-audio"] || [type isEqualToString:@"com.apple.m4v-video"] || [type isEqualToString:@"public.mpeg-4"]) {
        mp4File = [[MP42File alloc] initWithExistingFile:url andDelegate:self];
    }
    else {
        mp4File = [[MP42File alloc] initWithDelegate:self];
        MP42FileImporter *fileImporter = [[MP42FileImporter alloc] initWithDelegate:nil
                                                                            andFile:url
                                                                              error:outError];

        for (MP42Track *track in [fileImporter tracksArray]) {
            if ([track.format isEqualToString:@"AC-3"] && [[[NSUserDefaults standardUserDefaults] valueForKey:@"SBAudioConvertAC3"] integerValue])
                track.needConversion = YES;

            [track setTrackImporterHelper:fileImporter];
            [mp4File addTrack:track];
        }
        [fileImporter release];
    }

    // Search for external subtitles files
    NSArray *subtitles = [self loadSubtitles:url];
    for (MP42SubtitleTrack *subTrack in subtitles)
        [mp4File addTrack:subTrack];

    // Search for metadata
    if ([MetadataOption state]) {
        MP42Metadata *metadata = [self searchMetadataForFile:url];

        for (MP42Track *track in mp4File.tracks)
            if ([track isKindOfClass:[MP42VideoTrack class]]) {
                uint64_t tw = (uint64_t) [((MP42VideoTrack *) track) trackWidth];
                uint64_t th = (uint64_t) [((MP42VideoTrack *) track) trackHeight];
                if ((tw >= 1024) && (th >= 720))
                    [metadata setTag:@"YES" forKey:@"HD Video"];
            }

        [[mp4File metadata] mergeMetadata:metadata];
    }

    return [mp4File autorelease];
}

- (SBQueueItem*)firstItemInQueue
{
    for (SBQueueItem *item in filesArray)
        if ([item status] != SBQueueItemStatusCompleted)
            return item;
    return nil;
}

- (void)start:(id)sender
{
    if (status == SBBatchStatusWorking)
        return;

    status = SBBatchStatusWorking;

    [start setTitle:@"Stop"];
    [countLabel setStringValue:@"Working."];
    [spinningIndicator setHidden:NO];
    [spinningIndicator startAnimation:self];
    [open setEnabled:NO];

    NSMutableDictionary * attributes = [[NSMutableDictionary alloc] init];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"chaptersPreviewTrack"] integerValue])
        [attributes setObject:[NSNumber numberWithBool:YES] forKey:MP42CreateChaptersPreviewTrack];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *outError = nil;
        BOOL success = NO;
        for (;;) {
            SBQueueItem *item = [self firstItemInQueue];
            if (item == nil)
                break;

            NSURL * url = [item URL];
            MP42File *mp4File = [[item mp4File] retain];
            [mp4File setDelegate:self];

            [item setStatus:SBQueueItemStatusWorking];

            // Update the UI
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger itemIndex = [filesArray indexOfObject:item];
                [countLabel setStringValue:[NSString stringWithFormat:@"Processing file %ld of %ld.",itemIndex + 1, [filesArray count]]];
                [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", [filesArray count] - itemIndex]];
                [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            });

            // The file has been added directly to the queue
            if (!mp4File && url) {
                mp4File = [[self prepareQueueItem:url error:&outError] retain];
            }

            // We have an existing mp4 file
            if ([mp4File hasFileRepresentation])
                success = [mp4File updateMP4FileWithAttributes:attributes error:&outError];
            else if (mp4File) {
                // Write the file to disk
                NSURL *newURL = [[url URLByDeletingPathExtension] URLByAppendingPathExtension:@"mp4"];
                if (newURL)
                    [attributes addEntriesFromDictionary:[item attributes]];
                    success = [mp4File writeToUrl:newURL
                                   withAttributes:attributes
                                            error:&outError];
            }

            if (success) {
                if ([OptimizeOption state])
                    [mp4File optimize];
                [item setStatus:SBQueueItemStatusCompleted];
            }
            else {
                [item setStatus:SBQueueItemStatusFailed];
                if (outError)
                    NSLog(@"Error: %@", [outError localizedDescription]);
            }

            [mp4File release];

            // Update the UI
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger itemIndex = [filesArray indexOfObject:item];
                [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [countLabel setStringValue:@"Done."];
            [spinningIndicator setHidden:YES];
            [spinningIndicator stopAnimation:self];
            [start setTitle:@"Start"];
            [open setEnabled:YES];

            status = SBBatchStatusCompleted;

            [self updateDockTile];
        });
    });

    [attributes release];
}

- (void)stop:(id)sender
{

}

- (IBAction)toggleStartStop:(id)sender
{
    if (status == SBBatchStatusWorking) {
        [self stop:sender];
    }
    else {
        [self start:sender];
    }
}

- (IBAction)toggleOptions:(id)sender
{
    NSInteger value = 0;
    if (optionsStatus) {
        value = -54;
        optionsStatus = NO;
    }
    else {
        value = 54;
        optionsStatus = YES;
    }

    NSRect frame = [[self window] frame];
    frame.size.height += value;
    frame.origin.y -= value;

    [tableScrollView setAutoresizingMask:NSViewNotSizable | NSViewMinYMargin];
    [optionsBox setAutoresizingMask:NSViewNotSizable | NSViewMinYMargin];

    [[self window] setFrame:frame display:YES animate:YES];

    [tableScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [optionsBox setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
}

- (IBAction)open:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = YES;
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"mp4", @"m4v", @"m4a", @"mov",
                                @"aac", @"h264", @"264", @"ac3",
                                @"txt", @"srt", @"smi", @"scc", @"mkv", nil]];

    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *url in [panel URLs]) {
                [filesArray addObject:[SBQueueItem itemWithURL:url]];
            }
            [self updateUI];
            
            if ([AutoStartOption state])
                [self start:self];
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [filesArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"nameColumn"])
        return [[[filesArray objectAtIndex:rowIndex] URL] lastPathComponent];

    if ([aTableColumn.identifier isEqualToString:@"statusColumn"]) {
        SBQueueItemStatus batchStatus = [[filesArray objectAtIndex:rowIndex] status];
        if (batchStatus == SBQueueItemStatusCompleted)
            return [NSImage imageNamed:@"EncodeComplete"];
        else if (batchStatus == SBQueueItemStatusWorking)
            return [NSImage imageNamed:@"EncodeWorking"];
        else if (batchStatus == SBQueueItemStatusFailed)
            return [NSImage imageNamed:@"EncodeCanceled"];
        else
            return [NSImage imageNamed:NSImageNameFollowLinkFreestandingTemplate];
    }

    return nil;
}

- (void)_deleteSelectionFromTableView:(NSTableView *)aTableView
{
    NSIndexSet *rowIndexes = [aTableView selectedRowIndexes];
    NSUInteger selectedIndex = [rowIndexes lastIndex];

    if ([NSTableView instancesRespondToSelector:@selector(beginUpdates)]) {
        #if __MAC_OS_X_VERSION_MAX_ALLOWED > 1060
        [aTableView beginUpdates];
        [aTableView removeRowsAtIndexes:rowIndexes withAnimation:NSTableViewAnimationEffectFade];
        [aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
        [filesArray removeObjectsAtIndexes:rowIndexes];
        [aTableView endUpdates];
        #endif
    }
    else {
        [filesArray removeObjectsAtIndexes:rowIndexes];
        [aTableView reloadData];
        [aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
    }

    if (status != SBBatchStatusWorking) {
        [countLabel setStringValue:[NSString stringWithFormat:@"%ld files in queue.", [filesArray count]]];
        [self updateDockTile];
    }
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:SublerBatchTableViewDataType] owner:self];
    [pboard setData:data forType:SublerBatchTableViewDataType];
    return YES;
}

- (NSDragOperation) tableView: (NSTableView *) view
                 validateDrop: (id <NSDraggingInfo>) info
                  proposedRow: (NSInteger) row
        proposedDropOperation: (NSTableViewDropOperation) operation
{
    if (nil == [info draggingSource]) { // From other application
        [view setDropRow: row dropOperation: NSTableViewDropAbove];
        return NSDragOperationCopy;
    }
    else if (view == [info draggingSource] && operation == NSTableViewDropAbove) { // From self
        return NSDragOperationEvery;
    }
    else { // From other documents 
        [view setDropRow: row dropOperation: NSTableViewDropAbove];
        return NSDragOperationCopy;
    }
}

- (BOOL) tableView: (NSTableView *) view
        acceptDrop: (id <NSDraggingInfo>) info
               row: (NSInteger) row
     dropOperation: (NSTableViewDropOperation) operation
{
    NSPasteboard *pboard = [info draggingPasteboard];

    if (tableView == [info draggingSource]) { // From self
        NSData* rowData = [pboard dataForType:SublerBatchTableViewDataType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        NSInteger dragRow = [rowIndexes firstIndex];

        id object = [[filesArray objectAtIndex:dragRow] retain];

        [filesArray removeObjectAtIndex:dragRow];
        if (row > [filesArray count] || row > dragRow)
            row--;
        [filesArray insertObject:object atIndex:row];
        [object release];
        [view reloadData];

        return YES;
    }
    else { // From other documents
        if ( [[pboard types] containsObject:NSURLPboardType] ) {
            NSArray * items = [pboard readObjectsForClasses:
                               [NSArray arrayWithObject: [NSURL class]] options: nil];
            for (NSURL * url in items)
                [filesArray insertObject:[SBQueueItem itemWithURL:url] atIndex:row];

            [self updateUI];

            if ([AutoStartOption state])
                [self start:self];

            return YES;
        }
        
    }

    return NO;
}

@end
