//
//  MP4Metadata.h
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mp4v2.h"

@interface MP4Metadata : NSObject {
    NSString                *sourcePath;
    NSMutableDictionary     *tagsDict;
    NSImage                 *artwork;
    
    uint8_t mediaKind;
    uint8_t contentRating;
    uint8_t hdVideo;
    uint8_t gapless;
    BOOL edited;
}

- (id) initWithSourcePath:(NSString *)source;
- (void) readMetaData;
- (BOOL) writeMetadataWithFileHandle: (MP4FileHandle *) fileHandle;

@property(readonly) NSMutableDictionary    *tagsDict;
@property(readwrite, retain) NSImage                 *artwork;
@property(readwrite) uint8_t    mediaKind;
@property(readwrite) uint8_t    contentRating;
@property(readwrite) uint8_t    hdVideo;
@property(readwrite) uint8_t    gapless;
@property(readwrite) BOOL    edited;

@end
