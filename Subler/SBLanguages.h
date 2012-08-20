//
//  SBLanguages.h
//  Subler
//
//  Created by Damiano Galassi on 13/08/12.
//

#import <Foundation/Foundation.h>

extern NSString *const SBLanguageEnglishNameKey;
extern NSString *const SBLanguageNativeNameKey;
extern NSString *const SBLanguageISO_639_1Key;
extern NSString *const SBLanguageISO_639_2Key;
extern NSString *const SBLanguageISO_639_2BKey;
extern NSString *const SBLanguageQTCodeKey;

@interface SBLanguages : NSObject

+ (NSDictionary *)languages;
+ (NSArray *)languageNames;

+ (NSDictionary *)languageForShortCode:(NSInteger)code;
+ (NSDictionary *)languageForCode:(const char *)code;
+ (NSDictionary *)languageForQTCode:(short)code;
+ (NSDictionary *)languageForEnglishName:(NSString *)code;

+ (NSString *)englishNameForCode:(const char *)code;
+ (NSString *)codeForEnglishName:(NSString *)english;
+ (NSString *)shortCodeForEnglishName:(NSString *)english;

@end
