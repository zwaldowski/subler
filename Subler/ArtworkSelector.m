//
//  ArtworkSelector.m
//  Subler
//
//  Created by Douglas Stebila on 2011/02/03.
//  Copyright 2011 Douglas Stebila. All rights reserved.
//

#import "ArtworkSelector.h"

#pragma mark IKImageBrowserItem data source objects

@interface myImageObject : NSObject{
    NSURL *_url;
    NSString *_urlString;
}
@end

@implementation myImageObject


- (void) setURL:(NSURL *)url {
    if(_url != url){
        _url = url;
        _urlString = [url absoluteString];
    }
}

- (NSURL *) url {
    return _url;
}

- (NSString *) imageRepresentationType {
    return IKImageBrowserNSURLRepresentationType;
}

- (id)  imageRepresentation {
    return _url;
}

- (NSString *) imageUID {
    return _urlString;
}

@end

#pragma mark -

@implementation ArtworkSelector

#pragma mark Initialization

- (id)initWithDelegate:(id)del imageURLs:(NSArray *)imageURLs {
	if ((self = [super initWithWindowNibName:@"ArtworkSelector"])) {        
		delegate = del;
        imageURLsUnloaded = [[NSMutableArray alloc] initWithArray:imageURLs];
    }
    return self;
}

#pragma mark Load images

- (void)awakeFromNib {
    images = [[NSMutableArray alloc] initWithCapacity:[imageURLsUnloaded count]];
    myImageObject *m;
    for (int i = 0; (i < 10) && ([imageURLsUnloaded count] > 0); i++) {
        m = [[myImageObject alloc] init];
        [m setURL:[imageURLsUnloaded objectAtIndex:0]];
        [imageURLsUnloaded removeObjectAtIndex:0];
        [images addObject:m];
    }
    [loadMoreArtworkButton setEnabled:([imageURLsUnloaded count] > 0)];
    [imageBrowser reloadData];
    [imageBrowser setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (IBAction) loadMoreArtwork:(id)sender {
    myImageObject *m;
    for (int i = 0; (i < 10) && ([imageURLsUnloaded count] > 0); i++) {
        m = [[myImageObject alloc] init];
        [m setURL:[imageURLsUnloaded objectAtIndex:0]];
        [imageURLsUnloaded removeObjectAtIndex:0];
        [images addObject:m];
    }
    [loadMoreArtworkButton setEnabled:([imageURLsUnloaded count] > 0)];
    [imageBrowser reloadData];
}

#pragma mark User interface

- (IBAction) zoomSliderDidChange:(id)sender {
    [imageBrowser setZoomValue:[slider floatValue]];
    [imageBrowser setNeedsDisplay:YES];
}

#pragma mark Finishing up

- (IBAction) addArtwork:(id)sender {
	NSURL *u = [[images objectAtIndex:[[imageBrowser selectionIndexes] firstIndex]] url];
	[delegate artworkSelector: self didSelect: u];
}

- (IBAction) addNoArtwork:(id)sender {
	[delegate artworkSelector: self didSelect: nil];

}


#pragma mark -
#pragma mark IKImageBrowserDataSource

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
    return [images count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
    return [images objectAtIndex:index];
}

#pragma mark -
#pragma mark IKImageBrowserDelegate

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index {
    [self addArtwork:nil];
}

- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) aBrowser {
    if ([[aBrowser selectionIndexes] count]) {
        [addArtworkButton setEnabled:YES];
    } else {
        [addArtworkButton setEnabled:NO];
    }
}

@end
