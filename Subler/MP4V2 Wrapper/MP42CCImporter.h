//
//  MP42CCFileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 05/12/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import "MP42FileImporter.h"

@interface MP42CCImporter : NSObject <MP42FileImporter> {
    NSThread *dataReader;
    NSInteger readerStatus;

    NSMutableArray *samplesBuffer;
    NSMutableArray *activeTracks;
}

@end