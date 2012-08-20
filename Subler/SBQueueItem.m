//
//  SBQueueItem.m
//  Subler
//
//  Created by Damiano Galassi on 16/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SBQueueItem.h"
#import "MP42File.h"

@implementation SBQueueItem

@synthesize attributes;
@synthesize URL = fileURL;
@synthesize destURL;
@synthesize mp4File;
@synthesize status;

- (id)initWithURL:(NSURL*)URL {
    self = [super init];
    if (self) {
        fileURL = URL;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        unsigned long long originalFileSize = [[[fileManager attributesOfItemAtPath:[fileURL path] error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
        if (originalFileSize > 4257218560) {
            attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], MP42Create64BitData, nil];
        }
    }

    return self;
}

- (id)initWithMP4:(MP42File*)MP4 {
    self = [super init];
    if (self) {
        mp4File = MP4;

        if ([MP4 URL])
            fileURL = [MP4 URL];
        else {
            for (NSUInteger i = 0; i < [mp4File tracksCount]; i++) {
                MP42Track *track = [mp4File trackAtIndex:i];
                if ([track sourceURL]) {
                    fileURL = [track sourceURL];
                    break;
                }
            }
        }

        status = SBQueueItemStatusReady;
    }

    return self;
}

- (id)initWithMP4:(MP42File*)MP4 url:(NSURL*)URL attributes:(NSDictionary*)dict
{
    if (self = [super init])
    {
        mp4File = MP4;
        fileURL = URL;
        destURL = URL;
        attributes = dict;

        status = SBQueueItemStatusReady;
    }

    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:1 forKey:@"SBQueueItemTagEncodeVersion"];

    [coder encodeObject:mp4File forKey:@"SBQueueItemMp4File"];
    [coder encodeObject:fileURL forKey:@"SBQueueItemFileURL"];
    [coder encodeObject:destURL forKey:@"SBQueueItemDestURL"];
    [coder encodeObject:attributes forKey:@"SBQueueItemAttributes"];

    [coder encodeInt:status forKey:@"SBQueueItemStatus"];
    [coder encodeInt:humanEdited forKey:@"SBQueueItemHumanEdited"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];

    mp4File = [decoder decodeObjectForKey:@"SBQueueItemMp4File"];

    fileURL = [decoder decodeObjectForKey:@"SBQueueItemFileURL"];
    destURL = [decoder decodeObjectForKey:@"SBQueueItemDestURL"];
    attributes = [decoder decodeObjectForKey:@"SBQueueItemAttributes"];

    status = [decoder decodeIntForKey:@"SBQueueItemStatus"];
    humanEdited = [decoder decodeIntForKey:@"SBQueueItemHumanEdited"];

    return self;
}

@end
