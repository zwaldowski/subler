//
//  SBAudioConverter.h
//  Subler
//
//  Created by Damiano Galassi on 16/09/10.
//  Copyright 2010 Damiano Galassi. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudio.h>

#include "sfifo.h"
#include "downmix.h"

@class MP42SampleBuffer;
@class MP42AudioTrack;

extern NSString * const SBMonoMixdown;
extern NSString * const SBStereoMixdown;
extern NSString * const SBDolbyMixdown;
extern NSString * const SBDolbyPlIIMixdown;

@interface SBAudioIOData : NSObject

@property (nonatomic) AudioConverterRef				converter;
@property (nonatomic) AudioStreamBasicDescription	inputFormat;
@property (nonatomic) AudioStreamBasicDescription	outputFormat;

@property (nonatomic) sfifo_t						*fifo;

@property (nonatomic) NSUInteger					pos;
@property (nonatomic, strong) NSMutableData			*srcBuffer;
@property (nonatomic) UInt32						srcSizePerPacket;
@property (nonatomic) UInt32						numPacketsPerRead;
@property (nonatomic) AudioStreamBasicDescription	srcFormat;
@property (nonatomic) AudioStreamPacketDescription	*pktDescs;

@property (nonatomic, strong) NSMutableArray		*inputSamplesBuffer;
@property (nonatomic, strong) NSMutableArray		*outputSamplesBuffer;

@property (nonatomic, strong) MP42SampleBuffer		*sample;
@property (nonatomic) BOOL							fileReaderDone;

@end

@interface SBAudioConverter : NSObject {
    NSThread *decoderThread;
    NSThread *encoderThread;

    unsigned char *buffer;
    int bufferSize;
    sfifo_t fifo;

    BOOL readerDone;
    BOOL encoderDone;

    NSUInteger  trackId;
    Float64     sampleRate;
    NSUInteger  inputChannelsCount;
    NSUInteger  outputChannelCount;
    NSUInteger  downmixType;
    NSUInteger  layout;
    hb_chan_map_t *ichanmap;

    NSMutableArray * inputSamplesBuffer;
    NSMutableArray * outputSamplesBuffer;
    NSData * outputMagicCookie;

    SBAudioIOData *decoderData;
    SBAudioIOData *encoderData;
}

- (id) initWithTrack: (MP42AudioTrack*) track andMixdownType: (NSString*) mixdownType error:(NSError **)outError;
- (void) setOutputTrack: (NSUInteger) outputTrackId;
- (void) addSample: (MP42SampleBuffer*)sample;
- (MP42SampleBuffer*) copyEncodedSample;

- (NSData*) magicCookie;
- (BOOL) needMoreSample;

- (BOOL) encoderDone;
- (void) setDone:(BOOL)status;

@end