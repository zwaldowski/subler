//
//  SBLanguages.m
//  Subler
//
//  Created by Damiano Galassi on 13/08/12.
//
//

#import "SBLanguages.h"

NSString *const SBLanguageEnglishNameKey = @"englishName";
NSString *const SBLanguageNativeNameKey = @"nativeName";
NSString *const SBLanguageISO_639_1Key = @"iso639_1";
NSString *const SBLanguageISO_639_2Key = @"iso639_2";
NSString *const SBLanguageISO_639_2BKey = @"iso639_2b";
NSString *const SBLanguageQTCodeKey = @"qtLang";

@implementation SBLanguages

+ (NSDictionary *)languages {
	static dispatch_once_t onceToken;
	static NSDictionary *languages = nil;
	dispatch_once(&onceToken, ^{
		NSURL *URL = [[NSBundle mainBundle] URLForResource: @"languages" withExtension: @"plist"];
		languages = [NSDictionary dictionaryWithContentsOfURL: URL];
	});
	return languages;
}

+ (NSArray *)languageNames {
	static dispatch_once_t onceToken;
	static NSArray *languagesArray = nil;
	dispatch_once(&onceToken, ^{
		NSMutableArray *otherLanguages = [[[self languages] keysSortedByValueUsingSelector: @selector(compare:)] mutableCopy];

		NSURL *URL = [[NSBundle mainBundle] URLForResource: @"topLanguages" withExtension: @"plist"];
		NSMutableArray *topLanguages = [NSMutableArray arrayWithContentsOfURL: URL];

		[otherLanguages removeObjectsInArray: topLanguages];

		[topLanguages addObjectsFromArray: otherLanguages];

		languagesArray = [topLanguages copy];

		[otherLanguages release];
	});
	return languagesArray;
}

+ (NSDictionary *)languageForShortCode:(NSInteger)code {
	__block NSString *retKey = nil;

    char code_string[2];
    code_string[0] = tolower( ( code >> 8 ) & 0xFF );
    code_string[1] = tolower( code & 0xFF );
	NSString *codeString = [NSString stringWithUTF8String: code_string];

	[[self languages] enumerateKeysAndObjectsUsingBlock:^(NSString *englishName, NSDictionary *obj, BOOL *stop) {
		if ([[obj objectForKey: SBLanguageISO_639_1Key] isEqualToString: codeString]) {
			retKey = englishName;
			*stop = YES;
		}
	}];

	return [self languageForEnglishName: retKey];
}

+ (NSDictionary *)languageForCode:(const char *)code {
	__block NSString *retKey = nil;
	NSString *codeString = [NSString stringWithUTF8String: code];
	[[self languages] enumerateKeysAndObjectsUsingBlock:^(NSString *englishName, NSDictionary *obj, BOOL *stop) {
		if ([[obj objectForKey: SBLanguageISO_639_2Key] isEqualToString: codeString] || [[obj objectForKey: SBLanguageISO_639_2BKey] isEqualToString: codeString]) {
			retKey = englishName;
			*stop = YES;
		}
	}];

	return [self languageForEnglishName: retKey];
}

+ (NSDictionary *)languageForQTCode:(short)code {
	__block NSString *retKey = nil;
	
	[[self languages] enumerateKeysAndObjectsUsingBlock:^(NSString *englishName, NSDictionary *obj, BOOL *stop) {
		if ([[obj objectForKey: SBLanguageQTCodeKey] shortValue] == code) {
			retKey = englishName;
			*stop = YES;
		}
	}];

	return [self languageForEnglishName: retKey];
}

+ (NSDictionary *)languageForEnglishName:(NSString *)code {
	if (!code)
		return nil;
	NSMutableDictionary *dict = [[[self languages] objectForKey: code] mutableCopy];
	[dict setObject: code forKey: SBLanguageEnglishNameKey];
	return [dict autorelease];
}

+ (NSString *)englishNameForCode:(const char *)code {
	return [[self languageForCode: code] objectForKey: SBLanguageEnglishNameKey];
}

+ (NSString *)codeForEnglishName:(NSString *)english {
	return [[[self languages] objectForKey: english] objectForKey: SBLanguageISO_639_2Key];
}

+ (NSString *)shortCodeForEnglishName:(NSString *)english {
	return [[[self languages] objectForKey: english] objectForKey: SBLanguageISO_639_1Key];
}

@end
