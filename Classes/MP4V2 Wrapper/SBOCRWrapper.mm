//
//  SBOcr.mm
//  Subler
//
//  Created by Damiano Galassi on 27/03/11.
//  Copyright 2011 Damiano Galassi. All rights reserved.
//

#import "SBOCRWrapper.h"

// Tesseract OCR
#include "tesseract/baseapi.h"
#include <iostream>
#include <string>
#include <cstdio>

#import "SBLanguages.h"

using namespace tesseract;

@interface SBOCRWrapper () {
    NSString *_language;
    TessBaseAPI _tessBaseAPI;
}

@end

@implementation SBOCRWrapper

- (NSURL*) appSupportUrl
{
    NSURL *URL = nil;

    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                            NSUserDomainMask,
                                                            YES);
    if ([allPaths count]) {
        NSString* path = [[allPaths lastObject] stringByAppendingPathComponent:@"Subler"];
        URL = [NSURL fileURLWithPath:path];

        if (URL) {
            return URL;
        }
    }

    return nil;

}

- (BOOL)tessdataAvailableForLanguage:(NSString*) language
{
    NSURL *URL = [self appSupportUrl];

    if (URL) {
        NSString* path = [[[URL path] stringByAppendingPathComponent:@"tessdata"] stringByAppendingFormat:@"/%@.traineddata", language];
        URL = [NSURL fileURLWithPath:path];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
            return YES;
        }
    }

    return NO;
}

+ (NSLock *)ocrLock {
	static dispatch_once_t onceToken;
	static NSLock *ocrLock = nil;
	dispatch_once(&onceToken, ^{
		ocrLock = [NSLock new];
	});
	return ocrLock;
}

- (id)init
{
    if ((self = [super init]))
    {
		
		NSString *path = [[NSBundle mainBundle] resourcePath];

		setenv("TESSDATA_PREFIX", [path UTF8String], 1);

		path = [path stringByAppendingPathComponent: @"tessdata/"];

		_tessBaseAPI.Init([path UTF8String], lang_for_english([_language UTF8String])->iso639_2, OEM_DEFAULT);
    }
    return self;
}

- (id) initWithLanguage: (NSString*) language
{
    if ((self = [super init]))
    {
        _language = [language retain];

        NSString * lang = [NSString stringWithUTF8String:lang_for_english([_language UTF8String])->iso639_2];
        NSURL *dataURL = [self appSupportUrl];
        if (![self tessdataAvailableForLanguage:lang]) {
            lang = @"eng";
            dataURL = [[NSBundle mainBundle] resourceURL];
        }

		setenv("TESSDATA_PREFIX", [dataURL.path UTF8String], 1);

		dataURL = [dataURL URLByAppendingPathComponent: @"tessdat" isDirectory:YES];

		_tessBaseAPI.Init(dataURL.path.UTF8String, lang.UTF8String, OEM_DEFAULT);
    }
    return self;
}

- (NSString*) performOCROnCGImage:(CGImageRef)cgImage {
    NSMutableString * text;

    size_t bytes_per_line   = CGImageGetBytesPerRow(cgImage);
    size_t bytes_per_pixel  = CGImageGetBitsPerPixel(cgImage) / 8.0;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);

    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    const UInt8 *imageData = CFDataGetBytePtr(data);

    
    // Tesseract is not multithreaded
    [[[self class] ocrLock] lock];
    char *string = _tessBaseAPI.TesseractRect(imageData,
											  bytes_per_pixel,
											  bytes_per_line,
											  0, 0,
											  width, height);
    [[[self class] ocrLock] unlock];
    CFRelease(data);

    if (string) {
        text = [NSMutableString stringWithUTF8String:string];
        if ([text characterAtIndex:[text length] -1] == '\n')
            [text replaceOccurrencesOfString:@"\n\n" withString:@"" options:nil range:NSMakeRange(0,[text length])];
    }
    else
        text = nil;

    delete[]string;

    return text;

}

- (void) dealloc {
    [_language release];
    [super dealloc];
}
@end
