//
//  MP42File.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <mp4v2/mp4v2.h>
#import "MP42Track.h"
#import "MP42VideoTrack.h"
#import "MP42AudioTrack.h"
#import "MP42SubtitleTrack.h"
#import "MP42ClosedCaptionTrack.h"
#import "MP42ChapterTrack.h"
#import "MP42Metadata.h"
#import "MP42Utilities.h"
#import "MP42Muxer.h"
#import "MP42FileImporter.h"

extern NSString * const MP42Create64BitData;
extern NSString * const MP42Create64BitTime;
extern NSString * const MP42CreateChaptersPreviewTrack;

extern NSString * const MP42FileTypeMP4;
extern NSString * const MP42FileTypeM4V;
extern NSString * const MP42FileTypeM4A;

@class MP42File;

@protocol MP42FileDelegate <NSObject>

@optional

- (void)file:(MP42File *)file didUpdateProgress:(CGFloat)progress;

@end

@interface MP42File : NSObject <NSCoding> {
@private
    MP4FileHandle  fileHandle;
    NSURL          *fileURL;
    id <MP42FileDelegate> delegate;

    NSMutableArray  *tracksToBeDeleted;
    NSMutableArray  *fileImporters;
    BOOL             hasFileRepresentation;
    BOOL             isCancelled;

@protected
    NSMutableArray  *tracks;
    MP42Metadata    *metadata;
    MP42Muxer       *muxer;
}

@property (nonatomic, assign) id <MP42FileDelegate> delegate;
@property (readonly) NSURL  *URL;
@property (readonly) NSMutableArray  *tracks;
@property (readonly) MP42Metadata    *metadata;
@property (readonly) BOOL hasFileRepresentation;

- (id)   initWithDelegate:(id <MP42FileDelegate>)del;
- (id)   initWithExistingFile:(NSURL *)URL andDelegate:(id <MP42FileDelegate>)del;

- (NSUInteger) movieDuration;
- (MP42ChapterTrack*) chapters;

- (NSUInteger) tracksCount;
- (id)   trackAtIndex:(NSUInteger)index;

- (void) addTrack:(id)object;

- (void) removeTrackAtIndex:(NSUInteger)index;
- (void) removeTracksAtIndexes:(NSIndexSet *)indexes;
- (void) moveTrackAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;

- (BOOL) writeToUrl:(NSURL *)url withAttributes:(NSDictionary *)attributes error:(NSError **)outError;
- (BOOL) updateMP4FileWithAttributes:(NSDictionary *)attributes error:(NSError **)outError;
- (void) optimize;

- (void) cancel;

@end