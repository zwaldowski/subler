//
//  MP42ChapterTrack.m
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "MP42ChapterTrack.h"
#import "SubUtilities.h"
#import "MP42Utilities.h"
#import "MP42FileImporter.h"

@implementation MP42ChapterTrack

- (id) init
{
    if ((self = [super init]))
    {
        name = @"Chapter Track";
        format = @"Text";
        language = @"English";
        isEdited = YES;
        muxed = NO;
        enabled = NO;

        chapters = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithSourceURL:(NSURL *)URL trackID:(NSInteger)trackID fileHandle:(MP4FileHandle)fileHandle
{
    if ((self = [super initWithSourceURL:URL trackID:trackID fileHandle:fileHandle]))
    {
        if (!name || [name isEqualToString:@"Text Track"])
            name = @"Chapter Track";
        if (!format)
            format = @"Text";
        chapters = [[NSMutableArray alloc] init];

        MP4Chapter_t *chapter_list = NULL;
        uint32_t      chapter_count;

        MP4GetChapters(fileHandle, &chapter_list, &chapter_count, MP4ChapterTypeQt);

        unsigned int i = 1;
        MP4Duration sum = 0;
        while (i <= chapter_count)
        {
            SBTextSample *chapter = [[SBTextSample alloc] init];

            char * title = chapter_list[i-1].title;
            if ((title[0] == '\xfe' && title[1] == '\xff') || (title[0] == '\xff' && title[1] == '\xfe')) {
                chapter.title = [[NSString alloc] initWithBytes:title
														  length:chapter_list[i-1].titleLength
														encoding:NSUTF16StringEncoding];
            }
            else {
                chapter.title = [NSString stringWithCString:chapter_list[i-1].title encoding: NSUTF8StringEncoding];
            }

            chapter.timestamp = sum;
            sum = chapter_list[i-1].duration + sum;
            [chapters addObject:chapter];
            i++;
        }
        MP4Free(chapter_list);
    }

    return self;
}

- (id) initWithTextFile:(NSURL *)URL
{
    if ((self = [super init]))
    {
        name = @"Chapter Track";
        format = @"Text";
        sourceURL = URL;
        language = @"English";
        isEdited = YES;
        muxed = NO;
        enabled = NO;

        chapters = [[NSMutableArray alloc] init];
        LoadChaptersFromPath([sourceURL path], chapters);   
        [chapters sortUsingSelector:@selector(compare:)];
    }
    
    return self;
}

+ (id) chapterTrackFromFile:(NSURL *)URL
{
    return [[MP42ChapterTrack alloc] initWithTextFile:URL];
}

- (void) addChapter:(NSString *)title duration:(uint64_t)timestamp
{
    SBTextSample *newChapter = [[SBTextSample alloc] init];
    newChapter.title = title;
    newChapter.timestamp = timestamp;

    [self setIsEdited:YES];

    [chapters addObject:newChapter];
    [chapters sortUsingSelector:@selector(compare:)];
}

- (void) removeChapterAtIndex:(NSUInteger)index
{
    [self setIsEdited:YES];
    [chapters removeObjectAtIndex:index];
}

- (void) setTimestamp:(MP4Duration)timestamp forChapter:(SBTextSample*)chapterSample
{
    [self setIsEdited:YES];
    [chapterSample setTimestamp:timestamp];
    [chapters sortUsingSelector:@selector(compare:)];
}

- (void) setTitle:(NSString*)title forChapter:(SBTextSample*)chapterSample
{
    [self setIsEdited:YES];
    [chapterSample setTitle:title];
}

- (SBTextSample*) chapterAtIndex:(NSUInteger)index
{
    return [chapters objectAtIndex:index];
}

- (BOOL) writeToFile:(MP4FileHandle)fileHandle error:(NSError **)outError
{
    BOOL success = YES;

    if (isEdited) {
        MP4Chapter_t * fileChapters = 0;
        uint32_t i, refTrackDuration, chapterCount = 0;
        uint64_t sum = 0;

        // get the list of chapters
        MP4GetChapters(fileHandle, &fileChapters, &chapterCount, MP4ChapterTypeQt);

        MP4DeleteChapters(fileHandle, MP4ChapterTypeAny, Id);
        updateTracksCount(fileHandle);

        MP4TrackId refTrack = findFirstVideoTrack(fileHandle);
        if (!refTrack)
            refTrack = 1;

        chapterCount = [chapters count];
        fileChapters = malloc(sizeof(MP4Chapter_t)*chapterCount);
        refTrackDuration = MP4ConvertFromTrackDuration(fileHandle,
                                                       refTrack,
                                                       MP4GetTrackDuration(fileHandle, refTrack),
                                                       MP4_MSECS_TIME_SCALE);

        for (i = 0; i < chapterCount; i++) {
            SBTextSample * chapter = [chapters objectAtIndex:i];
            strcpy(fileChapters[i].title, [[chapter title] UTF8String]);

            if (i+1 < chapterCount && sum < refTrackDuration) {
                SBTextSample * nextChapter = [chapters objectAtIndex:i+1];
                fileChapters[i].duration = nextChapter.timestamp - chapter.timestamp;
                sum = nextChapter.timestamp;
            }
            else
                fileChapters[i].duration = refTrackDuration - chapter.timestamp;

            if (sum > refTrackDuration) {
                fileChapters[i].duration = refTrackDuration - chapter.timestamp;
                i++;
                break;
            }
        }

        removeAllChapterTrackReferences(fileHandle);
        MP4SetChapters(fileHandle, fileChapters, i, MP4ChapterTypeAny);

        free(fileChapters);
        success = Id = findChapterTrackId(fileHandle);
    }
    if (!success) {
        if ( outError != NULL)
            *outError = MP42Error(@"Failed to mux chapters into mp4 file",
                                  nil,
                                  120);

        return success;
    }
    else if (Id)
        success = [super writeToFile:fileHandle error:outError];

    return success;
}

- (NSInteger)chapterCount
{
  return [chapters count];
}

- (BOOL)exportToURL:(NSURL *)url error:(NSError **)error
{
	NSMutableString* file = [[NSMutableString alloc] init];
	NSUInteger x = 0;

	for (SBTextSample * chapter in chapters) {
		[file appendFormat:@"CHAPTER%02ld=%@\nCHAPTER%02ldNAME=%@\n", x, SRTStringFromTime([chapter timestamp], 1000, '.'), x, [chapter title]];
		x++;
	}

	return [file writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (void) setTrackImporterHelper: (id <MP42FileImporter>) importerHelper
{
}


@synthesize chapters;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:chapters forKey:@"chapters"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];

    chapters = [decoder decodeObjectForKey:@"chapters"];

    return self;
}

@end
