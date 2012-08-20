/*
 *  MP42Utilities.h
 *  Subler
 *
 *  Created by Damiano Galassi on 30/01/09.
 *  Copyright 2009 Damiano Galassi. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#include "mp4v2.h"

extern NSString * const SBMonoMixdown;
extern NSString * const SBStereoMixdown;
extern NSString * const SBDolbyMixdown;
extern NSString * const SBDolbyPlIIMixdown;

typedef enum {  TRACK_DISABLED = 0x0,
    TRACK_ENABLED = 0x1,
    TRACK_IN_MOVIE = 0x2,
    TRACK_IN_PREVIEW = 0x4,
    TRACK_IN_POSTER = 0x8
} track_header_flags;

NSString* SRTStringFromTime( long long time, long timeScale , const char separator);
NSString* SMPTEStringFromTime(long long time, long timeScale);
MP4Duration TimeFromSMPTEString( NSString* SMPTE_string, MP4Duration timeScale );

int enableTrack(MP4FileHandle fileHandle, MP4TrackId trackId);
int disableTrack(MP4FileHandle fileHandle, MP4TrackId trackId);

int enableFirstSubtitleTrack(MP4FileHandle fileHandle);
int enableFirstAudioTrack(MP4FileHandle fileHandle);
int updateTracksCount(MP4FileHandle fileHandle);
void updateMoovDuration(MP4FileHandle fileHandle);

MP4TrackId findChapterTrackId(MP4FileHandle fileHandle);
void removeAllChapterTrackReferences(MP4FileHandle fileHandle);
MP4TrackId findFirstVideoTrack(MP4FileHandle fileHandle);

uint16_t getFixedVideoWidth(MP4FileHandle fileHandle, MP4TrackId videoTrack);

NSString* getTrackName(MP4FileHandle fileHandle, MP4TrackId videoTrack);
NSString* getHumanReadableTrackMediaDataName(MP4FileHandle fileHandle, MP4TrackId videoTrack);
NSString* getHumanReadableTrackLanguage(MP4FileHandle fileHandle, MP4TrackId videoTrack);
NSString* getFilenameLanguage(CFStringRef filename);

uint8_t *CreateEsdsFromSetupData(uint8_t *codecPrivate, size_t vosLen, size_t *esdsLen, int trackID, bool audio, bool write_version);
ComponentResult ReadESDSDescExt(void* descExt, UInt8 **buffer, int *size, int versionFlags);
CFDataRef createDescExt_XiphVorbis(UInt32 codecPrivateSize, const void * codecPrivate);
CFDataRef createDescExt_XiphFLAC(UInt32 codecPrivateSize, const void * codecPrivate);

int readAC3Config(uint64_t acmod, uint64_t lfeon, UInt32 *channelsCount, UInt32 *channelLayoutTag);

BOOL isTrackMuxable(NSString * formatName);
BOOL trackNeedConversion(NSString * formatName);

int64_t getTrackStartOffset(MP4FileHandle fileHandle, MP4TrackId Id);
void setTrackStartOffset(MP4FileHandle fileHandle, MP4TrackId Id, int64_t offset);
int copyTrackEditLists (MP4FileHandle fileHandle, MP4TrackId srcTrackId, MP4TrackId dstTrackId);

NSError* MP42Error(NSString *description, NSString* recoverySuggestion, NSInteger code);
int yuv2rgb(int yuv);
int rgb2yuv(int rgb);

void *fast_realloc_with_padding(void *ptr, unsigned int *size, unsigned int min_size);
void DecompressZlib(uint8_t **codecData, unsigned int *bufferSize, uint8_t *sampleData, uint64_t sampleSize);
