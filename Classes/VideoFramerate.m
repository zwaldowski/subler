//
//  VideoFramerate.m
//  Subler
//
//  Created by Damiano Galassi on 01/04/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "VideoFramerate.h"
#import "MP42File.h"
#import "MP42FileImporter.h"

@implementation VideoFramerate

- (id)initWithDelegate:(id)del andFile:(NSURL *)URL
{
	if ((self = [super initWithWindowNibName:@"VideoFramerate"]))
	{        
		delegate = del;
        fileURL = URL;
    }

	return self;
}

- (void)awakeFromNib
{
    fileImporter = [MP42Utilities fileImporterForURL: fileURL delegate: delegate error: NULL];
}

- (IBAction) closeWindow: (id) sender
{
	if (delegate)
		[delegate fileImport: self didCompleteWithTracks: nil metadata: nil];
}

uint8_t H264Info(const char *filePath, uint32_t *pic_width, uint32_t *pic_height, uint8_t *profile, uint8_t *level);

- (IBAction) addTracks: (id) sender
{   
    NSMutableArray *tracks = [[NSMutableArray alloc] init];

    for (MP42Track * track in [fileImporter tracksArray]) {
        [track setId:[[framerateSelection selectedItem] tag]];
        [track setTrackImporterHelper:fileImporter];
        [tracks addObject:track];
    }
	
	if (delegate)
		[delegate fileImport: self didCompleteWithTracks: tracks metadata: nil];
	
}


@end
