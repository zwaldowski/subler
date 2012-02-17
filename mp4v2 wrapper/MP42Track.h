//
//  MP42Track.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mp4v2.h"
@class MP42FileImporter;

@interface MP42Track : NSObject <NSCoding> {
    MP4TrackId  Id;
    MP4TrackId  sourceId;
    id          sourceFileHandle;

    NSURL       *sourceURL;
    NSString    *sourceFormat;
    NSString    *format;
    NSString    *name;
    NSString    *language;
    BOOL        enabled;
    uint64_t    alternate_group;
    int64_t     startOffset;

    BOOL    isEdited;
    BOOL    muxed;
    BOOL    needConversion;

	uint32_t    timescale; 
	uint32_t    bitrate; 
	MP4Duration duration;

    NSMutableDictionary *updatedProperty;

    MP42FileImporter * trackImporterHelper;
    id trackDemuxerHelper;
    id trackConverterHelper;
}

@property(readwrite) MP4TrackId Id;
@property(readwrite) MP4TrackId sourceId;
@property(readwrite, retain) id sourceFileHandle;

@property(readwrite, retain) NSURL *sourceURL;
@property(readwrite, retain) NSString *sourceFormat;
@property(readwrite, retain) NSString *format;
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *language;

@property(readwrite) BOOL     enabled;
@property(readwrite) uint64_t alternate_group;
@property(readwrite) int64_t  startOffset;

@property(readonly) uint32_t timescale;
@property(readonly) uint32_t bitrate;
@property(readwrite) MP4Duration duration;

@property(readwrite) BOOL isEdited;
@property(readwrite) BOOL muxed;
@property(readwrite) BOOL needConversion;

@property(readwrite, assign) MP42FileImporter * trackImporterHelper;
@property(readwrite, retain) id trackDemuxerHelper;
@property(readwrite, retain) id trackConverterHelper;

@property(readwrite, retain) NSMutableDictionary *updatedProperty;

- (id) initWithSourceURL:(NSURL *)URL trackID:(NSInteger)trackID fileHandle:(MP4FileHandle)fileHandle;
- (BOOL) writeToFile:(MP4FileHandle)fileHandle error:(NSError **)outError;

- (NSString *) timeString;
- (NSString *) formatSummary;

@end
