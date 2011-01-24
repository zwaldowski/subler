//
//  MP42ChapterTrack.h
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MP42Track.h"

@class SBTextSample;

@interface MP42ChapterTrack : MP42Track {
    NSMutableArray *chapters;
}
- (id) initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID fileHandle:(MP4FileHandle)fileHandle;
+ (id) chapterTrackFromFile:(NSString *)filePath;

- (void) addChapter:(NSString *)title duration:(uint64_t)timestamp;
- (void) removeChapterAtIndex:(NSUInteger)index;

- (void) setTimestamp:(MP4Duration)timestamp forChapter:(SBTextSample*)chapterSample;
- (void) setTitle:(NSString*)title forChapter:(SBTextSample*)chapterSample;

- (SBTextSample*) chapterAtIndex:(NSUInteger)index;

- (NSInteger) chapterCount;

- (BOOL)exportToURL:(NSURL *)url error:(NSError **)error;

@property (readonly, retain) NSArray * chapters;

@end
