//
//  MP4TrackWrapper.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mp4v2/mp4v2.h"

@interface MP4TrackWrapper : NSObject {
    MP4TrackId  trackId;
	NSString    *trackSourcePath;
	NSString    *trackFormat;
    NSString    *trackName;
    NSString    *trackMedia;
    NSString    *language;
    BOOL        hasChanged;
    BOOL        muxed;
	
	int samplerate; 
	double bitrate;     // kbit/sec
	double duration;    // seconds
}

@property (readwrite, retain) NSString * trackSourcePath;
@property (readwrite) MP4TrackId trackId;
@property (readwrite, retain) NSString *trackFormat;
@property (readwrite, retain) NSString *trackName;
@property (readwrite, retain) NSString *trackMedia;
@property (readwrite, retain) NSString *language;

@property (readonly) int samplerate;
@property (readonly) double bitrate;
@property (readonly) double duration;
@property(readwrite) BOOL hasChanged;
@property(readwrite) BOOL muxed;

-(id)initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID;
-(void)readTrackType;

@end
