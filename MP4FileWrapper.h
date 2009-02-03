//
//  MP4FileWrapper.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mp4v2/mp4v2.h"
#import "MP4TrackWrapper.h"
#import "MP4SubtitleTrackWrapper.h"

@interface MP4FileWrapper : NSObject {

    MP4FileHandle fileHandle;
    
    NSMutableArray *tracksArray;
    NSMutableArray *tracksToBeDeleted;
}

@property (readonly) NSMutableArray *tracksArray;
@property (readonly) NSMutableArray *tracksToBeDeleted;

-(id)initWithExistingMP4File:(NSString *)mp4File;
- (int)tracksCount;


@end
