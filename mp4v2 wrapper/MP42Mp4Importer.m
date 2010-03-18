//
//  MP42MkvFileImporter.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MP42Mp4Importer.h"
#import "lang.h"
#import "MP42File.h"

@implementation MP42Mp4Importer

- (id)initWithDelegate:(id)del andFile:(NSString *)fileUrl
{
    if (self = [super init]) {
        delegate = del;
        file = [fileUrl retain];

        MP42File *sourceFile = [[MP42File alloc] initWithExistingFile:fileUrl andDelegate:self];

        tracksArray = [[sourceFile tracks] retain];
        
        for (MP42Track* track in tracksArray)
            track.sourceInputType = MP42SourceTypeMP4;

        [sourceFile release];
    }

    return self;
}

- (void) dealloc
{
	[file release];
    [tracksArray release];

    [super dealloc];
}

@end
