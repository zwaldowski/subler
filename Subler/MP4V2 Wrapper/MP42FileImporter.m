//
//  MP42FileImporter.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import "MP42FileImporter.h"
#import "MP42MkvImporter.h"
#import "MP42Mp4Importer.h"
#import "MP42SrtImporter.h"
#import "MP42CCImporter.h"
#import "MP42AC3Importer.h"
#import "MP42AACImporter.h"
#import "MP42H264Importer.h"
#import "MP42AVFImporter.h"

@implementation MP42Utilities (FileImporter)

+ (id <MP42FileImporter>)fileImporterForURL:(NSURL *)URL delegate:(id <MP42FileImporterDelegate>)del error:(NSError **)outError {
	if ([[URL pathExtension] caseInsensitiveCompare: @"mkv"] == NSOrderedSame ||
        [[URL pathExtension] caseInsensitiveCompare: @"mka"] == NSOrderedSame ||
        [[URL pathExtension] caseInsensitiveCompare: @"mks"] == NSOrderedSame)
		return [[MP42MkvImporter alloc] initWithFile: URL delegate: del error: outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"mp4"] == NSOrderedSame ||
             [[URL pathExtension] caseInsensitiveCompare: @"m4v"] == NSOrderedSame ||
             [[URL pathExtension] caseInsensitiveCompare: @"m4a"] == NSOrderedSame)
        return [[MP42Mp4Importer alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"srt"] == NSOrderedSame)
        return [[MP42SrtImporter alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"scc"] == NSOrderedSame)
        return [[MP42CCImporter alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"ac3"] == NSOrderedSame)
        return [[MP42AC3Importer alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"aac"] == NSOrderedSame)
        return [[MP42AACImporter alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"264"] == NSOrderedSame ||
             [[URL pathExtension] caseInsensitiveCompare: @"h264"] == NSOrderedSame)
        return [[MP42H264Importer alloc] initWithFile:URL delegate: del error:outError];
    else if ([[URL pathExtension] caseInsensitiveCompare: @"mov"] == NSOrderedSame)
        return [[MP42AVFImporter alloc] initWithFile:URL delegate: del error:outError];
	return nil;
}

@end