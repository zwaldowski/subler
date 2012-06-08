//
//  MP42FileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import <mp4v2/mp4v2.h>
#import "MP42Utilities.h"

@class MP42Sample;
@class MP42Metadata;
@class MP42Track;
@class MP42FileImporter;
@class MP42SampleBuffer;

@protocol MP42FileImporterDelegate <NSObject>

@optional

- (void)fileImporterDidLoadFile:(MP42FileImporter *)importer;

@end

@protocol MP42FileImporter <NSObject>

- (id <MP42FileImporter>)initWithFile:(NSURL *)URL delegate:(id <MP42FileImporterDelegate>)delegate error:(NSError **)outError;

- (NSUInteger)timescaleForTrack:(MP42Track *)track;
- (NSSize)sizeForTrack:(MP42Track *)track;
- (NSData*)magicCookieForTrack:(MP42Track *)track;
- (void)setActiveTrack:(MP42Track *)track;

- (MP42SampleBuffer*)copyNextSample;
- (CGFloat)progress;
- (void)cancel;

- (BOOL)cleanUp:(MP4FileHandle) fileHandle;

@property (nonatomic, retain) MP42Metadata *metadata;
@property (nonatomic, readonly) NSMutableArray  *tracksArray;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) id <MP42FileImporterDelegate> delegate;
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;

@end

@interface MP42Utilities (FileImporter)

+ (id <MP42FileImporter>)fileImporterForURL:(NSURL *)URL delegate:(id <MP42FileImporterDelegate>)del error:(NSError **)outError;

@end