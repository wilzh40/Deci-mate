//
//  AudioMeter.m
//  
//
//  Created by Wilson Zhao on 7/11/15.
//
//

#import "AudioMeter.h"
#import "mo_audio.h" //stuff that helps set up low-level audio
#import "FFTHelper.h"
//#import  "EAGLView.h"
#import <aubio/aubio.h>
#include <iostream>

#define SAMPLE_RATE 44100  //22050 //44100 //
//Valued sampled per second
#define FRAMESIZE  512
#define NUMCHANNELS 2

#define kOutputBus 0
#define kInputBus 1



/// Nyquist Maximum Frequency
const Float32 NyquistMaxFreq = SAMPLE_RATE/2.0;

/// caculates HZ value for specified index from a FFT bins vector
Float32 frequencyHerzValue(long frequencyIndex, long fftVectorSize, Float32 nyquistFrequency ) {
    return ((Float32)frequencyIndex/(Float32)fftVectorSize) * nyquistFrequency;
}



// The Main FFT Helper
FFTHelperRef *fftConverter = NULL;
// Reference to self
id thisClass;




//Accumulator Buffer=====================

UInt32 accumulatorDataLenght = 131072;  //16384; //32768; 65536; 131072;
UInt32 accumulatorFillIndex = 0;
Float32 *dataAccumulator = nil;
static void initializeAccumulator(int length) {
    dataAccumulator = (Float32*) malloc(sizeof(Float32)*length);
    accumulatorFillIndex = 0;
}
static void destroyAccumulator() {
    if (dataAccumulator!=NULL) {
        free(dataAccumulator);
        dataAccumulator = NULL;
    }
    accumulatorFillIndex = 0;
}

static BOOL accumulateFrames(Float32 *frames, UInt32 lenght) { //returned YES if full, NO otherwise.
    //    float zero = 0.0;
    //    vDSP_vsmul(frames, 1, &zero, frames, 1, lenght);
    
    if (accumulatorFillIndex>=accumulatorDataLenght) { return YES; } else {
        memmove(dataAccumulator+accumulatorFillIndex, frames, sizeof(Float32)*lenght);
        accumulatorFillIndex = accumulatorFillIndex+lenght;
        if (accumulatorFillIndex>=accumulatorDataLenght) { return YES; }
    }
    return NO;
}

static void emptyAccumulator(int length) {
    accumulatorFillIndex = 0;
    memset(dataAccumulator, 0, sizeof(Float32)*length);
}
//=======================================


//==========================Window Buffer
const UInt32 windowLength = accumulatorDataLenght;
Float32 *windowBuffer= NULL;
//=======================================



/// max value from vector with value index (using Accelerate Framework)
static Float32 vectorMaxValueACC32_index(Float32 *vector, unsigned long size, long step, unsigned long *outIndex) {
    Float32 maxVal;
    vDSP_maxvi(vector, step, &maxVal, outIndex, size);
    return maxVal;
}




///returns HZ of the strongest frequency.
static Float32 strongestFrequencyHZ(Float32 *buffer, FFTHelperRef *fftHelper, UInt32 frameSize, Float32 *freqValue) {
    Float32 *fftData = computeFFT(fftHelper, buffer, frameSize);
    fftData[0] = 0.0;
    unsigned long length = frameSize/2.0;
    Float32 max = 0;
    unsigned long maxIndex = 0;
    max = vectorMaxValueACC32_index(fftData, length, 1, &maxIndex);
    if (freqValue!=NULL) { *freqValue = max; }
    Float32 HZ = frequencyHerzValue(maxIndex, length, NyquistMaxFreq);
    return HZ;
}



__weak UILabel *labelToUpdate = nil;

