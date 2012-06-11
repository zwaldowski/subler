#define uint32 CSSM_uint32
#import "UniversalDetector.h"
#undef uint32

#import "nscore.h"
#import "nsUniversalDetector.h"
#import "nsCharSetProber.h"

class wrappedUniversalDetector:public nsUniversalDetector
{
	public:
	void Report(const char* aCharset) {}

	const char *charset(float &confidence)
	{
		if(!mGotData)
		{
			confidence=0;
			return 0;
		}

		if(mDetectedCharset)
		{
			confidence=1;
			return mDetectedCharset;
		}

		switch(mInputState)
		{
			case eHighbyte:
			{
				float proberConfidence;
				float maxProberConfidence = (float)0.0;
				PRInt32 maxProber = 0;

				for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
				{
					proberConfidence = mCharSetProbers[i]->GetConfidence();
					if (proberConfidence > maxProberConfidence)
					{
						maxProberConfidence = proberConfidence;
						maxProber = i;
					}
				}

				confidence=maxProberConfidence;
				return mCharSetProbers[maxProber]->GetCharSetName();
			}
			break;

			case ePureAscii:
				confidence=0;
				return "US-ASCII";
			break;
				
			case eEscAscii:
				confidence=0;
				return 0;
				break;
		}
	}

	bool done()
	{
		if(mDetectedCharset) return true;
		return false;
	}
    
    void debug()
    {
        for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
        {
            // If no data was received the array might stay filled with nulls
            // the way it was initialized in the constructor.
            if (mCharSetProbers[i])
                mCharSetProbers[i]->DumpStatus();
        }
    }

	void reset() { Reset(); }
};

@interface UniversalDetector () {
	wrappedUniversalDetector *detector;
	NSString *charset;
	float confidence;
}

@end

@implementation UniversalDetector

-(id)init
{
	if(self=[super init])
	{
		detector=new wrappedUniversalDetector;
	}
	return self;
}

-(void)dealloc
{
	delete detector;
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	if (detector->done()) return;
	detector->HandleData(data,len);
}

-(void)reset
{
	detector->reset();
}

-(BOOL)done
{
	return detector->done()?YES:NO;
}

-(NSString *)MIMECharset
{
	if(!charset)
	{
		const char *cstr=detector->charset(confidence);
		if (!cstr) return nil;
		charset=[[NSString alloc] initWithUTF8String:cstr];
	}
	return charset;
}

-(NSStringEncoding)encoding
{
	NSString *mimecharset=[self MIMECharset];
	if(!mimecharset) return 0;
	CFStringEncoding cfenc=CFStringConvertIANACharSetNameToEncoding((CFStringRef)mimecharset);
	if(cfenc==kCFStringEncodingInvalidId) return 0;
	return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

-(float)confidence
{
	if(!charset) [self MIMECharset];
	return confidence;
}

-(void)debugDump
{
    return detector->debug();
}

@end
