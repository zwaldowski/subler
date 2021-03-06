//
//  MP42Track.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import "MP42Track.h"
#import "MP42Utilities.h"
#import "SBLanguages.h"

@implementation MP42Track

-(id)init
{
    if ((self = [super init]))
    {
        enabled = YES;
        updatedProperty = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id)initWithSourceURL:(NSURL *)URL trackID:(NSInteger)trackID fileHandle:(MP4FileHandle)fileHandle
{
	if ((self = [super init]))
	{
		sourceURL = URL;
		Id = trackID;
        isEdited = NO;
        muxed = YES;
        updatedProperty = [[NSMutableDictionary alloc] init];

        if (fileHandle) {
            format = getHumanReadableTrackMediaDataName(fileHandle, Id);
            name = getTrackName(fileHandle, Id);
            language = getHumanReadableTrackLanguage(fileHandle, Id);
            bitrate = MP4GetTrackBitRate(fileHandle, Id);
            duration = MP4ConvertFromTrackDuration(fileHandle, Id,
                                                   MP4GetTrackDuration(fileHandle, Id),
                                                   MP4_MSECS_TIME_SCALE);
            timescale = MP4GetTrackTimeScale(fileHandle, Id);
            startOffset = getTrackStartOffset(fileHandle, Id);

            uint64_t temp;
            MP4GetTrackIntegerProperty(fileHandle, Id, "tkhd.flags", &temp);
            if (temp & TRACK_ENABLED) enabled = YES;
            else enabled = NO;
            MP4GetTrackIntegerProperty(fileHandle, Id, "tkhd.alternate_group", &alternate_group);
        }
	}

    return self;
}

- (BOOL) writeToFile:(MP4FileHandle)fileHandle error:(NSError **)outError
{
    BOOL success = YES;
    if (!fileHandle || !Id) {
        if ( outError != NULL) {
            *outError = MP42Error(@"Failed to modify track",
                                  nil,
                                  120);
            return NO;

        }
    }

    if ([updatedProperty valueForKey:@"name"]  || !muxed)
        if (![name isEqualToString:@"Video Track"] &&
            ![name isEqualToString:@"Sound Track"] &&
            ![name isEqualToString:@"Subtitle Track"] &&
            ![name isEqualToString:@"Text Track"] &&
            ![name isEqualToString:@"Chapter Track"] &&
            ![name isEqualToString:@"Unknown Track"] &&
            name != nil) {
            const char* cString = [name cStringUsingEncoding: NSMacOSRomanStringEncoding];
            if (cString)
                MP4SetTrackName(fileHandle, Id, cString);
        }
    if ([updatedProperty valueForKey:@"alternate_group"] || !muxed)
        MP4SetTrackIntegerProperty(fileHandle, Id, "tkhd.alternate_group", alternate_group);
    if ([updatedProperty valueForKey:@"start_offset"])
        setTrackStartOffset(fileHandle, Id, startOffset);
    if ([updatedProperty valueForKey:@"language"] || !muxed)
        MP4SetTrackLanguage(fileHandle, Id, [[SBLanguages codeForEnglishName: language] UTF8String]);
    if ([updatedProperty valueForKey:@"enabled"] || !muxed) {
        if (enabled) enableTrack(fileHandle, Id);
        else disableTrack(fileHandle, Id);
    }

    return success;
}


- (NSString *) timeString
{
        return SMPTEStringFromTime(duration, 1000);
}

@synthesize sourceURL;
@synthesize Id;
@synthesize sourceId;
@synthesize sourceFileHandle;

@synthesize format;
@synthesize sourceFormat;
@synthesize name;

- (NSString *) name {
    return name;
}

- (void) setName: (NSString *) newName
{
    name = newName;
    isEdited = YES;
    [updatedProperty setValue:@"True" forKey:@"name"];
}

- (NSString *) language {
    return language;
}

- (void) setLanguage: (NSString *) newLang
{
    language = newLang;
    isEdited = YES;
    [updatedProperty setValue:@"True" forKey:@"language"];
}

- (BOOL) enabled {
    return enabled;
}

- (void) setEnabled: (BOOL) newState
{
    enabled = newState;
    isEdited = YES;
    [updatedProperty setValue:@"True" forKey:@"enabled"];
}

- (uint64_t) alternate_group {
    return alternate_group;
}

- (void) setAlternate_group: (uint64_t) newGroup
{
    alternate_group = newGroup;
    isEdited = YES;
    [updatedProperty setValue:@"True" forKey:@"alternate_group"];
}

- (int64_t) startOffset {
    return startOffset;
}

- (void) setStartOffset:(int64_t)newOffset
{
    startOffset = newOffset;
    isEdited = YES;
    [updatedProperty setValue:@"True" forKey:@"start_offset"];
    
}

- (NSString *) formatSummary
{
    return format;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:1 forKey:@"MP42TrackVersion"];

    [coder encodeInt64:Id forKey:@"Id"];
    [coder encodeInt64:sourceId forKey:@"sourceId"];

    [coder encodeObject:sourceURL forKey:@"sourceURL"];
    [coder encodeObject:sourceFormat forKey:@"sourceFormat"];
    [coder encodeObject:format forKey:@"format"];
    [coder encodeObject:name forKey:@"name"];
    [coder encodeObject:language forKey:@"language"];

    [coder encodeBool:enabled forKey:@"enabled"];

    [coder encodeInt64:alternate_group forKey:@"alternate_group"];
    [coder encodeInt64:startOffset forKey:@"startOffset"];

    [coder encodeBool:isEdited forKey:@"isEdited"];
    [coder encodeBool:muxed forKey:@"muxed"];
    [coder encodeBool:needConversion forKey:@"needConversion"];

    [coder encodeInt32:timescale forKey:@"timescale"];
    [coder encodeInt32:bitrate forKey:@"bitrate"];
    [coder encodeInt64:duration forKey:@"duration"];

    [coder encodeObject:updatedProperty forKey:@"updatedProperty"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];

    Id = [decoder decodeInt64ForKey:@"Id"];
    sourceId = [decoder decodeInt64ForKey:@"sourceId"];

    sourceURL = [decoder decodeObjectForKey:@"sourceURL"];
    sourceFormat = [decoder decodeObjectForKey:@"sourceFormat"];
    format = [decoder decodeObjectForKey:@"format"];
    name = [decoder decodeObjectForKey:@"name"];
    language = [decoder decodeObjectForKey:@"language"];

    enabled = [decoder decodeBoolForKey:@"enabled"];

    alternate_group = [decoder decodeInt64ForKey:@"alternate_group"];
    startOffset = [decoder decodeInt64ForKey:@"startOffset"];

    isEdited = [decoder decodeBoolForKey:@"isEdited"];
    muxed = [decoder decodeBoolForKey:@"muxed"];
    needConversion = [decoder decodeBoolForKey:@"needConversion"];

    timescale = [decoder decodeInt32ForKey:@"timescale"];
    bitrate = [decoder decodeInt32ForKey:@"bitrate"];
    duration = [decoder decodeInt64ForKey:@"duration"];

    updatedProperty = [decoder decodeObjectForKey:@"updatedProperty"];

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Track: %d, %@, %@, %@", [self Id], [self name], [self timeString], [self format]];
}

@synthesize timescale;
@synthesize bitrate;
@synthesize duration;
@synthesize isEdited;
@synthesize muxed;
@synthesize needConversion;

@synthesize updatedProperty;

@synthesize trackImporterHelper;
@synthesize trackDemuxerHelper;
@synthesize trackConverterHelper;

@end
