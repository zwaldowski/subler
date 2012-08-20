//
//  NSRegularExpression+Subler.h
//  Subler
//
//  Created by Zachary Waldowski on 6/8/12.
//  Copyright 2009-2011 Damiano Galassi. All rights reserved.
//

@interface NSRegularExpression (Subler)

- (NSArray *)arrayBySeparatingMatchesInString:(NSString *)string;
- (NSDictionary *)dictionaryBySeparatingMatchesInString:(NSString *)string withKeys:(NSArray *)keys;

@end
