//
//  MP42SubtitleTrack.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MP42Utilities.h"
#import "SubUtilities.h"
#import "lang.h"

int muxMP4VideoTrack(MP4FileHandle fileHandle, NSString* filePath, MP4TrackId sourceTrackId)
{
    BOOL success = YES;
    MP4FileHandle sourceFileHandle;

    sourceFileHandle = MP4Read([filePath UTF8String], 0);
    MP4TrackId videoTrackId;

    success = videoTrackId = MP4CopyTrack(sourceFileHandle, sourceTrackId, fileHandle, YES, MP4_INVALID_TRACK_ID);

    MP4Close(sourceFileHandle);

    return success;
}
