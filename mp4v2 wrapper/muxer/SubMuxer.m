//
//  MP42SubtitleTrack.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SubMuxer.h"
#import "MP42Utilities.h"
#import "SubUtilities.h"
#import "lang.h"

static MP4TrackId createSubtitleTrack(MP4FileHandle file, MP4TrackId refTrackId, const char* language_iso639_2,
                               uint16_t video_width, uint16_t video_height, uint16_t subtitleHeight)
{
    const uint8_t textColor[4] = { 255,255,255,255 };
    MP4TrackId subtitle_track = MP4AddSubtitleTrack(file, refTrackId);

    MP4SetTrackLanguage(file, subtitle_track, language_iso639_2);

    MP4SetTrackFloatProperty(file,subtitle_track, "tkhd.width", video_width);
    MP4SetTrackFloatProperty(file,subtitle_track, "tkhd.height", subtitleHeight);

    MP4SetTrackIntegerProperty(file,subtitle_track, "tkhd.alternate_group", 2);

    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.horizontalJustification", 1);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.verticalJustification", 0);

	MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.bgColorAlpha", 255);

    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.defTextBoxBottom", subtitleHeight);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.defTextBoxRight", video_width);

    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontID", 1);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontSize", 24);

    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontColorRed", textColor[0]);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontColorGreen", textColor[1]);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontColorBlue", textColor[2]);
    MP4SetTrackIntegerProperty(file,subtitle_track, "mdia.minf.stbl.stsd.tx3g.fontColorAlpha", textColor[3]);

    /* translate the track */
    uint8_t* val;
    uint8_t nval[36];
    uint32_t *ptr32 = (uint32_t*) nval;
    uint32_t size;

    MP4GetTrackBytesProperty(file, subtitle_track, "tkhd.matrix", &val, &size);
    memcpy(nval, val, size);
    ptr32[7] = CFSwapInt32HostToBig( (video_height - subtitleHeight) * 0x10000);

    MP4SetTrackBytesProperty(file, subtitle_track, "tkhd.matrix", nval, size);
    free(val);

    /* set the timescale to ms */
    MP4SetTrackTimeScale(file,subtitle_track, 1000);

    enableFirstSubtitleTrack(file);

	return subtitle_track;
}

static int writeSubtitleSample(MP4FileHandle file, MP4TrackId subtitleTrackId,const char* string, MP4Duration duration)
{
    int Err;
    const size_t stringLength = strlen(string);
    u_int8_t buffer[1024];
    memcpy(buffer+2, string, strlen(string)); // strlen > 1024 -> booom?
    buffer[0] = (stringLength >> 8) & 0xff;
    buffer[1] = stringLength & 0xff;
    
    Err = MP4WriteSample(file,
                         subtitleTrackId,
                         buffer,
                         stringLength + 2,
                         duration,
                         0, true);
    return Err;
}

static int writeEmptySubtitleSample(MP4FileHandle file, MP4TrackId subtitleTrackId, MP4Duration duration)
{
    int Err;
    u_int8_t empty[2] = {0,0};
    Err = MP4WriteSample(file,
                         subtitleTrackId,
                         empty,
                         2,
                         duration,
                         0, true);
    return Err;
}

int muxSRTSubtitleTrack(MP4FileHandle fileHandle, NSString* subtitlePath, const char* lang, uint16_t subtitleHeight, int16_t delay) {
    BOOL success = YES;
    MP4TrackId subtitleTrackId, videoTrack;
    uint16_t videoWidth, videoHeight;

    videoTrack = findFirstVideoTrack(fileHandle);
    if (!videoTrack)
        return 0;

    videoWidth = getFixedVideoWidth(fileHandle, videoTrack);
    videoHeight = MP4GetTrackVideoHeight(fileHandle, videoTrack);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    SubSerializer *ss = [[SubSerializer alloc] init];
    success = LoadSRTFromPath(subtitlePath, ss);
    [ss setFinished:YES];

    if (success) {
        int firstSub = 0;

        success = subtitleTrackId = createSubtitleTrack(fileHandle, 1, lang, videoWidth, videoHeight, subtitleHeight);

        while (![ss isEmpty]) {
            SubLine *sl = [ss getSerializedPacket];
            const char *str = [sl->line UTF8String];
            if (firstSub == 0) {
                firstSub++;
                if (!writeEmptySubtitleSample(fileHandle, subtitleTrackId, sl->begin_time + delay))
                    break;
            }
            if ([sl->line isEqualToString:@"\n"]) {
                if (!writeEmptySubtitleSample(fileHandle, subtitleTrackId, sl->end_time - sl->begin_time))
                    break;
                continue;
            }
            if (!writeSubtitleSample(fileHandle, subtitleTrackId, str, sl->end_time - sl->begin_time))
                break;
        }
        writeEmptySubtitleSample(fileHandle, subtitleTrackId, 100);
    }

    [ss release];
    [pool release];

    return success;
}

int muxMP4SubtitleTrack(MP4FileHandle fileHandle, NSString* filePath, MP4TrackId sourceTrackId)
{
    BOOL success = YES;
    MP4FileHandle sourceFileHandle;

    sourceFileHandle = MP4Read([filePath UTF8String], MP4_DETAILS_ERROR);
    MP4TrackId subtitleTrackId;

    success = subtitleTrackId = MP4CopyTrack(sourceFileHandle, sourceTrackId, fileHandle, YES, MP4_INVALID_TRACK_ID);

    MP4Close(sourceFileHandle);

    return success;
}
