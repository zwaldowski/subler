//
//  MP42SubtitleTrack.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "VideoMuxer.h"
#import "MP42Utilities.h"
#import "SubUtilities.h"
#if !__LP64__
    #import <QuickTime/QuickTime.h>
#endif
#import "lang.h"

static const framerate_t framerates[] =
{ { 2398, 24000, 1001 },
  { 24, 600, 25 },
  { 25, 600, 24 },
  { 2997, 30000, 1001 },
  { 30, 600, 20 },
  { 5994, 60000, 1001 },
  { 60, 600, 10 },
  { 0, 24000, 1001 } };

MP4TrackId H264Creator (MP4FileHandle mp4File, FILE* inFile,
                        uint32_t timescale, uint32_t mp4FrameDuration);

int muxH264ElementaryStream(MP4FileHandle fileHandle, NSString* filePath, uint32_t frameRateCode) {
    MP4TrackId dstTrackId = MP4_INVALID_TRACK_ID;
    FILE* inFile = fopen([filePath UTF8String], "rb");
    framerate_t * framerate;

    for (framerate = (framerate_t*) framerates; framerate->code; framerate++)
        if(frameRateCode == framerate->code)
            break;

    dstTrackId = H264Creator(fileHandle, inFile, framerate->timescale, framerate->duration);
    fclose(inFile);

    return dstTrackId;
}

