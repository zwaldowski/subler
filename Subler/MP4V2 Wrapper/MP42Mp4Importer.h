//
//  MP42MkvFileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import "MP42FileImporter.h"
#import "MP42File.h"

@interface MP42Mp4Importer : NSObject <MP42FileImporter, MP42FileDelegate> {
    MP4FileHandle  fileHandle;

    NSThread *dataReader;
    NSInteger readerStatus;

    NSMutableArray *activeTracks;
    NSMutableArray *samplesBuffer;
    
    CGFloat progress;
}

@end