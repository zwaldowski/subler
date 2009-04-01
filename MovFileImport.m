//
//  FileImport.m
//  Subler
//
//  Created by Damiano Galassi on 15/03/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "MovFileImport.h"
#import <QuickTime/QuickTime.h>
#include "lang.h"

@implementation MovFileImport

- (id)initWithDelegate:(id)del andFile: (NSString *)path
{
	if (self = [super initWithWindowNibName:@"FileImport"])
	{        
		delegate = del;
        filePath = path;
        sourceFile = [[QTMovie alloc] initWithFile:filePath error:nil];
        NSInteger i = [[sourceFile tracks] count];
        importCheckArray = [[NSMutableArray alloc] initWithCapacity:i];

        while (i) {
            [importCheckArray addObject: [NSNumber numberWithBool:YES]];
            i--;
        }

        if([sourceFile hasChapters]) {
            long    myCount;
            long    myTrackCount = GetMovieTrackCount([sourceFile quickTimeMovie]);
            Track   myTrack = NULL;
            Track   myChapTrack = NULL;

            for (myCount = 1; myCount <= myTrackCount; myCount++) {
                myTrack = GetMovieIndTrack([sourceFile quickTimeMovie], myCount);
                if (GetTrackEnabled(myTrack))
                    myChapTrack = GetTrackReference(myTrack, kTrackReferenceChapterList, 1);
                if (myChapTrack != NULL)
                    chapterTrackId = GetTrackID(myChapTrack);
                    break;
            }
        }
    }

	return self;
}

- (NSString*)formatForTrack: (QTTrack *)track;
{
    NSString* result = @"";
    ImageDescriptionHandle idh = (ImageDescriptionHandle) NewHandleClear(sizeof(ImageDescription));
    GetMediaSampleDescription([[track media] quickTimeMedia], 1,
                              (SampleDescriptionHandle)idh);
    
    switch ((*idh)->cType) {
        case kH264CodecType:
            result = @"H.264";
            break;
        case kMPEG4VisualCodecType:
            result = @"MPEG-4 Visual";
            break;
        case 'mp4a':
            result = @"AAC";
            break;
        case kAudioFormatAC3:
        case 'ms \0':
            result = @"AC-3";
            break;
        case kAudioFormatAMR:
            result = @"AMR Narrow Band";
            break;
        case TextMediaType:
            result = @"Text";
            break;
        case kTx3gSampleType:
            result = @"3GPP Text";
            break;
        case 'SRT ':
            result = @"Text";
            break;
        case 'SSA ':
            result = @"SSA";
            break;
        case TimeCodeMediaType:
            result = @"Timecode";
            break;
        default:
            result = @"Unknown";
            break;
    }
    DisposeHandle((Handle)idh);
    return result;
}

- (NSString*)langForTrack: (QTTrack *)track;
{
    short lang = GetMediaLanguage([[track media] quickTimeMedia]);

    return [NSString stringWithFormat:@"%s", lang_for_qtcode(lang)->eng_name];
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *) t
{
    if( !sourceFile )
        return 0;

    return [[sourceFile tracks] count];
}

- (id) tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
             row:(NSInteger)rowIndex
{
    QTTrack *track = [[sourceFile tracks] objectAtIndex:rowIndex];

    if (!track)
        return nil;
    
    if( [tableColumn.identifier isEqualToString: @"check"] )
        return [importCheckArray objectAtIndex: rowIndex];

    if ([tableColumn.identifier isEqualToString:@"trackId"]) {
        return [track attributeForKey:QTTrackIDAttribute];
    }

    if ([tableColumn.identifier isEqualToString:@"trackName"])
        if ([[track attributeForKey:QTTrackIDAttribute] integerValue] == chapterTrackId)
            return @"Chapter Track";
        else
            return [track attributeForKey:QTTrackDisplayNameAttribute];

    if ([tableColumn.identifier isEqualToString:@"trackInfo"]) {
        return [self formatForTrack:track];
    }

    if ([tableColumn.identifier isEqualToString:@"trackDuration"]) {
        return QTStringFromTime([[track attributeForKey:QTTrackRangeAttribute] QTTimeRangeValue].duration);
    }
    if ([tableColumn.identifier isEqualToString:@"trackLanguage"])
        return [self langForTrack:track];

    return nil;
}

- (void) tableView: (NSTableView *) tableView 
    setObjectValue: (id) anObject 
    forTableColumn: (NSTableColumn *) tableColumn 
               row: (NSInteger) rowIndex
{
    if ([tableColumn.identifier isEqualToString: @"check"])
        [importCheckArray replaceObjectAtIndex:rowIndex withObject:anObject];
}

- (IBAction) closeWindow: (id) sender
{
    if ([delegate respondsToSelector:@selector(importDone:)]) 
        [delegate importDone:nil];
}

- (IBAction) addTracks: (id) sender
{
    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    NSInteger i;

    for (i = 0; i < [[sourceFile tracks] count]; i++) {
        if ([[importCheckArray objectAtIndex: i] boolValue]) {
            QTTrack *track = [[sourceFile tracks] objectAtIndex:i];
            NSString* mediaType = [track attributeForKey:QTTrackMediaTypeAttribute];
            MP42Track *newTrack = nil;

            // Video
            if ([mediaType isEqualToString:QTMediaTypeVideo]) {
                if ([[self formatForTrack:track] isEqualToString:@"Text"] || [[self formatForTrack:track] isEqualToString:@"SSA"])
                    newTrack = [[MP42SubtitleTrack alloc] init];
                else
                    newTrack = [[MP42VideoTrack alloc] init];

                NSSize dimesion = [track apertureModeDimensionsForMode:QTMovieApertureModeClean];
                [(MP42VideoTrack*)newTrack setTrackWidth: dimesion.width];
                [(MP42VideoTrack*)newTrack setTrackHeight: dimesion.height];
            }

            // Audio
            else if ([mediaType isEqualToString:QTMediaTypeSound])
                newTrack = [[MP42AudioTrack alloc] init];

            // Text
            else if ([mediaType isEqualToString:QTMediaTypeText])
                if ([[track attributeForKey:QTTrackIDAttribute] integerValue] == chapterTrackId) {
                    newTrack = [[MP42ChapterTrack alloc] init];
                    NSArray *chapters = [sourceFile chapters];

                    for (NSDictionary *dic in chapters) {
                        QTTimeRange time = [[dic valueForKey:QTMovieChapterStartTime] QTTimeRangeValue];
                        [(MP42ChapterTrack*)newTrack addChapter:[dic valueForKey:QTMovieChapterName]
                                                       duration:((float)time.time.timeValue / time.time.timeScale)*1000];
                    }
                }
            // Subtitle
            else if([mediaType isEqualToString:@"sbtl"])
                    newTrack = [[MP42SubtitleTrack alloc] init];

            if (newTrack) {
                newTrack.format = [self formatForTrack:track];
                newTrack.Id = i;
                newTrack.sourcePath = filePath;
                newTrack.name = [track attributeForKey:QTTrackDisplayNameAttribute];
                newTrack.language = [self langForTrack:track];
                [tracks addObject:newTrack];
                [newTrack release];
            }
        }
    }

    if ([delegate respondsToSelector:@selector(importDone:)]) 
        [delegate importDone:tracks];

    [tracks release];
}

- (void) dealloc
{
    [sourceFile release];
    [importCheckArray release];
    [super dealloc];
}

@end
