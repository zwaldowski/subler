//
//  MovieViewController.h
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MP42File.h"
#import "SBTableView.h"

@interface MovieViewController : NSViewController <SBTableViewDelegate> {
    MP42Metadata            *metadata;

    IBOutlet NSPopUpButton  *tagList;
    IBOutlet SBTableView  *tagsTableView;

    IBOutlet NSImageView    *imageView;
    IBOutlet NSPopUpButton  *mediaKind;
    IBOutlet NSPopUpButton  *contentRating;
    IBOutlet NSButton       *hdVideo;
    IBOutlet NSButton       *gapless;
    
    IBOutlet NSButton       *removeTag;
    
    NSPopUpButtonCell       *ratingCell;
    NSComboBoxCell          *genreCell;

    NSDictionary    *tags;
    NSArray         *tagsArray;
    NSArray         *tagsMenu;
    NSDictionary    *detailBoldAttr;

    NSMutableDictionary  *dct;
    NSTableColumn *tabCol;
    CGFloat width;
}

- (void) setFile: (MP42File *)file;
- (IBAction) addTag: (id) sender;
- (IBAction) removeTag: (id) sender;

- (IBAction) addMetadataSet: (id)sender;
- (IBAction) saveSet: (id)sender;

- (IBAction) updateArtwork: (id) sender;

- (IBAction) changeMediaKind: (id) sender;
- (IBAction) changecContentRating: (id) sender;
- (IBAction) changeGapless: (id) sender;
- (IBAction) changehdVideo: (id) sender;

@end