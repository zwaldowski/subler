//
//  MetadataImportController.h
//  Subler
//
//  Created by Douglas Stebila on 2011/01/27.
//  Copyright 2011 Douglas Stebila. All rights reserved.
//

@class SBTableView;
@class MP42Metadata, MP42File;

#import "TheMovieDB.h"
#import "TheTVDB.h"
#import "ArtworkSelector.h"

@protocol MetadataSearchControllerDelegate <NSObject>

- (void)searchController:(MetadataSearchController *)controller didImportMetadata:(MP42Metadata *)metadata;

@property (nonatomic, readonly) MP42File *mp4File;

@property (readonly) NSMutableArray *languages;

@end

@interface MetadataSearchController : NSWindowController<NSTableViewDelegate, ArtworkSelectorDelegate> {
    id <MetadataSearchControllerDelegate> delegate;
    NSDictionary                 *detailBoldAttr;

    IBOutlet NSTabView           *searchMode;
    
    IBOutlet NSTextField         *movieName;
    IBOutlet NSPopUpButton       *movieLanguage;
    
    IBOutlet NSComboBox          *tvSeriesName;
    NSMutableArray               *tvSeriesNameSearchArray;
    IBOutlet NSTextField         *tvSeasonNum;
    IBOutlet NSTextField         *tvEpisodeNum;
    IBOutlet NSPopUpButton       *tvLanguage;
    
    IBOutlet NSButton            *searchButton;
    id                            currentSearcher;

    NSArray                      *resultsArray;
    IBOutlet NSTableView         *resultsTable;
    MP42Metadata                 *selectedResult;
    NSDictionary                 *selectedResultTags;
    NSArray                      *selectedResultTagsArray;
    IBOutlet SBTableView         *metadataTable;

    IBOutlet NSButton            *addButton;

    NSData                       *artworkData;

    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextField         *progressText;
    
}

#pragma mark Initialization
- (id)initWithDelegate:(id <MetadataSearchControllerDelegate>)del;
+ (NSDictionary *) parseFilename: (NSString *) filename;
+ (NSString *)langCodeFor:(NSString *)language;

#pragma mark Search input fields
- (void) updateSearchButtonVisibility;
- (void) searchForTVSeriesNameDone:(NSMutableArray *)seriesArray;

#pragma mark Search for metadata
- (IBAction) searchForResults:(id)sender;
- (void) searchForResultsDone:(NSArray *)metadataArray;

#pragma mark Load additional metadata
- (IBAction) loadAdditionalMetadata:(id)sender;
- (void) loadAdditionalMetadataDone:(MP42Metadata *)metadata;

#pragma mark Select artwork
- (void) selectArtwork;

#pragma mark Load artwork
- (void) loadArtwork;

#pragma mark Finishing up
- (void) addMetadata;
- (IBAction) closeWindow: (id) sender;

#pragma mark Miscellaneous
- (NSAttributedString *) boldString: (NSString *) string;
+ (NSString *) urlEncoded:(NSString *)s;

#pragma mark Logos
- (IBAction) loadTMDbWebsite:(id)sender;
- (IBAction) loadTVDBWebsite:(id)sender;

#pragma mark Static methods
+ (void) clearRecentSearches;
+ (void) deleteCachedMetadata;

@end