#import <Cocoa/Cocoa.h>

#define UniversalDetector SubUniversalDetector

@interface UniversalDetector:NSObject

-(void)analyzeData:(NSData *)data;
-(void)analyzeBytes:(const char *)data length:(int)len;
-(void)reset;

-(BOOL)done;
-(NSString *)MIMECharset;
-(NSStringEncoding)encoding;
-(float)confidence;

-(void)debugDump;

@end