#pragma mark MAIN CALLBACK
void AudioCallback( Float32 * buffer, UInt32 frameSize, void * userData )
{
    
    
    //take only data from 1 channel
    Float32 zero = 0.0;
    vDSP_vsadd(buffer, 2, &zero, buffer, 1, frameSize*NUMCHANNELS);
    
    
    
    if (accumulateFrames(buffer, frameSize)==YES) { //if full
        
        
        
        
        
        
        //windowing the time domain data before FFT (using Blackman Window)
        if (windowBuffer==NULL) { windowBuffer = (Float32*) malloc(sizeof(Float32)*windowLength); }
        vDSP_blkman_window(windowBuffer, windowLength, 0);
        vDSP_vmul(dataAccumulator, 1, windowBuffer, 1, dataAccumulator, 1, accumulatorDataLenght);
        //=========================================
        
        
        // Aubio
        
        uint_t win_s = frameSize; // window size
        fvec_t * in = new_fvec (win_s); // input buffer
        cvec_t * fftgrain = new_cvec (win_s); // fft norm and phase
        fvec_t * out = new_fvec (win_s); // output buffer
        // create fft object
        aubio_fft_t * fft = new_aubio_fft(win_s);
        // fill input with some data
        
        in -> data = buffer;
        fvec_print(in);
        // execute stft
        aubio_fft_do (fft,in,fftgrain);
        cvec_print(fftgrain);
        Float32 sum = 0.0;
        for (int i = 0; i < frameSize*3/4; i++) {
            Float32 amplitude = fftgrain -> norm[i];
            sum += amplitude/frameSize;
        }
        sum /= frameSize;
        double decibels = 20.0 * log10(sum);
        
        //pow( 10,(sum / 20) );
        
        std::cout << decibels+150 << std::endl;
        
        // execute inverse fourier transform
        //aubio_fft_rdo(fft,fftgrain,out);
        // cleam up
        //fvec_print(out);
        /* del_aubio_fft(fft);
         del_fvec(in);
         del_cvec(fftgrain);
         del_fvec(out);
         aubio_cleanup();
         return 0;*/
        
        
        Float32 maxHZValue = 0;
        Float32 maxHZ = strongestFrequencyHZ(dataAccumulator, fftConverter, accumulatorDataLenght, &maxHZValue);
        
        NSLog(@" max HZ = %0.3f ", maxHZ);
        dispatch_async(dispatch_get_main_queue(), ^{ //update UI only on main thread
          //  labelToUpdate.text = [NSString stringWithFormat:@"%f",decibels + 150];
            //[thisClass changeAccumulatorTo:12312312]
            [thisClass pushToDelegate: decibels+150];

        });
        
        emptyAccumulator(accumulatorDataLenght); //empty the accumulator when finished
    }
    memset(buffer, 0, sizeof(Float32)*frameSize*NUMCHANNELS);
   
    
}




@implementation AudioMeter



-(void) initAudioMeter {
    thisClass = self;
    fftConverter = FFTHelperCreate(accumulatorDataLenght);
    initializeAccumulator(accumulatorDataLenght);
   
    bool result = false;
    result = MoAudio::init( SAMPLE_RATE, FRAMESIZE, NUMCHANNELS, false);
    if (!result) { NSLog(@" MoAudio init ERROR"); }
    result = MoAudio::start( AudioCallback, NULL );
    if (!result) { NSLog(@" MoAudio start ERROR"); }
}

-(void) changeAccumulatorTo:(UInt32)length{
    bool result = false;
    MoAudio::stop();
    destroyAccumulator();
    accumulatorDataLenght = length;
    initializeAccumulator(accumulatorDataLenght);
    result = MoAudio::start( AudioCallback, NULL );
    if (!result) { NSLog(@" MoAudio start ERROR"); }

    
}

-(void) pushToDelegate: (Float32)value {
    [self.delegate newDataValue:value];
    
    
}




- (void)didReceiveMemoryWarning
{
    //[super didReceiveMemoryWarning];
}

/*
-(void) dealloc {
    destroyAccumulator();
    FFTHelperRelease(fftConverter);
    //[super dealloc];
}
 */

@end
