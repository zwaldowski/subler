//
//  ArtworkSelector.h
//  Subler
//
//  Created by Douglas Stebila on 2011/02/03.
//  Copyright 2011 Douglas Stebila. All rights reserved.
//

#import <Quartz/Quartz.h>

@class ArtworkSelector;

@protocol ArtworkSelectorDelegate <NSObject>

- (void)artworkSelector:(ArtworkSelector *)selector didSelect:(NSURL *)artworkURL;

@end

@interface ArtworkSelector : NSWindowController {

    id <ArtworkSelectorDelegate> delegate;
    IBOutlet IKImageBrowserView     *imageBrowser;
    IBOutlet NSSlider               *slider;
    IBOutlet NSButton               *addArtworkButton;
    IBOutlet NSButton               *loadMoreArtworkButton;
    NSMutableArray                  *imageURLsUnloaded;
    NSMutableArray                  *images;
}

#pragma mark Initialization
- (id)initWithDelegate:(id <ArtworkSelectorDelegate>)del imageURLs:(NSArray *)imageURLs;

#pragma mark Load images
- (IBAction) loadMoreArtwork:(id)sender;

#pragma mark User interface
- (IBAction) zoomSliderDidChange:(id)sender;

#pragma mark Finishing up
- (IBAction) addArtwork:(id)sender;
- (IBAction) addNoArtwork:(id)sender;

@end
