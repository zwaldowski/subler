//
//  MP42MkvFileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import "MP42FileImporter.h"

@interface MP42MkvImporter : NSObject <MP42FileImporter> {

    struct MatroskaFile	*matroskaFile;
	struct StdIoStream  *ioStream;

    NSThread *dataReader;
    NSInteger readerStatus;
    
    NSMutableArray *activeTracks;
    NSMutableArray *samplesBuffer;
    
    CGFloat progress;
    u_int64_t fileDuration;
}

@end