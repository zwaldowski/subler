//
//  MP42ChapterTrack.h
//  Subler
//
//  Created by Damiano Galassi on 06/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MP42Track.h"

@interface MP42ChapterTrack : MP42Track {
    NSMutableArray *chapters;
}
-(id)initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID;

@property (readwrite, retain) NSMutableArray * chapters;

@end