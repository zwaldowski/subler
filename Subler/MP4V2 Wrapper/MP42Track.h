//
//  MP42Track.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <mp4v2/mp4v2.h>
#import "MP42FileImporter.h"

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

    id <MP42FileImporter> __unsafe_unretained trackImporterHelper;
    id trackDemuxerHelper;
    id trackConverterHelper;
}

@property(readwrite) MP4TrackId Id;
@property(readwrite) MP4TrackId sourceId;
@property(readwrite, strong) id sourceFileHandle;

@property(readwrite, strong) NSURL *sourceURL;
@property(readwrite, strong) NSString *sourceFormat;
@property(readwrite, strong) NSString *format;
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) NSString *language;

@property(readwrite) BOOL     enabled;
@property(readwrite) uint64_t alternate_group;
@property(readwrite) int64_t  startOffset;

@property(readonly) uint32_t timescale;
@property(readonly) uint32_t bitrate;
@property(readwrite) MP4Duration duration;

@property(readwrite) BOOL isEdited;
@property(readwrite) BOOL muxed;
@property(readwrite) BOOL needConversion;

@property(nonatomic, unsafe_unretained) id <MP42FileImporter> trackImporterHelper;
@property(nonatomic, strong) id trackDemuxerHelper;
@property(nonatomic, strong) id trackConverterHelper;

@property(nonatomic, strong) NSMutableDictionary *updatedProperty;

- (id) initWithSourceURL:(NSURL *)URL trackID:(NSInteger)trackID fileHandle:(MP4FileHandle)fileHandle;
- (BOOL) writeToFile:(MP4FileHandle)fileHandle error:(NSError **)outError;

- (NSString *) timeString;
- (NSString *) formatSummary;

@end
