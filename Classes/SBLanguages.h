//
//  SBLanguages.h
//  Subler
//
//  Created by Damiano Galassi on 13/08/12.
//
//

#import <Foundation/Foundation.h>

struct _ISO639Lang
{
    char * eng_name;        /* Description in English */
    char * native_name;     /* Description in native language */
    char * iso639_1;        /* ISO-639-1 (2 characters) code */
    char * iso639_2;        /* ISO-639-2/t (3 character) code */
    char * iso639_2b;       /* ISO-639-2/b code (if different from above) */
    short  qtLang;          /* QT Lang Code */

};

typedef struct _ISO639Lang *ISO639LangRef;

@interface SBLanguages : NSObject

+ (NSArray *)defaultLanguages;

+ (ISO639LangRef)languageForShortCode:(NSInteger)code;
+ (ISO639LangRef)languageForCode:(const char *)code;
+ (ISO639LangRef)languageForQTCode:(short)code;
+ (ISO639LangRef)languageForEnglishName:(NSString *)english;

+ (NSString *)englishNameForCode:(const char *)code;

+ (NSString *)codeForEnglishName:(NSString *)english;
+ (NSString *)shortCodeForEnglishName:(NSString *)english;

+ (NSInteger)shortCodeForLanguage:(ISO639LangRef)lang;

@end