#if !__LP64__
int muxMOVVideoTrack(MP4FileHandle fileHandle, QTMovie* srcFile, MP4TrackId srcTrackId)
{
    OSStatus err = noErr;
    Track track = [[[srcFile tracks] objectAtIndex:srcTrackId] quickTimeTrack];
    Media media = GetTrackMedia(track);
    MP4TrackId dstTrackId = MP4_INVALID_TRACK_ID;
    long count;

    // Get the sample description
	SampleDescriptionHandle desc = (SampleDescriptionHandle) NewHandle(0);
    GetMediaSampleDescription(media, 1, desc);

    ImageDescriptionHandle imgDesc = (ImageDescriptionHandle) desc;

    if ((*imgDesc)->cType == kH264CodecType) {
        // Get avcC atom
        Handle imgDescHandle = NewHandle(0);
        GetImageDescriptionExtension(imgDesc, &imgDescHandle, 'avcC', 1);

        MP4SetVideoProfileLevel(fileHandle, 0x15);
        // Add video track
        dstTrackId = MP4AddH264VideoTrack(fileHandle, GetMediaTimeScale(media),
                                          MP4_INVALID_DURATION,
                                          (*imgDesc)->width, (*imgDesc)->height,
                                          (*imgDescHandle)[1],  // AVCProfileIndication
                                          (*imgDescHandle)[2],  // profile_compat
                                          (*imgDescHandle)[3],  // AVCLevelIndication
                                          (*imgDescHandle)[4]); // lengthSizeMinusOne

        // We have got a complete avcC atom, but mp4v2 wants sps and pps separately
        SInt64 i;
        int8_t spsCount = ((*imgDescHandle)[5] & 0x1f);
        uint8_t ptrPos = 6;
        for (i = 0; i < spsCount; i++) {
            uint16_t spsSize = ((*imgDescHandle)[ptrPos++] << 8) & 0xff00;
            spsSize += (*imgDescHandle)[ptrPos++] & 0xff;
            MP4AddH264SequenceParameterSet(fileHandle, dstTrackId,
                                           (uint8_t *)*imgDescHandle+ptrPos, spsSize);
            ptrPos += spsSize;
        }

        int8_t ppsCount = (*imgDescHandle)[ptrPos++];
        for (i = 0; i < ppsCount; i++) {
            uint16_t ppsSize = ((*imgDescHandle)[ptrPos++] << 8) & 0xff00;
            ppsSize += (*imgDescHandle)[ptrPos++] & 0xff;
            MP4AddH264PictureParameterSet(fileHandle, dstTrackId,
                                      (uint8_t*)*imgDescHandle+ptrPos, ppsSize);
            ptrPos += ppsSize;
        }
        DisposeHandle(imgDescHandle);
    }
    else if ((*imgDesc)->cType == kMPEG4VisualCodecType) {
        MP4SetVideoProfileLevel(fileHandle, MPEG4_SP_L3);
        // Add video track
        dstTrackId = MP4AddVideoTrack(fileHandle, GetMediaTimeScale(media),
                                      MP4_INVALID_DURATION,
                                      (*imgDesc)->width, (*imgDesc)->height,
                                      MP4_MPEG4_VIDEO_TYPE);

        // Add ES decoder specific configuration
        CountImageDescriptionExtensionType(imgDesc, 'esds',  &count);
        if (count >= 1) {
            Handle imgDescExt = NewHandle(0);
            UInt8* buffer;
            int size;

            GetImageDescriptionExtension(imgDesc, &imgDescExt, 'esds', 1);

            ReadESDSDescExt(*imgDescExt, &buffer, &size, 1);
            MP4SetTrackESConfiguration(fileHandle, dstTrackId, buffer, size);

            DisposeHandle(imgDescExt);
        }
    }
    else
        goto bail;

    MP4SetTrackDurationPerChunk(fileHandle, dstTrackId, GetMediaTimeScale(media) / 8);

    // Add pixel aspect ratio and color atom
    CountImageDescriptionExtensionType(imgDesc, kPixelAspectRatioImageDescriptionExtension, &count);
    if (count > 0) {
        Handle pasp = NewHandle(0);
        GetImageDescriptionExtension(imgDesc, &pasp, kPixelAspectRatioImageDescriptionExtension, 1);
        MP4AddPixelAspectRatio(fileHandle, dstTrackId,
                               CFSwapInt32BigToHost(((PixelAspectRatioImageDescriptionExtension*)(*pasp))->hSpacing),
                               CFSwapInt32BigToHost(((PixelAspectRatioImageDescriptionExtension*)(*pasp))->vSpacing));
        DisposeHandle(pasp);
    }

    CountImageDescriptionExtensionType(imgDesc, kColorInfoImageDescriptionExtension, &count);
    if (count > 0) {
        Handle colr = NewHandle(0);
        GetImageDescriptionExtension(imgDesc, &colr, kColorInfoImageDescriptionExtension, 1);
        MP4AddColr(fileHandle, dstTrackId,
                   CFSwapInt16BigToHost(((NCLCColorInfoImageDescriptionExtension*)(*colr))->primaries),
                   CFSwapInt16BigToHost(((NCLCColorInfoImageDescriptionExtension*)(*colr))->transferFunction),
                   CFSwapInt16BigToHost(((NCLCColorInfoImageDescriptionExtension*)(*colr))->matrix));
        DisposeHandle(colr);
    }    

    // Create a QTSampleTable which contains all the informatio of the track samples.
    TimeValue64 sampleTableStartDecodeTime = 0;
    QTMutableSampleTableRef sampleTable = NULL;
    err = CopyMediaMutableSampleTable(media,
                                      0,
                                      &sampleTableStartDecodeTime,
                                      0,
                                      0,
                                      &sampleTable);
    require_noerr(err, bail);

    TimeValue64 minDisplayOffset = 0;
    err = QTSampleTableGetProperty(sampleTable,
                                   kQTPropertyClass_SampleTable,
                                   kQTSampleTablePropertyID_MinDisplayOffset,
                                   sizeof(TimeValue64),
                                   &minDisplayOffset,
                                   NULL);
    require_noerr(err, bail);

    SInt64 sampleIndex, sampleCount;
    sampleCount = QTSampleTableGetNumberOfSamples(sampleTable);

    for (sampleIndex = 1; sampleIndex <= sampleCount; sampleIndex++) {
        TimeValue64 sampleDecodeTime = 0;
        ByteCount sampleDataSize = 0;
        MediaSampleFlags sampleFlags = 0;
		UInt8 *sampleData = NULL;
        TimeValue64 decodeDuration = QTSampleTableGetDecodeDuration(sampleTable, sampleIndex);
        TimeValue64 displayOffset = QTSampleTableGetDisplayOffset(sampleTable, sampleIndex);
        uint32_t dflags = 0;

        // Get the frame's data size and sample flags.  
        SampleNumToMediaDecodeTime( media, sampleIndex, &sampleDecodeTime, NULL);
		sampleDataSize = QTSampleTableGetDataSizePerSample(sampleTable, sampleIndex);
        sampleFlags = QTSampleTableGetSampleFlags(sampleTable, sampleIndex);
        dflags |= (sampleFlags & mediaSampleHasRedundantCoding) ? MP4_SDT_HAS_REDUNDANT_CODING : 0;
        dflags |= (sampleFlags & mediaSampleHasNoRedundantCoding) ? MP4_SDT_HAS_NO_REDUNDANT_CODING : 0;
        dflags |= (sampleFlags & mediaSampleIsDependedOnByOthers) ? MP4_SDT_HAS_DEPENDENTS : 0;
        dflags |= (sampleFlags & mediaSampleIsNotDependedOnByOthers) ? MP4_SDT_HAS_NO_DEPENDENTS : 0;
        dflags |= (sampleFlags & mediaSampleDependsOnOthers) ? MP4_SDT_IS_DEPENDENT : 0;
        dflags |= (sampleFlags & mediaSampleDoesNotDependOnOthers) ? MP4_SDT_IS_INDEPENDENT : 0;
        dflags |= (sampleFlags & mediaSampleEarlierDisplayTimesAllowed) ? MP4_SDT_EARLIER_DISPLAY_TIMES_ALLOWED : 0;

        // Load the frame.
		sampleData = malloc(sampleDataSize);
		GetMediaSample2(media, sampleData, sampleDataSize, NULL, sampleDecodeTime,
                        NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL);

        err = MP4WriteSampleDependency(fileHandle,
                                       dstTrackId,
                                       sampleData,
                                       sampleDataSize,
                                       decodeDuration,
                                       displayOffset -minDisplayOffset,
                                       !(sampleFlags & mediaSampleNotSync),
                                       dflags);
        free(sampleData);
        if(!err) goto bail;
    }

    QTSampleTableRelease(sampleTable);

    TimeValue editTrackStart, editTrackDuration;
	TimeValue64 editDisplayStart, trackDuration = 0;
    Fixed editDwell;

	// Find the first edit
	// Each edit has a starting track timestamp, a duration in track time, a starting display timestamp and a rate.
	GetTrackNextInterestingTime(track, 
                                nextTimeTrackEdit | nextTimeEdgeOK,
                                0,
                                fixed1,
                                &editTrackStart,
                                &editTrackDuration);

    while (editTrackDuration > 0) {
        editDisplayStart = TrackTimeToMediaDisplayTime(editTrackStart, track);
        editTrackDuration = (editTrackDuration / (float)GetMovieTimeScale([srcFile quickTimeMovie])) * MP4GetTimeScale(fileHandle);
        editDwell = GetTrackEditRate64(track, editTrackStart);
        
        if (minDisplayOffset < 0 && editDisplayStart != -1)
            MP4AddTrackEdit(fileHandle, dstTrackId, MP4_INVALID_EDIT_ID, editDisplayStart -minDisplayOffset,
                            editTrackDuration, !Fix2X(editDwell));
        else
            MP4AddTrackEdit(fileHandle, dstTrackId, MP4_INVALID_EDIT_ID, editDisplayStart,
                            editTrackDuration, !Fix2X(editDwell));

        trackDuration += editTrackDuration;
        // Find the next edit
		GetTrackNextInterestingTime(track,
                                    nextTimeTrackEdit,
                                    editTrackStart,
                                    fixed1,
                                    &editTrackStart,
                                    &editTrackDuration);
    }

    MP4SetTrackIntegerProperty(fileHandle, dstTrackId, "tkhd.duration", trackDuration);

bail:
    DisposeHandle((Handle) desc);

    return dstTrackId;
}
#endif

