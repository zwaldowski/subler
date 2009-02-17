//
//  SubMuxer.h
//  Subler
//
//  Created by Damiano Galassi on 29/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SubUtilities.h"
#include "MP4Utilities.h"

int muxSubtitleTrack(MP4FileHandle fileHandle, NSString* subtitlePath, const char* lang, uint16_t subtitleHeight, int16_t delay);
