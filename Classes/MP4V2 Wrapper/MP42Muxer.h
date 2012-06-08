//
//  MP42Muxer.h
//  Subler
//
//  Created by Damiano Galassi on 30/06/10.
//  Copyright 2010 Damiano Galassi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mp4v2.h"

@class MP42Track, MP42Muxer;

@protocol MP42MuxerDelegate <NSObject>

- (void)muxer:(MP42Muxer *)muxer didUpdateProgress: (CGFloat)progress;

@end

@interface MP42Muxer : NSObject {
    NSMutableArray *workingTracks;
    id <MP42MuxerDelegate> delegate;

    BOOL    isCancelled;
}

- (id)initWithDelegate:(id <MP42MuxerDelegate>)del;

- (void)addTrack:(MP42Track*)track;

- (BOOL)prepareWork:(MP4FileHandle)fileHandle error:(NSError **)outError;
- (void)start:(MP4FileHandle)fileHandle;
- (void)cancel;

@end