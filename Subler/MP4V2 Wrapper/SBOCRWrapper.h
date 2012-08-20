//
//  SBOcr.h
//  Subler
//
//  Created by Damiano Galassi on 27/03/11.
//  Copyright 2011 Damiano Galassi. All rights reserved.
//

@interface SBOCRWrapper : NSObject

- (id) initWithLanguage: (NSString*) language;
- (NSString*) performOCROnCGImage:(CGImageRef)image;

@end