int muxMP4VideoTrack(MP4FileHandle fileHandle, NSString* filePath, MP4TrackId srcTrackId)
{
    MP4FileHandle srcFile = MP4Read([filePath UTF8String], 0);
    MP4TrackId dstTrackId = MP4CloneTrack(srcFile, srcTrackId, fileHandle, MP4_INVALID_TRACK_ID);

    if (dstTrackId == MP4_INVALID_TRACK_ID) {
        MP4Close(srcFile);
        return dstTrackId;
    }

    MP4SetTrackDurationPerChunk(fileHandle, dstTrackId, MP4GetTrackTimeScale(srcFile, srcTrackId) / 8);

    if (MP4HaveTrackAtom(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.pasp")) {
        uint64_t hSpacing, vSpacing;
        MP4GetTrackIntegerProperty(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.pasp.hSpacing", &hSpacing);
        MP4GetTrackIntegerProperty(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.pasp.vSpacing", &vSpacing);

        if ( hSpacing >= 1 && vSpacing >= 1)
        MP4AddPixelAspectRatio(fileHandle, dstTrackId, hSpacing, vSpacing);
    }

    if (MP4HaveTrackAtom(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.colr")) {
        uint64_t primariesIndex, transferFunctionIndex, matrixIndex;
        MP4GetTrackIntegerProperty(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.colr.primariesIndex", &primariesIndex);
        MP4GetTrackIntegerProperty(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.colr.transferFunctionIndex", &transferFunctionIndex);
        MP4GetTrackIntegerProperty(srcFile, srcTrackId, "mdia.minf.stbl.stsd.*.colr.matrixIndex", &matrixIndex);

        MP4AddColr(fileHandle, dstTrackId, primariesIndex, transferFunctionIndex, matrixIndex);
    }

    MP4SampleId sampleId = 0;
    MP4SampleId numSamples = MP4GetTrackNumberOfSamples(srcFile, srcTrackId);

    while (true) {
        sampleId++;
        if (sampleId > numSamples)
            break;

        bool rc = false;
        rc = MP4CopySample(srcFile,
                           srcTrackId,
                           sampleId,
                           fileHandle,
                           dstTrackId,
                           MP4_INVALID_DURATION);

        if (!rc) {
            MP4DeleteTrack(fileHandle, dstTrackId);
            MP4Close(srcFile);
            return MP4_INVALID_TRACK_ID;
        }
    }

    MP4Duration trackDuration = 0;
    uint32_t i = 1, trackEditCount = MP4GetTrackNumberOfEdits(srcFile, srcTrackId);
    while (i <= trackEditCount) {
        MP4Timestamp editMediaStart = MP4GetTrackEditMediaStart(srcFile, srcTrackId, i);
        MP4Duration editDuration = MP4ConvertFromMovieDuration(srcFile,
                                                               MP4GetTrackEditDuration(srcFile, srcTrackId, i),
                                                               MP4GetTimeScale(fileHandle));
        trackDuration += editDuration;
        int8_t editDwell = MP4GetTrackEditDwell(srcFile, srcTrackId, i);

        MP4AddTrackEdit(fileHandle, dstTrackId, i, editMediaStart, editDuration, editDwell);
        i++;
    }
    if (trackEditCount)
        MP4SetTrackIntegerProperty(fileHandle, dstTrackId, "tkhd.duration", trackDuration);
    else {
        uint32_t firstFrameOffset = MP4GetSampleRenderingOffset(fileHandle, dstTrackId, 1);
        MP4Duration editDuration = MP4ConvertFromTrackDuration(srcFile,
                                                               srcTrackId,
                                                               MP4GetTrackDuration(srcFile, srcTrackId),
                                                               MP4GetTimeScale(fileHandle));
        MP4AddTrackEdit(fileHandle, dstTrackId, MP4_INVALID_EDIT_ID, firstFrameOffset,
                        editDuration, 0);
    }
        

    MP4Close(srcFile);

    return dstTrackId;
}
