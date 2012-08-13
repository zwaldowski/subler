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

NSLock *ocrLock;

using namespace tesseract;

class OCRWrapper {
public:
OCRWrapper(const char* lang) {
    NSString * path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingString:@"/Contents/Resources/"];

    setenv("TESSDATA_PREFIX", [path UTF8String], 1);

    path = [path stringByAppendingString:@"tessdata/"];

    tess_base_api.Init([path UTF8String], lang, OEM_DEFAULT);
}
char* OCRFrame(const unsigned char *image, int bytes_per_pixel, int bytes_per_line, int width, int height) {
    char* text = tess_base_api.TesseractRect(image,
                                             bytes_per_pixel,
                                             bytes_per_line,
                                             0, 0,
                                             width, height);
    return text;
}

protected:
    TessBaseAPI tess_base_api;
};

@implementation SBOCRWrapper

- (id)init
{
    if ((self = [super init]))
    {
        if (ocrLock == nil)
            ocrLock = [[NSLock alloc] init];

        tess_base = (void *)new OCRWrapper(lang_for_english([_language UTF8String])->iso639_2);
    }
    return self;
}

- (id) initWithLanguage: (NSString*) language
{
    if ((self = [super init]))
    {
        _language = [language retain];
        if (ocrLock == nil)
            ocrLock = [[NSLock alloc] init];

        NSString * lang = [NSString stringWithUTF8String:lang_for_english([_language UTF8String])->iso639_2];        
        NSString * path = [[NSBundle mainBundle] resourcePath];
        path = [path stringByAppendingFormat:@"/tessdata/%@.traineddata", lang];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            lang = @"eng";

        tess_base = (void *)new OCRWrapper([lang UTF8String]);
    }
    return self;
}

- (NSString*) performOCROnCGImage:(CGImageRef)cgImage {
    NSMutableString * text;

    OCRWrapper *ocr = (OCRWrapper *)tess_base;
    size_t bytes_per_line   = CGImageGetBytesPerRow(cgImage);
    size_t bytes_per_pixel  = CGImageGetBitsPerPixel(cgImage) / 8.0;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);

    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    const UInt8 *imageData = CFDataGetBytePtr(data);

    
    // Tesseract is not multithreaded
    [ocrLock lock];
    char* string = ocr->OCRFrame(imageData,
                                 bytes_per_pixel,
                                 bytes_per_line,
                                 width,
                                 height);
    [ocrLock unlock];
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
    OCRWrapper *ocr = (OCRWrapper *)tess_base;
    delete ocr;

    [_language release];
    [ocrLock release];
    [super dealloc];
}
@end
