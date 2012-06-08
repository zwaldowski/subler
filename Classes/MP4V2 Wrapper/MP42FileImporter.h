//
//  MP42FileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MP42Sample.h"
#import "mp4v2.h"

@class MP42Sample;
@class MP42Metadata;
@class MP42Track;
@class MP42FileImporter;

@protocol MP42FileImporterDelegate <NSObject>

@optional

- (void)fileImporterDidLoadFile:(MP42FileImporter *)importer;

@end

@interface MP42FileImporter : NSObject {
    NSURL          *fileURL;

    NSInteger      chapterTrackId;
    MP42Metadata   *metadata;
    NSMutableArray *tracksArray;

    id <MP42FileImporterDelegate> delegate;
    BOOL           isCancelled;
}

- (id)initWithDelegate:(id <MP42FileImporterDelegate>)del andFile:(NSURL *)URL error:(NSError **)outError;

- (NSUInteger)timescaleForTrack:(MP42Track *)track;
- (NSSize)sizeForTrack:(MP42Track *)track;
- (NSData*)magicCookieForTrack:(MP42Track *)track;
- (void)setActiveTrack:(MP42Track *)track;

- (MP42SampleBuffer*)copyNextSample;
- (CGFloat)progress;
- (void)cancel;

- (BOOL)cleanUp:(MP4FileHandle) fileHandle;

@property(readwrite, retain) MP42Metadata *metadata;
@property(readonly) NSMutableArray  *tracksArray;

@end