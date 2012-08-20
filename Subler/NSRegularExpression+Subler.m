//
//  NSRegularExpression+Subler.m
//  Subler
//
//  Created by Zachary Waldowski on 6/8/12.
//  Copyright 2009-2011 Damiano Galassi. All rights reserved.
//

#import "NSRegularExpression+Subler.h"

@implementation NSRegularExpression (Subler)

- (NSArray *)arrayBySeparatingMatchesInString:(NSString *)string {
	NSMutableArray *ret = [NSMutableArray array];
    NSRange area = NSMakeRange(0, string.length);
	__block NSUInteger pos = 0;
	
	[self enumerateMatchesInString: string options: 0 range: area usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		NSRange substrRange = NSMakeRange(pos, result.range.location - pos);
		[ret addObject: [string substringWithRange: substrRange]];
		pos = NSMaxRange(result.range);
	}];
	
	if (pos < string.length) {
		[ret addObject: [string substringFromIndex: pos]];
	}
	
	return ret;
}

- (NSDictionary *)dictionaryBySeparatingMatchesInString:(NSString *)string withKeys:(NSArray *)keys
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: keys.count];
    NSRange area = NSMakeRange(0, string.length);
	__block NSUInteger pos = 0;
	__block NSUInteger idx = 0;
	
	[self enumerateMatchesInString: string options: 0 range: area usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		NSRange substrRange = NSMakeRange(pos, result.range.location - pos);
		
		NSString *key = [keys objectAtIndex: idx];
		
		if (key.length) {
			NSString *value = [string substringWithRange: substrRange];
			[dict setObject: value forKey: key];
		}
		
		pos = NSMaxRange(result.range);
		idx++;
		
		if (idx == keys.count)
			*stop = YES;
	}];
	
	return dict;
}

@end
